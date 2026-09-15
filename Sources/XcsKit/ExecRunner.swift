public struct ExecRunner: Sendable {
    public enum Error: Swift.Error, Equatable, Sendable, CustomStringConvertible {
        case emptyCommand

        public var description: String {
            switch self {
            case .emptyCommand:
                "xcs exec requires a command after '--'."
            }
        }
    }

    private let candidateDiscovery: CandidateDiscovery
    private let execer: any Execer

    public init(candidateDiscovery: CandidateDiscovery, execer: any Execer) {
        self.candidateDiscovery = candidateDiscovery
        self.execer = execer
    }

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
