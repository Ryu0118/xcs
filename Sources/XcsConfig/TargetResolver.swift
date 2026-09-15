import Foundation
import Glob
import XcsCore

/// Resolves a candidate path (relative to the config directory) against the
/// `targets:` map of a `.xcodeversions.yml` document.
///
/// Resolution precedence: exact relative-path match > suffix match > glob
/// match. Evaluation short-circuits at the first tier with any match — this
/// avoids the same key being counted as both an exact and a suffix
/// candidate and producing a spurious ambiguity error. Two matches at the
/// *same* tier is an ambiguity error listing every matching key.
public struct TargetResolver: Sendable {
    public enum ResolutionError: Error, Equatable, Sendable, CustomStringConvertible {
        case ambiguousMatch(target: String, matchingKeys: [String])
        case noMatch(target: String)

        public var description: String {
            switch self {
            case let .ambiguousMatch(target, matchingKeys):
                "Target \"\(target)\" matches multiple keys in .xcodeversions.yml: \(matchingKeys.joined(separator: ", ")). Use a more specific key."
            case let .noMatch(target):
                "No entry in .xcodeversions.yml matches target \"\(target)\"."
            }
        }
    }

    public init() {}

    public func resolve(
        target: URL,
        relativeTo configDirectory: URL,
        in document: XcodeVersionsDocument
    ) -> Result<VersionSpec, ResolutionError> {
        let (relativePath, targetPath) = Self.paths(of: target, from: configDirectory)

        let exactMatches = document.targets.keys.filter { $0 == relativePath }
        if !exactMatches.isEmpty {
            return Self.pick(exactMatches, target: relativePath, from: document)
        }

        // A key equal to `relativePath` would already have matched above and
        // returned, so every key reaching this filter is necessarily != relativePath.
        let suffixMatches = document.targets.keys.filter { key in
            targetPath.hasSuffix("/\(key)") || targetPath.hasSuffix(key)
        }
        if !suffixMatches.isEmpty {
            return Self.pick(suffixMatches, target: relativePath, from: document)
        }

        let globMatches = document.targets.keys.filter { key in
            guard let pattern = try? Pattern(key) else { return false }
            return pattern.match(relativePath)
        }
        if !globMatches.isEmpty {
            return Self.pick(globMatches, target: relativePath, from: document)
        }

        return .failure(.noMatch(target: relativePath))
    }

    private static func pick(
        _ keys: [String],
        target: String,
        from document: XcodeVersionsDocument
    ) -> Result<VersionSpec, ResolutionError> {
        guard keys.count == 1, let version = document.targets[keys[0]] else {
            return .failure(.ambiguousMatch(target: target, matchingKeys: keys.sorted()))
        }
        return .success(VersionSpec(rawValue: version))
    }

    /// Returns both the config-relative path (used for exact/glob matching)
    /// and the standardized absolute path (used for suffix matching),
    /// computing the shared standardization/symlink-resolution step once.
    private static func paths(of target: URL, from configDirectory: URL) -> (relativePath: String, targetPath: String) {
        let targetPath = target.standardizedFileURL.resolvingSymlinksInPath().path
        let basePath = configDirectory.standardizedFileURL.resolvingSymlinksInPath().path
        guard targetPath.hasPrefix(basePath) else { return (target.lastPathComponent, targetPath) }
        var relative = String(targetPath.dropFirst(basePath.count))
        if relative.hasPrefix("/") { relative.removeFirst() }
        return (relative.isEmpty ? target.lastPathComponent : relative, targetPath)
    }
}
