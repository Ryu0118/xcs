import FileManagerProtocol
import Foundation

/// Bundles `XcodeVersionsLocator` and `XcodeVersionsDecoder`. Returns `nil`
/// when no `.xcodeversions.yml` exists in any ancestor, so callers can fall
/// back to cwd-directory candidate discovery (see `XcsKit.CandidateDiscovery`).
public struct XcodeVersionsLoader: Sendable {
    private let locator: XcodeVersionsLocator
    private let decoder: XcodeVersionsDecoder

    /// Creates the loader.
    public init(fileManager: any FileManagerProtocol) {
        locator = XcodeVersionsLocator(fileManager: fileManager)
        decoder = XcodeVersionsDecoder(fileManager: fileManager)
    }

    /// A decoded `.xcodeversions.yml` document paired with the directory it was found in.
    public struct LoadedConfiguration: Equatable, Sendable {
        /// The decoded document.
        public let document: XcodeVersionsDocument
        /// The directory containing the `.xcodeversions.yml` file.
        public let configurationDirectory: URL

        /// Creates a loaded configuration.
        public init(document: XcodeVersionsDocument, configurationDirectory: URL) {
            self.document = document
            self.configurationDirectory = configurationDirectory
        }
    }

    /// Locates and decodes `.xcodeversions.yml`, returning `nil` if none exists in any ancestor.
    public func load(startingAt: URL, stopAt: URL? = nil) throws -> LoadedConfiguration? {
        guard let configURL = locator.locate(startingAt: startingAt, stopAt: stopAt) else {
            return nil
        }
        let document = try decoder.decode(configURL)
        return LoadedConfiguration(
            document: document,
            configurationDirectory: configURL.deletingLastPathComponent()
        )
    }
}
