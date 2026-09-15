import XcsCore

public protocol XcodeDiscovery: Sendable {
    func discoverInstallations() async throws -> [XcodeInstallation]
}

public enum XcodeDiscoveryError: Error, Equatable, Sendable, CustomStringConvertible {
    case noInstallationsFound

    public var description: String {
        switch self {
        case .noInstallationsFound:
            "No Xcode installations were found via mdfind or in /Applications."
        }
    }
}
