import XcsCore

/// Tries a primary discovery mechanism first (mdfind), falling back to a
/// secondary one (/Applications glob) when the primary yields nothing or
/// throws. Throws `XcodeDiscoveryError.noInstallationsFound` only when both
/// fail.
public struct CompositeXcodeDiscovery: XcodeDiscovery {
    private let primary: any XcodeDiscovery
    private let fallback: any XcodeDiscovery

    /// Creates the composite discovery from a primary and fallback mechanism.
    public init(primary: any XcodeDiscovery, fallback: any XcodeDiscovery) {
        self.primary = primary
        self.fallback = fallback
    }

    /// Discovers installations via the primary mechanism, falling back to the secondary one.
    public func discoverInstallations() async throws -> [XcodeInstallation] {
        let primaryResult = await (try? primary.discoverInstallations()) ?? []
        if !primaryResult.isEmpty {
            return primaryResult
        }

        let fallbackResult = try await fallback.discoverInstallations()
        guard !fallbackResult.isEmpty else {
            throw XcodeDiscoveryError.noInstallationsFound
        }
        return fallbackResult
    }
}
