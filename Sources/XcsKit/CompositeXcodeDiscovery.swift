import XcsCore

/// Tries a primary discovery mechanism first (mdfind), falling back to a
/// secondary one (/Applications glob) when the primary yields nothing or
/// throws. Throws `XcodeDiscoveryError.noInstallationsFound` only when both
/// fail.
public struct CompositeXcodeDiscovery: XcodeDiscovery {
    private let primary: any XcodeDiscovery
    private let fallback: any XcodeDiscovery

    public init(primary: any XcodeDiscovery, fallback: any XcodeDiscovery) {
        self.primary = primary
        self.fallback = fallback
    }

    public func discoverInstallations() async throws -> [XcodeInstallation] {
        let primaryResult = (try? await primary.discoverInstallations()) ?? []
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
