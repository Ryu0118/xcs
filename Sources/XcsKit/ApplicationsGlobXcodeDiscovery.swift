import FileManagerProtocol
import Foundation
import XcsCore

/// Fallback discovery mechanism: glob `/Applications/Xcode*.app` directly,
/// used when `mdfind` is unavailable or returns nothing.
public struct ApplicationsGlobXcodeDiscovery: XcodeDiscovery {
    private let fileManager: any FileManagerProtocol
    private let versionReader: InfoPlistVersionReader
    private let applicationsDirectory: URL

    public init(
        fileManager: any FileManagerProtocol,
        versionReader: InfoPlistVersionReader = InfoPlistVersionReader(),
        applicationsDirectory: URL = URL(fileURLWithPath: "/Applications")
    ) {
        self.fileManager = fileManager
        self.versionReader = versionReader
        self.applicationsDirectory = applicationsDirectory
    }

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
