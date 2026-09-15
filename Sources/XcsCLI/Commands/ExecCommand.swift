import ArgumentParser
import Foundation
import XcsKit

/// Runs a command with `DEVELOPER_DIR` set to the resolved Xcode installation.
public struct ExecCommand: AsyncParsableCommand {
    /// Declares the command's name and abstract for `ArgumentParser`.
    public static let configuration = CommandConfiguration(
        commandName: "exec",
        abstract: "Run a command with DEVELOPER_DIR set to the resolved Xcode installation."
    )

    @Argument(help: "Path to the workspace/project.")
    var target: String

    @Argument(parsing: .captureForPassthrough, help: "Command to run, e.g. xcodebuild -scheme Foo.")
    var command: [String] = []

    /// Creates the command.
    public init() {}

    /// Resolves the target's Xcode installation and execs the given command under it.
    public mutating func run() async throws {
        let workingDirectory = CLIEnvironment.currentDirectory()
        let discovery = CLIEnvironment.makeDiscovery()
        let candidateDiscovery = CLIEnvironment.makeCandidateDiscovery(
            workingDirectory: workingDirectory,
            discovery: discovery
        )
        let runner = ExecRunner(candidateDiscovery: candidateDiscovery, execer: SystemExecer())

        do {
            try await runner.run(target: target, command: command)
        } catch {
            CLIOutput.reportFailure(error, json: false)
            throw ExitCode.failure
        }
    }
}
