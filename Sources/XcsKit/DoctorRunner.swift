import FileManagerProtocol
import Foundation
import XcsConfig
import XcsCore

/// The outcome of resolving one `.xcodeversions.yml` entry.
public enum DoctorEntryResolution: Equatable, Sendable {
    /// The entry resolved successfully to the given version.
    case ok(version: String)
    /// The entry failed to resolve, with a human-readable description.
    case error(String)
}

/// The result of a full `xcs doctor` diagnostic run.
public struct DoctorReport: Equatable, Sendable {
    /// The path to the located `.xcodeversions.yml`, or `nil` if none was found.
    public let configurationFound: URL?
    /// `nil` when discovery itself failed — kept distinct from "discovery
    /// succeeded but found nothing" so a doctor run never silently hides
    /// that the discovery mechanism itself is broken.
    public let discoveredInstallations: [XcodeInstallation]?
    /// The resolution outcome for each `.xcodeversions.yml` target key.
    public let entryResolutions: [String: DoctorEntryResolution]

    /// Creates a report.
    public init(
        configurationFound: URL?,
        discoveredInstallations: [XcodeInstallation]?,
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

    /// Creates the runner.
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

    /// Runs discovery and resolves every `.xcodeversions.yml` entry, producing a full report.
    public func run() async -> DoctorReport {
        let installations = try? await discovery.discoverInstallations()
        let loader = XcodeVersionsLoader(fileManager: fileManager)
        let resolver = TargetResolver()

        guard let loaded = try? loader.load(startingAt: workingDirectory, stopAt: stopAt) else {
            return DoctorReport(configurationFound: nil, discoveredInstallations: installations, entryResolutions: [:])
        }

        var resolutions: [String: DoctorEntryResolution] = [:]
        for (key, versionString) in loaded.document.targets {
            let targetURL = loaded.configurationDirectory.appending(path: key)
            do {
                let spec = try resolver.resolve(
                    target: targetURL,
                    relativeTo: loaded.configurationDirectory,
                    in: loaded.document
                ).get()
                _ = try VersionMatcher.resolve(spec: spec, installations: installations ?? []).get()
                resolutions[key] = .ok(version: versionString)
            } catch {
                resolutions[key] = .error(String(describing: error))
            }
        }

        return DoctorReport(
            configurationFound: loaded.configurationDirectory.appending(path: ".xcodeversions.yml"),
            discoveredInstallations: installations,
            entryResolutions: resolutions
        )
    }
}
