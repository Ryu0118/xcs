import ArgumentParser

/// The root `xcs` command, dispatching to its subcommands.
public struct XcsCommand: AsyncParsableCommand {
    /// Declares the command's name, subcommands, and default subcommand for `ArgumentParser`.
    public static let configuration = CommandConfiguration(
        commandName: "xcs",
        abstract: "Version-aware Xcode launcher and build tool selector.",
        version: XcsVersion.current,
        subcommands: [
            OpenCommand.self,
            PathCommand.self,
            ExecCommand.self,
            ListCommand.self,
            DoctorCommand.self,
            InitCommand.self,
        ],
        defaultSubcommand: OpenCommand.self
    )

    /// Creates the command.
    public init() {}
}
