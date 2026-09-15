import ArgumentParser
import XcsKit

public struct ListCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List discovered Xcode installations."
    )

    @Flag(name: .long, help: "Emit machine-readable JSON on stdout.")
    var json = false

    public init() {}

    public mutating func run() async throws {
        let discovery = CLIEnvironment.makeDiscovery()
        let runner = ListRunner(discovery: discovery, runningChecker: NSWorkspaceRunningXcodeChecker())

        do {
            let results = try await runner.run()
            if json {
                CLIOutput.printJSON(results.map { ListedInstallationJSON($0) })
            } else {
                for item in results {
                    let marker = item.isRunning ? "[running]" : ""
                    print("\(item.installation.shortVersion)  \(item.installation.appPath.path)  \(marker)")
                }
            }
        } catch {
            CLIOutput.reportFailure(error, json: json)
            throw ExitCode.failure
        }
    }
}
