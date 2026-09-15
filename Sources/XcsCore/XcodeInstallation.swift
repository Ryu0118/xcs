import Foundation

/// A discovered Xcode.app installation.
public struct XcodeInstallation: Equatable, Sendable {
    /// The path to the Xcode.app bundle.
    public let appPath: URL
    /// The `CFBundleShortVersionString` of this installation.
    public let shortVersion: String

    /// Creates an installation.
    public init(appPath: URL, shortVersion: String) {
        self.appPath = appPath
        self.shortVersion = shortVersion
    }

    /// The `Contents/Developer` path used as `DEVELOPER_DIR` for this installation.
    public var developerDirectoryPath: URL {
        appPath.appending(path: "Contents/Developer")
    }
}
