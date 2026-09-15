import XcsCore

/// Resolves a target and returns its Xcode installation path. Side-effect
/// free — used by `xcs path`.
public struct PathRunner: Sendable {
    private let candidateDiscovery: CandidateDiscovery

    /// Creates the runner.
    public init(candidateDiscovery: CandidateDiscovery) {
        self.candidateDiscovery = candidateDiscovery
    }

    /// Resolves the target to a single `ResolvedTarget`, failing if none or more than one match.
    public func run(explicitTarget: String?, override: VersionOverride? = nil) async throws -> ResolvedTarget {
        let candidates = try await candidateDiscovery.resolveCandidates(
            explicitTarget: explicitTarget,
            override: override
        )
        switch candidates.count {
        case 0:
            throw CandidateDiscovery.Error.noCandidates
        case 1:
            return candidates[0]
        default:
            throw CandidateDiscovery.Error.ambiguous(candidates: candidates)
        }
    }
}
