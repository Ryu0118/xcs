import Foundation
import Testing
@testable import XcsCore
@testable import XcsKit

struct PathRunnerTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func resolvesTheSingleCandidate() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            try ConfigurationTestSupport.write(
                "targets:\n  App.xcworkspace: \"27.0\"\n",
                to: root.appending(path: ".xcodeversions.yml")
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "App.xcworkspace"), withIntermediateDirectories: true
            )

            let candidateDiscovery = CandidateDiscovery(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                workingDirectory: root,
                stopAt: root
            )
            let runner = PathRunner(candidateDiscovery: candidateDiscovery)

            let result = try await runner.run(explicitTarget: nil)

            #expect(result.installation.shortVersion == "27.0")
        }
    }

    @Test
    func throwsAmbiguousWithMultipleCandidates() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            try ConfigurationTestSupport.write(
                "targets:\n  A.xcworkspace: \"27.0\"\n  B.xcworkspace: \"26.6\"\n",
                to: root.appending(path: ".xcodeversions.yml")
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "A.xcworkspace"), withIntermediateDirectories: true
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "B.xcworkspace"), withIntermediateDirectories: true
            )

            let candidateDiscovery = CandidateDiscovery(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.returning([installation("27.0"), installation("26.6")]),
                workingDirectory: root,
                stopAt: root
            )
            let runner = PathRunner(candidateDiscovery: candidateDiscovery)

            await #expect(throws: CandidateDiscovery.Error.self) {
                try await runner.run(explicitTarget: nil)
            }
        }
    }

    @Test
    func throwsNoCandidatesWhenNothingIsFound() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let candidateDiscovery = CandidateDiscovery(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                workingDirectory: root,
                stopAt: root
            )
            let runner = PathRunner(candidateDiscovery: candidateDiscovery)

            await #expect(throws: CandidateDiscovery.Error.self) {
                try await runner.run(explicitTarget: nil)
            }
        }
    }
}
