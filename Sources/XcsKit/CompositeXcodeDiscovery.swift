import XcsCore

/// Combines a primary discovery mechanism (mdfind) with a secondary one
/// (/Applications glob). Both always run: Spotlight can index some volumes
/// but not the one holding `/Applications`, so a non-empty mdfind result can
/// still be missing installations the glob finds. Results are merged in
/// primary-then-fallback order, listing each app path once. A failure of
/// either mechanism is tolerated; throws
/// `XcodeDiscoveryError.noInstallationsFound` only when the merged list is
/// empty.
public struct CompositeXcodeDiscovery: XcodeDiscovery {
    private let primary: any XcodeDiscovery
    private let fallback: any XcodeDiscovery

    /// Creates the composite discovery from a primary and fallback mechanism.
    public init(primary: any XcodeDiscovery, fallback: any XcodeDiscovery) {
        self.primary = primary
        self.fallback = fallback
    }

    /// Discovers installations via both mechanisms and merges them, primary first.
    public func discoverInstallations() async throws -> [XcodeInstallation] {
        let primaryResult = await (try? primary.discoverInstallations()) ?? []
        let fallbackResult = await (try? fallback.discoverInstallations()) ?? []

        var seenPaths = Set<String>()
        let merged = (primaryResult + fallbackResult).filter { installation in
            seenPaths.insert(installation.appPath.standardizedFileURL.path).inserted
        }
        guard !merged.isEmpty else {
            throw XcodeDiscoveryError.noInstallationsFound
        }
        return merged
    }
}
