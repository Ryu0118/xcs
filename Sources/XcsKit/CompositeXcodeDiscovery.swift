import Foundation
import XcsCore

/// Runs every discovery mechanism and merges their results, so an install
/// that only one mechanism can see is never dropped. Spotlight (`mdfind`)
/// finds installs anywhere but silently misses volumes whose index is
/// disabled or not yet built (e.g. `/Applications` with indexing off), while
/// the `/Applications` scan always sees its own directory — neither one is a
/// superset of the other, so falling back only when the first returns nothing
/// would hide installs.
///
/// Results keep the order of `discoveries`, and an app bundle reported by
/// several mechanisms (same path, a symlink to it, or the same bundle through
/// a firmlink such as `/System/Volumes/Data/Applications`) is kept once, as
/// first reported. A mechanism that throws contributes nothing. Throws
/// `XcodeDiscoveryError.noInstallationsFound` only when every mechanism finds
/// nothing.
public struct CompositeXcodeDiscovery: XcodeDiscovery {
    private let discoveries: [any XcodeDiscovery]

    /// Creates the composite discovery from mechanisms listed in priority order.
    public init(_ discoveries: [any XcodeDiscovery]) {
        self.discoveries = discoveries
    }

    /// Discovers installations via every mechanism and merges them without duplicates.
    public func discoverInstallations() async throws -> [XcodeInstallation] {
        var seen: Set<String> = []
        var merged: [XcodeInstallation] = []
        for discovery in discoveries {
            let found = await (try? discovery.discoverInstallations()) ?? []
            merged += found.filter { seen.insert(Self.identity(of: $0.appPath)).inserted }
        }
        guard !merged.isEmpty else {
            throw XcodeDiscoveryError.noInstallationsFound
        }
        return merged
    }

    /// The key two paths share when they name the same bundle on disk: the
    /// device and inode of the symlink-resolved path when it exists, otherwise
    /// the normalized path string.
    private static func identity(of appPath: URL) -> String {
        let resolved = appPath.standardizedFileURL.resolvingSymlinksInPath()
        if let attributes = try? FileManager.default.attributesOfItem(atPath: resolved.path),
           let device = attributes[.systemNumber],
           let inode = attributes[.systemFileNumber]
        {
            return "inode:\(device):\(inode)"
        }
        return "path:\(resolved.path)"
    }
}
