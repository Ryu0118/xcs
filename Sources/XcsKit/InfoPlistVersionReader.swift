import Foundation

/// Reads `CFBundleShortVersionString` from an app bundle's `Info.plist`
/// in-process, without shelling out to `defaults`.
public struct InfoPlistVersionReader: Sendable {
    /// Creates the reader.
    public init() {}

    /// A failure encountered while reading an app bundle's version.
    public enum Error: Swift.Error, Equatable, Sendable, CustomStringConvertible {
        /// `Info.plist` does not exist at the expected location.
        case infoPlistNotFound(URL)
        /// `Info.plist` exists but lacks a `CFBundleShortVersionString` key.
        case versionKeyMissing(URL)

        /// A human-readable explanation of the failure.
        public var description: String {
            switch self {
            case let .infoPlistNotFound(url):
                "Info.plist not found at \(url.path)."
            case let .versionKeyMissing(url):
                "CFBundleShortVersionString missing from \(url.path)."
            }
        }
    }

    /// Reads `CFBundleShortVersionString` from the app bundle at `appPath`.
    public func shortVersion(ofAppAt appPath: URL) throws -> String {
        let infoPlistURL = appPath.appending(path: "Contents/Info.plist")
        guard let data = FileManager.default.contents(atPath: infoPlistURL.path) else {
            throw Error.infoPlistNotFound(infoPlistURL)
        }
        guard
            let plist = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any],
            let version = plist["CFBundleShortVersionString"] as? String
        else {
            throw Error.versionKeyMissing(infoPlistURL)
        }
        return version
    }
}
