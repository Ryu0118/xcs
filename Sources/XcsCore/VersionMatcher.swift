/// Resolves a `VersionSpec` against a list of installed Xcode versions.
public enum VersionMatcher {
    /// A failure to resolve a version spec to a single installation.
    public enum MatchError: Error, Equatable, Sendable, CustomStringConvertible {
        /// No installed version matched `spec`.
        case noMatch(spec: String, available: [String])
        /// More than one installed version matched `spec`.
        case ambiguous(spec: String, candidates: [String])

        /// A human-readable explanation of the failure.
        public var description: String {
            switch self {
            case let .noMatch(spec, available):
                "No installed Xcode matches version \"\(spec)\". Available versions: \(available.joined(separator: ", "))."
            case let .ambiguous(spec, candidates):
                "Version \"\(spec)\" matches multiple installed Xcode versions: \(candidates.joined(separator: ", ")). Use a more specific version string."
            }
        }
    }

    /// Resolves a version spec against the given installations.
    ///
    /// Resolution order: an exact string match on `shortVersion` wins outright.
    /// Otherwise, a dot-segment prefix match is attempted (`"27"` matches `27.0`,
    /// `27.1`, ...); more than one prefix match is ambiguous. No match at either
    /// stage is `.noMatch`. Never guesses "closest" — see design spec.
    public static func resolve(
        spec: VersionSpec,
        installations: [XcodeInstallation]
    ) -> Result<XcodeInstallation, MatchError> {
        if let exact = installations.first(where: { $0.shortVersion == spec.rawValue }) {
            return .success(exact)
        }

        let specComponents = spec.rawValue.split(separator: ".").map(String.init)
        let prefixMatches = installations.filter { installation in
            let components = installation.shortVersion.split(separator: ".").map(String.init)
            guard components.count >= specComponents.count else { return false }
            return Array(components.prefix(specComponents.count)) == specComponents
        }

        switch prefixMatches.count {
        case 0:
            let available = installations.map(\.shortVersion)
            return .failure(.noMatch(spec: spec.rawValue, available: available))
        case 1:
            return .success(prefixMatches[0])
        default:
            let candidates = prefixMatches.map(\.shortVersion)
            return .failure(.ambiguous(spec: spec.rawValue, candidates: candidates))
        }
    }
}
