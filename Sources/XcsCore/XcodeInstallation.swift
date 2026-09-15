import Foundation

public struct XcodeInstallation: Equatable, Sendable {
    public let appPath: URL
    public let shortVersion: String

    public init(appPath: URL, shortVersion: String) {
        self.appPath = appPath
        self.shortVersion = shortVersion
    }

    public var developerDirectoryPath: URL {
        appPath.appending(path: "Contents/Developer")
    }
}
