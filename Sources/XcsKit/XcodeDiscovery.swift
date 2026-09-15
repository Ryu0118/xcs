import XcsCore

/// Discovers installed Xcode versions.
public protocol XcodeDiscovery: Sendable {
    /// Returns every Xcode installation this mechanism can find.
    func discoverInstallations() async throws -> [XcodeInstallation]
}

/// A failure encountered while discovering Xcode installations.
public enum XcodeDiscoveryError: Error, Equatable, Sendable, CustomStringConvertible {
    /// No Xcode installations were found by any discovery mechanism.
    case noInstallationsFound

    /// A human-readable explanation of the failure.
    public var description: String {
        switch self {
        case .noInstallationsFound:
            "No Xcode installations were found via mdfind or in /Applications."
        }
    }
}
