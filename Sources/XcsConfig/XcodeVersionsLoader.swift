import FileManagerProtocol
import Foundation

/// Bundles `XcodeVersionsLocator` and `XcodeVersionsDecoder`. Returns `nil`
/// when no `.xcodeversions.yml` exists in any ancestor, so callers can fall
/// back to cwd-directory candidate discovery (see `XcsKit.CandidateDiscovery`).
public struct XcodeVersionsLoader: Sendable {
    private let locator: XcodeVersionsLocator
    private let decoder: XcodeVersionsDecoder

    public init(fileManager: any FileManagerProtocol) {
        locator = XcodeVersionsLocator(fileManager: fileManager)
        decoder = XcodeVersionsDecoder(fileManager: fileManager)
    }

    public struct LoadedConfiguration: Equatable, Sendable {
        public let document: XcodeVersionsDocument
        public let configurationDirectory: URL

        public init(document: XcodeVersionsDocument, configurationDirectory: URL) {
            self.document = document
            self.configurationDirectory = configurationDirectory
        }
    }

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
