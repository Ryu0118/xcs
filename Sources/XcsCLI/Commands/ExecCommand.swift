import ArgumentParser
import Foundation
import XcsKit

public struct ExecCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "exec",
        abstract: "Run a command with DEVELOPER_DIR set to the resolved Xcode installation."
    )

    @Argument(help: "Path to the workspace/project.")
    var target: String

    @Argument(parsing: .captureForPassthrough, help: "Command to run, e.g. xcodebuild -scheme Foo.")
    var command: [String] = []

    public init() {}

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
            CLIOutput.printError(String(describing: error))
            throw ExitCode.failure
        }
    }
}
