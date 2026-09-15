import Interaction
import XcsCore

/// Resolves what to open (single candidate opens immediately; multiple
/// candidates prompt an interactive picker on a TTY, or fail fast with no
/// prompt when not interactive) and launches it.
///
/// "No candidates" and "ambiguous" are properties of candidate resolution,
/// not of opening specifically, so both are `CandidateDiscovery.Error`
/// cases shared with `PathRunner`/`ExecRunner` rather than duplicated here.
public struct OpenRunner: Sendable {
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

    public func run(explicitTarget: String?, override: VersionOverride? = nil) async throws -> ResolvedTarget {
        let candidates = try await candidateDiscovery.resolveCandidates(
            explicitTarget: explicitTarget,
            override: override
        )

        let chosen: ResolvedTarget
        switch candidates.count {
        case 0:
            throw CandidateDiscovery.Error.noCandidates
        case 1:
            chosen = candidates[0] // Single candidate: never touch `interaction`.
        default:
            guard isInteractive else {
                throw CandidateDiscovery.Error.ambiguous(candidates: candidates)
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
