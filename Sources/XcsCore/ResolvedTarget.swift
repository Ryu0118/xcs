import Foundation

/// A workspace/project path paired with the Xcode installation resolved for it.
public struct ResolvedTarget: Equatable, Sendable, CustomStringConvertible {
    /// The path to the workspace or project.
    public let path: URL
    /// The Xcode installation resolved for this target.
    public let installation: XcodeInstallation

    /// Creates a resolved target.
    public init(path: URL, installation: XcodeInstallation) {
        self.path = path
        self.installation = installation
    }

    /// A short human-readable summary of the target and its resolved Xcode version.
    public var description: String {
        "\(path.lastPathComponent)  (Xcode \(installation.shortVersion))"
    }
}
