import FileManagerProtocol
import Foundation
import Yams

/// Decodes `.xcodeversions.yml`. Mirrors x8-new's `X8ConfigurationDecoder`
/// pattern: read the file as UTF-8, then decode with `YAMLDecoder`.
public struct XcodeVersionsDecoder: Sendable {
    private let fileManager: any FileManagerProtocol

    /// Creates the decoder.
    public init(fileManager: any FileManagerProtocol) {
        self.fileManager = fileManager
    }

    /// Reads and decodes the `.xcodeversions.yml` at `url`.
    public func decode(_ url: URL) throws -> XcodeVersionsDocument {
        let source = try readSource(from: url)
        do {
            return try YAMLDecoder().decode(XcodeVersionsDocument.self, from: source)
        } catch {
            throw XcodeVersionsLoadingError.invalidYAML(url)
        }
    }

    private func readSource(from url: URL) throws -> String {
        guard let data = fileManager.contents(atPath: url.path),
              let source = String(data: data, encoding: .utf8)
        else {
            throw XcodeVersionsLoadingError.configurationFileUnreadable(url)
        }
        return source
    }
}
