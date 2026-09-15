import FileManagerProtocol
import Foundation
import XcsConfig
import XcsCore

public enum DoctorEntryResolution: Equatable, Sendable {
    case ok(version: String)
    case error(String)
}

public struct DoctorReport: Equatable, Sendable {
    public let configurationFound: URL?
    public let discoveredInstallations: [XcodeInstallation]
    public let entryResolutions: [String: DoctorEntryResolution]

    public init(
        configurationFound: URL?,
        discoveredInstallations: [XcodeInstallation],
        entryResolutions: [String: DoctorEntryResolution]
    ) {
        self.configurationFound = configurationFound
        self.discoveredInstallations = discoveredInstallations
        self.entryResolutions = entryResolutions
    }
}

/// Diagnoses `.xcodeversions.yml` discovery and each entry's resolvability,
/// plus whether any Xcode installations were found at all.
public struct DoctorRunner: Sendable {
    private let fileManager: any FileManagerProtocol
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
        self.discovery = discovery
        self.workingDirectory = workingDirectory
        self.stopAt = stopAt
    }

    public func run() async throws -> DoctorReport {
        let installations = try? await discovery.discoverInstallations()
        let loader = XcodeVersionsLoader(fileManager: fileManager)
        let resolver = TargetResolver()

        guard let loaded = try? loader.load(startingAt: workingDirectory, stopAt: stopAt) else {
            return DoctorReport(
                configurationFound: nil,
                discoveredInstallations: installations ?? [],
                entryResolutions: [:]
            )
        }

        var resolutions: [String: DoctorEntryResolution] = [:]
        for (key, versionString) in loaded.document.targets {
            let targetURL = loaded.configurationDirectory.appending(path: key)
            let specResult = resolver.resolve(
                target: targetURL,
                relativeTo: loaded.configurationDirectory,
                in: loaded.document
            )
            switch specResult {
            case let .success(spec):
                let matchResult = VersionMatcher.resolve(spec: spec, installations: installations ?? [])
                switch matchResult {
                case .success:
                    resolutions[key] = .ok(version: versionString)
                case let .failure(error):
                    resolutions[key] = .error(error.description)
                }
            case let .failure(error):
                resolutions[key] = .error(error.description)
            }
        }

        return DoctorReport(
            configurationFound: loaded.configurationDirectory.appending(path: ".xcodeversions.yml"),
            discoveredInstallations: installations ?? [],
            entryResolutions: resolutions
        )
    }
}
