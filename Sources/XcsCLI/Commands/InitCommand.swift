import ArgumentParser

/// v1 skeleton only — deferred past v1 per design spec.
public struct InitCommand: AsyncParsableCommand {
    /// Declares the command's name and abstract for `ArgumentParser`.
    public static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Scaffold a .xcodeversions.yml from workspaces/projects found in the current directory. (not yet implemented)"
    )

    /// Creates the command.
    public init() {}

    /// Reports that this command is not yet implemented.
    public mutating func run() async throws {
        print("xcs init is not yet implemented.")
        throw ExitCode.failure
    }
}
