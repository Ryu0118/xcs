import Foundation
import Testing
@testable import XcsCLI
@testable import XcsCore
@testable import XcsKit

struct DoctorCommandTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func printsHumanReadableStatusByDefault() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            try ConfigurationTestSupport.write(
                "targets:\n  App.xcworkspace: \"27.0\"\n",
                to: root.appending(path: ".xcodeversions.yml")
            )

            let runner = DoctorRunner(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                workingDirectory: root,
                stopAt: root
            )

            let output = try await OutputCapture.capture {
                await DoctorCommand.execute(json: false, workingDirectory: root, runner: runner)
            }

            #expect(output.contains("App.xcworkspace"))
            #expect(output.contains("27.0"))
        }
    }

    @Test
    func printsJSONWhenJSONFlagIsSet() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            try ConfigurationTestSupport.write(
                "targets:\n  App.xcworkspace: \"27.0\"\n",
                to: root.appending(path: ".xcodeversions.yml")
            )

            let runner = DoctorRunner(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                workingDirectory: root,
                stopAt: root
            )

            let output = try await OutputCapture.capture {
                await DoctorCommand.execute(json: true, workingDirectory: root, runner: runner)
            }

            #expect(output.contains("\"entryResolutions\""))
        }
    }
}
