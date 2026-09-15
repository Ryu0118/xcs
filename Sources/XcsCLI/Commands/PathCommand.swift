import ArgumentParser
import Foundation
import XcsKit

/// Prints the resolved Xcode.app path for a target.
public struct PathCommand: AsyncParsableCommand {
    /// Declares the command's name and abstract for `ArgumentParser`.
    public static let configuration = CommandConfiguration(
        commandName: "path",
        abstract: "Print the resolved Xcode.app path for a target."
    )

    @Argument(help: "Path to the workspace/project. Omit to auto-detect.")
    var target: String?

    @Option(name: .long, help: "Override the pinned Xcode version for this run.")
    var xcode: String?

    @Option(name: .customLong("xcode-path"), help: "Override with an explicit Xcode.app path for this run.")
    var xcodePath: String?

    @Flag(name: .customLong("developer-dir"), help: "Print the Contents/Developer path instead of the .app path.")
    var developerDir = false

    @Flag(name: .long, help: "Emit machine-readable JSON on stdout.")
    var json = false

    /// Creates the command.
    public init() {}

    /// Resolves the target and prints its Xcode installation path.
    public mutating func run() async throws {
        let workingDirectory = CLIEnvironment.currentDirectory()
        let discovery = CLIEnvironment.makeDiscovery()
        let candidateDiscovery = CLIEnvironment.makeCandidateDiscovery(
            workingDirectory: workingDirectory,
            discovery: discovery
        )
        let runner = PathRunner(candidateDiscovery: candidateDiscovery)

        let override = CLIEnvironment.makeVersionOverride(xcode: xcode, xcodePath: xcodePath)

        do {
            let result = try await runner.run(explicitTarget: target, override: override)
            let path = developerDir ? result.installation.developerDirectoryPath.path : result.installation.appPath.path
            if json {
                CLIOutput.printJSON(ResolvedTargetJSON(result))
            } else {
                print(path)
            }
        } catch {
            CLIOutput.reportFailure(error, json: json)
            throw ExitCode.failure
        }
    }
}
