import FileManagerProtocol
import Foundation
import XcsConfig
import XcsCore

/// Resolves the set of candidate targets to open for a given cwd:
/// `.xcodeversions.yml` targets when a config exists, or `*.xcworkspace`/
/// `*.xcodeproj` found directly in cwd otherwise.
public struct CandidateDiscovery: Sendable {
    public enum Error: Swift.Error, Equatable, Sendable, CustomStringConvertible {
        case noCandidates

        public var description: String {
            switch self {
            case .noCandidates:
                "No .xcworkspace or .xcodeproj found, and no .xcodeversions.yml entries resolved."
            }
        }
    }

    private let fileManager: any FileManagerProtocol
    private let loader: XcodeVersionsLoader
    private let resolver: TargetResolver
    private let discovery: any XcodeDiscovery
    private let workingDirectory: URL
    private let stopAt: URL?

    public init(
        fileManager: any FileManagerProtocol,
        discovery: any XcodeDiscovery,
        workingDirectory: URL,
        stopAt: URL? = nil
    ) {
        self.fileManager = fileManager
        loader = XcodeVersionsLoader(fileManager: fileManager)
        resolver = TargetResolver()
        self.discovery = discovery
        self.workingDirectory = workingDirectory
        self.stopAt = stopAt
    }

    /// Resolves candidates. When `explicitTarget` is given, the result is
    /// always exactly one candidate (or an error) — callers never reach the
    /// picker branch in that case.
    public func resolveCandidates(explicitTarget: String?) async throws -> [ResolvedTarget] {
        let installations = try await discovery.discoverInstallations()

        if let explicitTarget {
            let targetURL = URL(fileURLWithPath: explicitTarget, relativeTo: workingDirectory)
            let spec = try resolveVersionSpec(for: targetURL)
            let installation = try VersionMatcher.resolve(spec: spec, installations: installations).get()
            return [ResolvedTarget(path: targetURL, installation: installation)]
        }

        let candidatePaths = try candidateWorkspaceOrProjectPaths()
        guard !candidatePaths.isEmpty else { throw Error.noCandidates }

        return try candidatePaths.map { path in
            let spec = try resolveVersionSpec(for: path)
            let installation = try VersionMatcher.resolve(spec: spec, installations: installations).get()
            return ResolvedTarget(path: path, installation: installation)
        }
    }

    private func resolveVersionSpec(for target: URL) throws -> VersionSpec {
        guard let loaded = try loader.load(startingAt: workingDirectory, stopAt: stopAt) else {
            throw XcodeVersionsLoadingError.configurationFileNotFound(startingFrom: workingDirectory)
        }
        return try resolver.resolve(
            target: target,
            relativeTo: loaded.configurationDirectory,
            in: loaded.document
        ).get()
    }

    private func candidateWorkspaceOrProjectPaths() throws -> [URL] {
        let entries = (try? fileManager.contentsOfDirectory(atPath: workingDirectory.path)) ?? []
        return entries
            .filter { $0.hasSuffix(".xcworkspace") || $0.hasSuffix(".xcodeproj") }
            .map { workingDirectory.appending(path: $0) }
    }
}
