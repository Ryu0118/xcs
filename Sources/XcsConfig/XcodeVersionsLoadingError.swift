import Foundation

/// A failure encountered while locating, reading, or decoding `.xcodeversions.yml`.
public enum XcodeVersionsLoadingError: Error, Equatable, Sendable, CustomStringConvertible {
    /// No `.xcodeversions.yml` was found in any ancestor of `startingFrom`.
    case configurationFileNotFound(startingFrom: URL)
    /// The file at `URL` exists but could not be read as UTF-8.
    case configurationFileUnreadable(URL)
    /// The file at `URL` could not be decoded as valid YAML.
    case invalidYAML(URL)

    /// A human-readable explanation of the failure.
    public var description: String {
        switch self {
        case let .configurationFileNotFound(startingFrom):
            "No .xcodeversions.yml found in \(startingFrom.path) or any ancestor directory."
        case let .configurationFileUnreadable(url):
            "Could not read .xcodeversions.yml at \(url.path)."
        case let .invalidYAML(url):
            "The .xcodeversions.yml at \(url.path) is not valid YAML."
        }
    }
}
