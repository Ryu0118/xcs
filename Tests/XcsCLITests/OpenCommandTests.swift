import ArgumentParser
import Foundation
import Interaction
import Testing
@testable import XcsCLI
@testable import XcsCore
@testable import XcsKit

struct OpenCommandTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func printsTheOpenedTargetOnSuccess() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            try ConfigurationTestSupport.write(
                "targets:\n  App.xcworkspace: \"27.0\"\n",
                to: root.appending(path: ".xcodeversions.yml")
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "App.xcworkspace"), withIntermediateDirectories: true
            )

            let output = try await OutputCapture.capture {
                try await OpenCommand.execute(
                    target: nil,
                    xcode: nil,
                    xcodePath: nil,
                    json: false,
                    candidateDiscovery: CandidateDiscovery(
                        fileManager: FileManager.default,
                        discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                        workingDirectory: root,
                        stopAt: root
                    ),
                    launcher: FakeXcodeLauncher(),
                    interaction: GuardedInteraction(),
                    isInteractive: true
                )
            }

            #expect(output.contains("Opened"))
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
            try FileManager.default.createDirectory(
                at: root.appending(path: "App.xcworkspace"), withIntermediateDirectories: true
            )

            let output = try await OutputCapture.capture {
                try await OpenCommand.execute(
                    target: nil,
                    xcode: nil,
                    xcodePath: nil,
                    json: true,
                    candidateDiscovery: CandidateDiscovery(
                        fileManager: FileManager.default,
                        discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                        workingDirectory: root,
                        stopAt: root
                    ),
                    launcher: FakeXcodeLauncher(),
                    interaction: GuardedInteraction(),
                    isInteractive: true
                )
            }

            #expect(output.contains("\"xcodeVersion\""))
            #expect(output.contains("27.0"))
        }
    }

    @Test
    func failsWithExitCodeFailureWhenNoCandidateIsFound() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            await #expect(throws: ExitCode.failure) {
                try await OpenCommand.execute(
                    target: nil,
                    xcode: nil,
                    xcodePath: nil,
                    json: false,
                    candidateDiscovery: CandidateDiscovery(
                        fileManager: FileManager.default,
                        discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                        workingDirectory: root,
                        stopAt: root
                    ),
                    launcher: FakeXcodeLauncher(),
                    interaction: GuardedInteraction(),
                    isInteractive: true
                )
            }
        }
    }
}
