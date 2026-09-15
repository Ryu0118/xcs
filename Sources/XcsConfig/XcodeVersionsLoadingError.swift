import Foundation

public enum XcodeVersionsLoadingError: Error, Equatable, Sendable, CustomStringConvertible {
    case configurationFileNotFound(startingFrom: URL)
    case configurationFileUnreadable(URL)
    case invalidYAML(URL)

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
