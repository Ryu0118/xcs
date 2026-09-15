import FileManagerProtocol
import Foundation
import XcsCore

/// Fallback discovery mechanism, used when `mdfind` is unavailable or
/// returns nothing: list `/Applications` directly and filter to
/// `Xcode*.app` entries (a single-directory prefix/suffix filter, not a
/// full glob engine — the pattern is fixed and shallow enough that pulling
/// in `Glob` for it would be more machinery than the job needs).
public struct ApplicationsGlobXcodeDiscovery: XcodeDiscovery {
    private let fileManager: any FileManagerProtocol
    private let versionReader: InfoPlistVersionReader
    private let applicationsDirectory: URL

    /// Creates the discovery mechanism.
    public init(
        fileManager: any FileManagerProtocol,
        versionReader: InfoPlistVersionReader = InfoPlistVersionReader(),
        applicationsDirectory: URL = URL(filePath: "/Applications")
    ) {
        self.fileManager = fileManager
        self.versionReader = versionReader
        self.applicationsDirectory = applicationsDirectory
    }

    /// Lists `Xcode*.app` bundles directly under `applicationsDirectory`.
    public func discoverInstallations() async throws -> [XcodeInstallation] {
        let entries = (try? fileManager.contentsOfDirectory(atPath: applicationsDirectory.path)) ?? []
        let candidates = entries.filter { $0.hasPrefix("Xcode") && $0.hasSuffix(".app") }

        return candidates.compactMap { name in
            let url = applicationsDirectory.appending(path: name)
            guard let version = try? versionReader.shortVersion(ofAppAt: url) else { return nil }
            return XcodeInstallation(appPath: url, shortVersion: version)
        }
    }
}
