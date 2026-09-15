import FileManagerProtocol
import Foundation
import XcsConfig
import XcsCore

/// A one-off override that bypasses `.xcodeversions.yml` resolution entirely,
/// for `--xcode <version>` / `--xcode-path <path>`. Never mutates the yml or
/// `xcode-select`.
public enum VersionOverride: Equatable, Sendable {
    /// Overrides resolution with an explicit version string.
    case version(String)
    /// Overrides resolution with an explicit Xcode.app path.
    case appPath(URL)
}

/// Resolves the set of candidate targets to open for a given cwd:
/// `.xcodeversions.yml` targets when a config exists, or `*.xcworkspace`/
/// `*.xcodeproj` found directly in cwd otherwise.
public struct CandidateDiscovery: Sendable {
    /// A failure to resolve candidate targets to open.
    public enum Error: Swift.Error, Equatable, Sendable, CustomStringConvertible {
        /// No workspace/project was found and no `.xcodeversions.yml` entries resolved.
        case noCandidates
        /// The `--xcode-path` override does not match any discovered installation.
        case xcodePathNotInstalled(URL)
        /// More than one candidate target matched.
        case ambiguous(candidates: [ResolvedTarget])

        /// A human-readable explanation of the failure.
        public var description: String {
            switch self {
            case .noCandidates:
                "No .xcworkspace or .xcodeproj found, and no .xcodeversions.yml entries resolved."
            case let .xcodePathNotInstalled(path):
                "\(path.path) does not match any discovered Xcode installation."
            case let .ambiguous(candidates):
                "Multiple targets matched: " + candidates.map(\.description).joined(separator: ", ")
            }
        }
    }

    private let fileManager: any FileManagerProtocol
    private let loader: XcodeVersionsLoader
    private let resolver: TargetResolver
    private let discovery: any XcodeDiscovery
    private let workingDirectory: URL
    private let stopAt: URL?

    /// Creates the candidate discovery, wiring up its loader and resolver.
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
    /// picker branch in that case. When `override` is given, `.xcodeversions.yml`
    /// resolution is bypassed entirely for every candidate.
    public func resolveCandidates(
        explicitTarget: String?,
        override: VersionOverride? = nil
    ) async throws -> [ResolvedTarget] {
        let installations = try await discovery.discoverInstallations()
        let loaded = try? loader.load(startingAt: workingDirectory, stopAt: stopAt)

        if let explicitTarget {
            let targetURL = URL(filePath: explicitTarget, relativeTo: workingDirectory)
            let installation = try resolveInstallation(
                for: targetURL,
                override: override,
                loaded: loaded,
                installations: installations
            )
            return [ResolvedTarget(path: targetURL, installation: installation)]
        }

        let candidatePaths = try candidateWorkspaceOrProjectPaths()
        guard !candidatePaths.isEmpty else { throw Error.noCandidates }

        return try candidatePaths.map { path in
            let installation = try resolveInstallation(
                for: path,
                override: override,
                loaded: loaded,
                installations: installations
            )
            return ResolvedTarget(path: path, installation: installation)
        }
    }

    private func resolveInstallation(
        for target: URL,
        override: VersionOverride?,
        loaded: XcodeVersionsLoader.LoadedConfiguration?,
        installations: [XcodeInstallation]
    ) throws -> XcodeInstallation {
        switch override {
        case let .appPath(appPath):
            guard let installation = installations.first(where: {
                $0.appPath.standardizedFileURL.resolvingSymlinksInPath()
                    == appPath.standardizedFileURL.resolvingSymlinksInPath()
            }) else {
                throw Error.xcodePathNotInstalled(appPath)
            }
            return installation
        case let .version(version):
            return try VersionMatcher.resolve(
                spec: VersionSpec(rawValue: version),
                installations: installations
            ).get()
        case nil:
            let spec = try versionSpec(for: target, loaded: loaded)
            return try VersionMatcher.resolve(spec: spec, installations: installations).get()
        }
    }

    private func versionSpec(
        for target: URL,
        loaded: XcodeVersionsLoader.LoadedConfiguration?
    ) throws -> VersionSpec {
        guard let loaded else {
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
