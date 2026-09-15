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

struct DoctorReportJSON: Encodable {
    let configurationFound: String?
    let discoveredInstallations: [String]
    let entryResolutions: [String: String]

    init(_ report: DoctorReport) {
        configurationFound = report.configurationFound?.path
        discoveredInstallations = report.discoveredInstallations.map(\.shortVersion)
        entryResolutions = report.entryResolutions.mapValues { result in
            switch result {
            case let .ok(version): "ok (\(version))"
            case let .error(message): "error: \(message)"
            }
        }
    }
}
