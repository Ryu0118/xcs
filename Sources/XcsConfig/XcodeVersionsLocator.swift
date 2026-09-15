import FileManagerProtocol
import Foundation

/// Locates `.xcodeversions.yml` by walking up from a starting directory
/// toward the filesystem root. There is no reference implementation for
/// this in x8-new: its `X8ConfigurationLocator` only checks a single
/// directory. This ancestor-walk is new for xcs.
public struct XcodeVersionsLocator: Sendable {
    private let fileManager: any FileManagerProtocol
    private let fileName = ".xcodeversions.yml"

    public init(fileManager: any FileManagerProtocol) {
        self.fileManager = fileManager
    }

    /// Searches ancestors of `startingAt` for `.xcodeversions.yml`.
    ///
    /// - Parameter stopAt: When provided, the search stops at this directory
    ///   (inclusive) without walking further up. Tests must always pass this
    ///   to avoid escaping a fixture root and picking up a real config file
    ///   from the actual filesystem (e.g. the user's home directory).
    public func locate(startingAt: URL, stopAt: URL? = nil) -> URL? {
        var current = startingAt.standardizedFileURL.resolvingSymlinksInPath()
        let stop = stopAt?.standardizedFileURL.resolvingSymlinksInPath()

        while true {
            let candidate = current.appending(path: fileName)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            if let stop, current.path == stop.path {
                return nil
            }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path {
                return nil
            }
            current = parent
        }
    }
}
