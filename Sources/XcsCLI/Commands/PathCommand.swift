import ArgumentParser
import Foundation
import XcsKit

public struct PathCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "path",
        abstract: "Print the resolved Xcode.app path for a target."
    )

    @Argument(help: "Path to the workspace/project. Omit to auto-detect.")
    var target: String?

    @Option(name: .long, help: "Override the pinned Xcode version for this run.")
    var xcode: String?

    @Flag(name: .customLong("developer-dir"), help: "Print the Contents/Developer path instead of the .app path.")
    var developerDir = false

    @Flag(name: .long, help: "Emit machine-readable JSON on stdout.")
    var json = false

    public init() {}

    public mutating func run() async throws {
        let workingDirectory = CLIEnvironment.currentDirectory()
        let discovery = CLIEnvironment.makeDiscovery()
        let candidateDiscovery = CLIEnvironment.makeCandidateDiscovery(
            workingDirectory: workingDirectory,
            discovery: discovery
        )
        let runner = PathRunner(candidateDiscovery: candidateDiscovery)

        do {
            let result = try await runner.run(explicitTarget: target)
            let path = developerDir ? result.installation.developerDirectoryPath.path : result.installation.appPath.path
            if json {
                CLIOutput.printJSON(ResolvedTargetJSON(result))
            } else {
                print(path)
            }
        } catch {
            if json {
                CLIOutput.printJSONError(String(describing: error))
            } else {
                CLIOutput.printError(String(describing: error))
            }
            throw ExitCode.failure
        }
    }
}
