import Foundation
import Testing
@testable import XcsCore
@testable import XcsKit

struct ListRunnerTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func annotatesEachInstallationWithItsRunningState() async throws {
        let running = installation("27.0")
        let notRunning = installation("26.6")
        let runner = ListRunner(
            discovery: FakeXcodeDiscovery.returning([running, notRunning]),
            runningChecker: FakeRunningXcodeChecker(runningAppPaths: [running.appPath])
        )

        let result = try await runner.run()

        #expect(result.count == 2)
        #expect(result[0].installation.shortVersion == "27.0")
        #expect(result[0].isRunning)
        #expect(result[1].installation.shortVersion == "26.6")
        #expect(!result[1].isRunning)
    }

    @Test
    func propagatesDiscoveryFailures() async throws {
        struct SomeError: Error {}
        let runner = ListRunner(
            discovery: FakeXcodeDiscovery.throwing(SomeError()),
            runningChecker: FakeRunningXcodeChecker()
        )

        await #expect(throws: SomeError.self) {
            try await runner.run()
        }
    }
}
