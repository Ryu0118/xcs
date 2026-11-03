import FileManagerProtocol
import Foundation
import XcsCore

/// Lists an applications directory (`/Applications` by default) directly and
/// keeps the `Xcode*.app` entries whose bundle identifier is Xcode's. Runs
/// alongside `mdfind` (see `CompositeXcodeDiscovery`) because Spotlight misses
/// directories whose index is disabled or not yet built. The name filter is
/// a single-directory prefix/suffix filter, not a full glob engine — the
/// pattern is fixed and shallow enough that pulling in `Glob` for it would be
/// more machinery than the job needs.
public struct ApplicationsGlobXcodeDiscovery: XcodeDiscovery {
    private let fileManager: any FileManagerProtocol
    private let versionReader: InfoPlistVersionReader
    private let applicationsDirectory: URL

    private static let xcodeBundleIdentifier = "com.apple.dt.Xcode"

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

    /// Lists Xcode bundles named `Xcode*.app` directly under `applicationsDirectory` (not recursive).
    public func discoverInstallations() async throws -> [XcodeInstallation] {
        let entries = (try? fileManager.contentsOfDirectory(atPath: applicationsDirectory.path)) ?? []
        let candidates = entries.filter { $0.hasPrefix("Xcode") && $0.hasSuffix(".app") }

        return candidates.compactMap { name in
            let url = applicationsDirectory.appending(path: name)
            guard
                versionReader.bundleIdentifier(ofAppAt: url) == Self.xcodeBundleIdentifier,
                let version = try? versionReader.shortVersion(ofAppAt: url)
            else {
                return nil
            }
            let licenseType = versionReader.licenseType(ofAppAt: url)
            return XcodeInstallation(appPath: url, shortVersion: version, licenseType: licenseType)
        }
    }
}
