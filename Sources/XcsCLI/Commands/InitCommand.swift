import ArgumentParser

/// v1 skeleton only — deferred past v1 per design spec.
public struct InitCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Scaffold a .xcodeversions.yml from workspaces/projects found in the current directory. (not yet implemented)"
    )

    public init() {}

    public mutating func run() async throws {
        print("xcs init is not yet implemented.")
        throw ExitCode.failure
    }
}
