import Foundation
import Testing
@testable import XcsCore
@testable import XcsKit

struct DoctorRunnerTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func reportsMissingConfigurationWithoutHidingDiscoveryResults() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let runner = DoctorRunner(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                workingDirectory: root,
                stopAt: root
            )

            let report = await runner.run()

            #expect(report.configurationFound == nil)
            #expect(report.discoveredInstallations?.map(\.shortVersion) == ["27.0"])
            #expect(report.entryResolutions.isEmpty)
        }
    }

    @Test
    func resolvesEachEntryAgainstDiscoveredInstallations() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            try ConfigurationTestSupport.write(
                "targets:\n  App.xcworkspace: \"27.0\"\n  Tools.xcodeproj: \"28.0\"\n",
                to: root.appending(path: ".xcodeversions.yml")
            )

            let runner = DoctorRunner(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                workingDirectory: root,
                stopAt: root
            )

            let report = await runner.run()

            #expect(report.configurationFound == root.appending(path: ".xcodeversions.yml"))
            #expect(report.entryResolutions["App.xcworkspace"] == .ok(version: "27.0"))
            if case .error = report.entryResolutions["Tools.xcodeproj"] {
                // expected: 28.0 is not among the discovered installations
            } else {
                Issue.record("expected Tools.xcodeproj to fail resolution")
            }
        }
    }

    @Test
    func reportsDiscoveryFailureAsNilRatherThanAnEmptyList() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            struct SomeError: Error {}
            let runner = DoctorRunner(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.throwing(SomeError()),
                workingDirectory: root,
                stopAt: root
            )

            let report = await runner.run()

            #expect(report.discoveredInstallations == nil)
        }
    }
}
