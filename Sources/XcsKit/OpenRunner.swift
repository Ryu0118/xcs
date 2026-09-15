import Interaction
import XcsCore

/// Resolves what to open (single candidate opens immediately; multiple
/// candidates prompt an interactive picker on a TTY, or fail fast with no
/// prompt when not interactive) and launches it.
public struct OpenRunner: Sendable {
    public enum Error: Swift.Error, Equatable, Sendable, CustomStringConvertible {
        case noCandidates
        case ambiguousNonInteractive(candidates: [ResolvedTarget])

        public var description: String {
            switch self {
            case .noCandidates:
                "No target to open was found."
            case let .ambiguousNonInteractive(candidates):
                "Multiple targets matched and no terminal is attached to prompt for a choice: "
                    + candidates.map(\.description).joined(separator: ", ")
            }
        }
    }

    private let candidateDiscovery: CandidateDiscovery
    private let launcher: any XcodeLauncher
    private let interaction: any InteractionProviding
    private let isInteractive: Bool

    public init(
        candidateDiscovery: CandidateDiscovery,
        launcher: any XcodeLauncher,
        interaction: any InteractionProviding,
        isInteractive: Bool
    ) {
        self.candidateDiscovery = candidateDiscovery
        self.launcher = launcher
        self.interaction = interaction
        self.isInteractive = isInteractive
    }

    public func run(explicitTarget: String?) async throws -> ResolvedTarget {
        let candidates = try await candidateDiscovery.resolveCandidates(explicitTarget: explicitTarget)

        let chosen: ResolvedTarget
        switch candidates.count {
        case 0:
            throw Error.noCandidates
        case 1:
            chosen = candidates[0] // Single candidate: never touch `interaction`.
        default:
            guard isInteractive else {
                throw Error.ambiguousNonInteractive(candidates: candidates)
            }
            chosen = interaction.choose(
                ChoicePrompt(
                    question: "Multiple targets matched. Which one?",
                    options: candidates
                )
            )
        }

        try launcher.launch(installation: chosen.installation, filePath: chosen.path)
        return chosen
    }
}
