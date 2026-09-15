import ArgumentParser
import Foundation
import Interaction
import XcsKit

public struct OpenCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "open",
        abstract: "Open a workspace/project with its pinned Xcode version."
    )

    @Argument(help: "Path to the workspace/project. Omit to auto-detect from .xcodeversions.yml or cwd.")
    var target: String?

    @Option(name: .long, help: "Override the pinned Xcode version for this run.")
    var xcode: String?

    @Option(name: .customLong("xcode-path"), help: "Override with an explicit Xcode.app path for this run.")
    var xcodePath: String?

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
        let isInteractive = TerminalCapabilities.detect().isInteractive

        let runner = OpenRunner(
            candidateDiscovery: candidateDiscovery,
            launcher: DirectExecXcodeLauncher(),
            interaction: Terminal(),
            isInteractive: isInteractive
        )

        let override = CLIEnvironment.makeVersionOverride(xcode: xcode, xcodePath: xcodePath)

        do {
            let result = try await runner.run(explicitTarget: target, override: override)
            if json {
                CLIOutput.printJSON(ResolvedTargetJSON(result))
            } else {
                print("Opened \(result.description)")
            }
        } catch {
            CLIOutput.reportFailure(error, json: json)
            throw ExitCode.failure
        }
    }
}
