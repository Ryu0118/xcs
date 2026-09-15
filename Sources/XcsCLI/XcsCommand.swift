import ArgumentParser

public struct XcsCommand: AsyncParsableCommand {
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

    public init() {}
}
