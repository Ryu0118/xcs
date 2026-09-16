import Foundation
import Testing
@testable import XcsCore
@testable import XcsKit

struct ExecRunnerTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func setsDeveloperDirectoryFromTheResolvedInstallation() async throws {
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
            let execer = FakeExecer()
            let runner = ExecRunner(candidateDiscovery: candidateDiscovery, execer: execer)

            await #expect(throws: FakeExecer.Invoked.self) {
                try await runner.run(target: "App.xcworkspace", command: ["xcodebuild", "-version"])
            }

            #expect(execer.lastCommand == ["xcodebuild", "-version"])
            #expect(execer.lastDeveloperDirectory == "/Applications/Xcode_27.0.app/Contents/Developer")
        }
    }

    @Test
    func throwsEmptyCommandWhenNoCommandIsGiven() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let candidateDiscovery = CandidateDiscovery(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                workingDirectory: root,
                stopAt: root
            )
            let execer = FakeExecer()
            let runner = ExecRunner(candidateDiscovery: candidateDiscovery, execer: execer)

            await #expect(throws: ExecRunner.Error.emptyCommand) {
                try await runner.run(target: "App.xcworkspace", command: [])
            }
            #expect(execer.lastCommand == nil)
        }
    }
}
