import Foundation

/// A discovered Xcode.app installation.
public struct XcodeInstallation: Equatable, Sendable, CustomStringConvertible {
    /// The `licenseType` reported by an installation's `LicenseInfo.plist`.
    public enum LicenseType: String, Equatable, Sendable {
        /// A general-release (non-beta) build.
        case gm = "GM"
        /// A beta/seed build.
        case beta = "Beta"
    }

    /// The path to the Xcode.app bundle.
    public let appPath: URL
    /// The `CFBundleShortVersionString` of this installation.
    public let shortVersion: String
    /// The `licenseType` from `Contents/Resources/LicenseInfo.plist`, when present.
    /// `nil` when the file is missing or its `licenseType` doesn't match a known case —
    /// callers must treat `nil` as "unknown", never as "not beta".
    public let licenseType: LicenseType?

    /// Creates an installation.
    public init(appPath: URL, shortVersion: String, licenseType: LicenseType? = nil) {
        self.appPath = appPath
        self.shortVersion = shortVersion
        self.licenseType = licenseType
    }

    /// The `Contents/Developer` path used as `DEVELOPER_DIR` for this installation.
    public var developerDirectoryPath: URL {
        appPath.appending(path: "Contents/Developer")
    }

    /// A human-readable rendering including path and license type, not just
    /// `shortVersion` — distinct installations (a beta seed and its GM) can
    /// report the identical `shortVersion` string, so `shortVersion` alone is
    /// not enough to tell candidates apart in error/diagnostic output.
    public var description: String {
        let license = licenseType.map { " [\($0.rawValue)]" } ?? ""
        return "\(shortVersion) (\(appPath.path))\(license)"
    }
}
