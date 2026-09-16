import ArgumentParser
import Foundation
import Testing
@testable import XcsCLI
@testable import XcsCore
@testable import XcsKit

struct ListCommandTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func printsATableByDefault() async throws {
        let output = try await OutputCapture.capture {
            try await ListCommand.execute(
                json: false,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                runningChecker: FakeRunningXcodeChecker(runningAppPaths: [installation("27.0").appPath])
            )
        }

        #expect(output.contains("27.0"))
        #expect(output.contains("[running]"))
    }

    @Test
    func printsJSONWhenJSONFlagIsSet() async throws {
        let output = try await OutputCapture.capture {
            try await ListCommand.execute(
                json: true,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                runningChecker: FakeRunningXcodeChecker()
            )
        }

        #expect(output.contains("\"version\""))
        #expect(output.contains("27.0"))
    }
}
