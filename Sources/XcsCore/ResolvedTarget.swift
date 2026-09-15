import Foundation

public struct ResolvedTarget: Equatable, Sendable, CustomStringConvertible {
    public let path: URL
    public let installation: XcodeInstallation

    public init(path: URL, installation: XcodeInstallation) {
        self.path = path
        self.installation = installation
    }

    public var description: String {
        "\(path.lastPathComponent)  (Xcode \(installation.shortVersion))"
    }
}
