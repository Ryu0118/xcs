import Foundation
import Testing
@testable import XcsCore
@testable import XcsKit

struct OpenRunnerTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    private func candidateDiscovery(
        in root: URL,
        discovery: any XcodeDiscovery
    ) -> CandidateDiscovery {
        // stopAt: root is required — without it, a fixture with no
        // .xcodeversions.yml makes the locator walk all the way to the
        // real filesystem root, which can hang or pick up an unrelated file.
        CandidateDiscovery(
            fileManager: FileManager.default,
            discovery: discovery,
            workingDirectory: root,
            stopAt: root
        )
    }

    @Test
    func singleCandidateOpensImmediatelyWithoutTouchingInteraction() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let configURL = root.appending(path: ".xcodeversions.yml")
            try ConfigurationTestSupport.write("targets:\n  App.xcworkspace: \"27.0\"\n", to: configURL)
            try FileManager.default.createDirectory(
                at: root.appending(path: "App.xcworkspace"),
                withIntermediateDirectories: true
            )

            let launcher = FakeXcodeLauncher()
            let runner = OpenRunner(
                candidateDiscovery: candidateDiscovery(in: root, discovery: FakeXcodeDiscovery.returning([installation("27.0")])),
                launcher: launcher,
                interaction: GuardedInteraction(),
                isInteractive: true
            )

            let result = try await runner.run(explicitTarget: nil)

            #expect(result.installation.shortVersion == "27.0")
            #expect(launcher.launchedCalls.count == 1)
            #expect(launcher.launchedCalls.first?.installation.shortVersion == "27.0")
        }
    }

    @Test
    func multipleCandidatesInteractivePromptsAndOpensTheChosenOne() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let configURL = root.appending(path: ".xcodeversions.yml")
            try ConfigurationTestSupport.write(
                "targets:\n  A.xcworkspace: \"27.0\"\n  B.xcworkspace: \"26.6\"\n",
                to: configURL
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "A.xcworkspace"), withIntermediateDirectories: true
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "B.xcworkspace"), withIntermediateDirectories: true
            )

            let launcher = FakeXcodeLauncher()
            let discovery = FakeXcodeDiscovery.returning([installation("27.0"), installation("26.6")])
            let runner = OpenRunner(
                candidateDiscovery: candidateDiscovery(in: root, discovery: discovery),
                launcher: launcher,
                interaction: FixedChoiceInteraction(chosenIndex: 1),
                isInteractive: true
            )

            let result = try await runner.run(explicitTarget: nil)

            #expect(launcher.launchedCalls.count == 1)
            #expect(result == launcher.launchedCalls.first.map { ResolvedTarget(path: $1, installation: $0) })
        }
    }

    @Test
    func multipleCandidatesNonInteractiveFailsWithoutTouchingInteraction() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let configURL = root.appending(path: ".xcodeversions.yml")
            try ConfigurationTestSupport.write(
                "targets:\n  A.xcworkspace: \"27.0\"\n  B.xcworkspace: \"26.6\"\n",
                to: configURL
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "A.xcworkspace"), withIntermediateDirectories: true
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "B.xcworkspace"), withIntermediateDirectories: true
            )

            let launcher = FakeXcodeLauncher()
            let discovery = FakeXcodeDiscovery.returning([installation("27.0"), installation("26.6")])
            let runner = OpenRunner(
                candidateDiscovery: candidateDiscovery(in: root, discovery: discovery),
                launcher: launcher,
                interaction: GuardedInteraction(),
                isInteractive: false
            )

            await #expect(throws: CandidateDiscovery.Error.self) {
                try await runner.run(explicitTarget: nil)
            }
            #expect(launcher.launchedCalls.isEmpty)
        }
    }

    @Test
    func xcodeOverrideBypassesTheConfigFile() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            // No .xcodeversions.yml at all — the override must still resolve.
            try FileManager.default.createDirectory(
                at: root.appending(path: "App.xcworkspace"), withIntermediateDirectories: true
            )

            let launcher = FakeXcodeLauncher()
            let discovery = FakeXcodeDiscovery.returning([installation("27.0"), installation("26.6")])
            let runner = OpenRunner(
                candidateDiscovery: candidateDiscovery(in: root, discovery: discovery),
                launcher: launcher,
                interaction: GuardedInteraction(),
                isInteractive: true
            )

            let result = try await runner.run(
                explicitTarget: "App.xcworkspace",
                override: .version("26.6")
            )

            #expect(result.installation.shortVersion == "26.6")
        }
    }
}
