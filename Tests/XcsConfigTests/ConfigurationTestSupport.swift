import Foundation

/// Creates and tears down a temporary directory tree for fixture-based
/// config tests. Mirrors x8-new's `ConfigurationTestSupport` pattern.
enum ConfigurationTestSupport {
    static func withDirectory(_ body: (URL) async throws -> Void) async throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "xcs-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try await body(root)
    }

    static func write(_ source: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try source.write(to: url, atomically: true, encoding: .utf8)
    }
}
