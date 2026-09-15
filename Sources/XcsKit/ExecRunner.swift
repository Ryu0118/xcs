/// Resolves a target's Xcode installation and execs a command under it.
public struct ExecRunner: Sendable {
    /// A failure encountered while running `xcs exec`.
    public enum Error: Swift.Error, Equatable, Sendable, CustomStringConvertible {
        /// No command was given after `--`.
        case emptyCommand

        /// A human-readable explanation of the failure.
        public var description: String {
            switch self {
            case .emptyCommand:
                "xcs exec requires a command after '--'."
            }
        }
    }

    private let candidateDiscovery: CandidateDiscovery
    private let execer: any Execer

    /// Creates the runner.
    public init(candidateDiscovery: CandidateDiscovery, execer: any Execer) {
        self.candidateDiscovery = candidateDiscovery
        self.execer = execer
    }

    /// Resolves `target`'s Xcode installation and execs `command` with `DEVELOPER_DIR` set.
    public func run(target: String, command: [String]) async throws -> Never {
        guard !command.isEmpty else { throw Error.emptyCommand }
        let candidates = try await candidateDiscovery.resolveCandidates(explicitTarget: target)
        guard let resolved = candidates.first else {
            throw CandidateDiscovery.Error.noCandidates
        }
        try execer.exec(
            command: command,
            developerDirectory: resolved.installation.developerDirectoryPath.path
        )
    }
}
