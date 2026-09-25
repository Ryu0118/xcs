import ArgumentParser
import Foundation
import Testing
@testable import XcsCLI
@testable import XcsCore
@testable import XcsKit

struct ExecCommandTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func execsWithTheResolvedDeveloperDirectory() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            try ConfigurationTestSupport.write(
                "targets:\n  App.xcworkspace: \"27.0\"\n",
                to: root.appending(path: ".xcodeversions.yml")
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "App.xcworkspace"), withIntermediateDirectories: true
            )

            let execer = FakeExecer()
            let candidateDiscovery = CandidateDiscovery(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                workingDirectory: root,
                stopAt: root
            )

            await #expect(throws: ExitCode.failure) {
                // FakeExecer always throws rather than replacing the process
                // image, which the runner surfaces as a failure to exec —
                // this is what proves the arguments reached the execer.
                try await ExecCommand.execute(
                    target: "App.xcworkspace",
                    command: ["xcodebuild", "-scheme", "Foo", "-configuration", "Debug"],
                    candidateDiscovery: candidateDiscovery,
                    execer: execer
                )
            }

            #expect(execer.lastCommand == ["xcodebuild", "-scheme", "Foo", "-configuration", "Debug"])
            #expect(execer.lastDeveloperDirectory == "/Applications/Xcode_27.0.app/Contents/Developer")
        }
    }

    @Test
    func parsesDashPrefixedArgumentsAsPassthroughCommand() throws {
        // Regression guard: without `.captureForPassthrough`, ArgumentParser
        // would try to interpret `-scheme`/`-configuration` as its own flags.
        let parsed = try ExecCommand.parse(["App.xcworkspace", "xcodebuild", "-scheme", "Foo", "-configuration", "Debug"])

        #expect(parsed.target == "App.xcworkspace")
        #expect(parsed.command == ["xcodebuild", "-scheme", "Foo", "-configuration", "Debug"])
    }

    @Test
    func excludeBetaMustPrecedeTargetToBeRecognizedAsAFlag() throws {
        // `.captureForPassthrough` on `command` captures everything from
        // <target> onward, including any later-positioned flags — so
        // `--exclude-beta` only parses as a flag when given *before* <target>.
        let before = try ExecCommand.parse(["--exclude-beta", "App.xcworkspace", "xcodebuild", "-version"])
        #expect(before.excludeBeta == true)
        #expect(before.command == ["xcodebuild", "-version"])

        // After <target>, it's swallowed into the passthrough command instead
        // of being parsed as the flag — this is the documented tradeoff, not
        // a bug to silently fix, so pin the behavior here.
        let after = try ExecCommand.parse(["App.xcworkspace", "--exclude-beta", "xcodebuild", "-version"])
        #expect(after.excludeBeta == false)
        #expect(after.command == ["--exclude-beta", "xcodebuild", "-version"])
    }

    @Test
    func dropsALeadingDoubleDashBeforeExeccing() async throws {
        // `.captureForPassthrough` captures a literal leading "--" (documented
        // ArgumentParser behavior), but `xcs exec <target> -- <command>` is
        // the natural way to write this — execute() must drop it rather than
        // handing "--" to execvp as the program name.
        try await ConfigurationTestSupport.withDirectory { root in
            try ConfigurationTestSupport.write(
                "targets:\n  App.xcworkspace: \"27.0\"\n",
                to: root.appending(path: ".xcodeversions.yml")
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "App.xcworkspace"), withIntermediateDirectories: true
            )

            let execer = FakeExecer()
            let candidateDiscovery = CandidateDiscovery(
                fileManager: FileManager.default,
                discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                workingDirectory: root,
                stopAt: root
            )

            await #expect(throws: ExitCode.failure) {
                try await ExecCommand.execute(
                    target: "App.xcworkspace",
                    command: ["--", "xcodebuild", "-version"],
                    candidateDiscovery: candidateDiscovery,
                    execer: execer
                )
            }

            #expect(execer.lastCommand == ["xcodebuild", "-version"])
        }
    }
}
