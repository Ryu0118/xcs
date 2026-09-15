import ArgumentParser
import XcsKit

/// Lists discovered Xcode installations.
public struct ListCommand: AsyncParsableCommand {
    /// Declares the command's name and abstract for `ArgumentParser`.
    public static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List discovered Xcode installations."
    )

    @Flag(name: .long, help: "Emit machine-readable JSON on stdout.")
    var json = false

    /// Creates the command.
    public init() {}

    /// Discovers installed Xcode versions and prints them, marking any currently running.
    public mutating func run() async throws {
        let discovery = CLIEnvironment.makeDiscovery()
        let runner = ListRunner(discovery: discovery, runningChecker: NSWorkspaceRunningXcodeChecker())

        do {
            let results = try await runner.run()
            if json {
                CLIOutput.printJSON(results.map { ListedInstallationJSON($0) })
            } else {
                printTable(results)
            }
        } catch {
            CLIOutput.reportFailure(error, json: json)
            throw ExitCode.failure
        }
    }

    /// Prints one line per installation, marking any that are currently running.
    private func printTable(_ results: [ListedInstallation]) {
        for item in results {
            let marker = item.isRunning ? "[running]" : ""
            print("\(item.installation.shortVersion)  \(item.installation.appPath.path)  \(marker)")
        }
    }
}
