import XcsCore

/// Resolves a target and returns its Xcode installation path. Side-effect
/// free — used by `xcs path`.
public struct PathRunner: Sendable {
    private let candidateDiscovery: CandidateDiscovery

    public init(candidateDiscovery: CandidateDiscovery) {
        self.candidateDiscovery = candidateDiscovery
    }

    public func run(explicitTarget: String?) async throws -> ResolvedTarget {
        let candidates = try await candidateDiscovery.resolveCandidates(explicitTarget: explicitTarget)
        guard let single = candidates.first, candidates.count == 1 else {
            throw OpenRunner.Error.ambiguousNonInteractive(candidates: candidates)
        }
        return single
    }
}
