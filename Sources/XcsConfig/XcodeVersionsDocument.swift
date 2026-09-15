/// The decoded contents of a `.xcodeversions.yml` file.
public struct XcodeVersionsDocument: Codable, Equatable, Sendable {
    /// Maps a workspace/project key (or glob) to its pinned Xcode version spec.
    public let targets: [String: String]

    /// Creates a document with the given target mappings.
    public init(targets: [String: String]) {
        self.targets = targets
    }
}
