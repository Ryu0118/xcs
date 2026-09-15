import XcsCore
import XcsKit

/// Thin JSON-encodable mirrors of XcsCore/XcsKit result types. Kept in
/// XcsCLI so those layers stay free of presentation/encoding concerns.
struct ResolvedTargetJSON: Encodable {
    let path: String
    let xcodeVersion: String
    let xcodeAppPath: String

    init(_ target: ResolvedTarget) {
        path = target.path.path
        xcodeVersion = target.installation.shortVersion
        xcodeAppPath = target.installation.appPath.path
    }
}

struct ListedInstallationJSON: Encodable {
    let appPath: String
    let version: String
    let running: Bool

    init(_ listed: ListedInstallation) {
        appPath = listed.installation.appPath.path
        version = listed.installation.shortVersion
        running = listed.isRunning
    }
}

/// Tagged rather than a flattened human-readable string, since `--json`
/// output is meant to be machine-parsed without re-parsing prose.
struct DoctorEntryResolutionJSON: Encodable {
    let status: String
    let version: String?
    let message: String?

    init(_ resolution: DoctorEntryResolution) {
        switch resolution {
        case let .ok(version):
            status = "ok"
            self.version = version
            message = nil
        case let .error(errorMessage):
            status = "error"
            version = nil
            message = errorMessage
        }
    }
}

struct DoctorReportJSON: Encodable {
    let configurationFound: String?
    /// `nil` when discovery itself failed, distinct from an empty array.
    let discoveredInstallations: [String]?
    let entryResolutions: [String: DoctorEntryResolutionJSON]

    init(_ report: DoctorReport) {
        configurationFound = report.configurationFound?.path
        discoveredInstallations = report.discoveredInstallations?.map(\.shortVersion)
        entryResolutions = report.entryResolutions.mapValues(DoctorEntryResolutionJSON.init)
    }
}
