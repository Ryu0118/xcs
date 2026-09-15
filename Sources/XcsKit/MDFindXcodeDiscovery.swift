import Foundation
import XcsCore

/// Discovers installed Xcode versions via Spotlight (`mdfind`). Primary
/// discovery mechanism per design spec; catches installs anywhere, not
/// just `/Applications`.
public struct MDFindXcodeDiscovery: XcodeDiscovery {
    private let versionReader: InfoPlistVersionReader

    /// Creates the discovery mechanism.
    public init(versionReader: InfoPlistVersionReader = InfoPlistVersionReader()) {
        self.versionReader = versionReader
    }

    /// Finds Xcode installations by querying Spotlight for the Xcode bundle identifier.
    public func discoverInstallations() async throws -> [XcodeInstallation] {
        let paths = try runMDFind()
        return paths.compactMap { path in
            let url = URL(filePath: path)
            guard let version = try? versionReader.shortVersion(ofAppAt: url) else { return nil }
            return XcodeInstallation(appPath: url, shortVersion: version)
        }
    }

    private func runMDFind() throws -> [String] {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/mdfind")
        process.arguments = ["kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else { return [] }
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        return output
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}
