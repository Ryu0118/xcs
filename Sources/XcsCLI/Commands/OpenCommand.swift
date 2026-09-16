import ArgumentParser
import Foundation
import Interaction
import XcsKit

/// Opens a workspace/project with its pinned Xcode version.
public struct OpenCommand: AsyncParsableCommand {
    /// Declares the command's name and abstract for `ArgumentParser`.
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

    /// Creates the command.
    public init() {}

    /// Resolves the target and launches it with the matching Xcode installation.
    public mutating func run() async throws {
        let workingDirectory = CLIEnvironment.currentDirectory()
        try await Self.execute(
            target: target,
            xcode: xcode,
            xcodePath: xcodePath,
            json: json,
            candidateDiscovery: CLIEnvironment.makeCandidateDiscovery(
                workingDirectory: workingDirectory,
                discovery: CLIEnvironment.makeDiscovery()
            ),
            launcher: DirectExecXcodeLauncher(),
            interaction: Terminal(),
            isInteractive: TerminalCapabilities.detect().isInteractive
        )
    }

    /// Runs `OpenRunner` against injected dependencies and reports the result. Split out from
    /// `run()` so tests can inject fakes without going through `ArgumentParser`.
    static func execute(
        target: String?,
        xcode: String?,
        xcodePath: String?,
        json: Bool,
        candidateDiscovery: CandidateDiscovery,
        launcher: any XcodeLauncher,
        interaction: any InteractionProviding,
        isInteractive: Bool
    ) async throws {
        let runner = OpenRunner(
            candidateDiscovery: candidateDiscovery,
            launcher: launcher,
            interaction: interaction,
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
