/// A version string (e.g. `"27"` or `"27.1"`) requested for an Xcode installation.
public struct VersionSpec: Equatable, Sendable {
    /// The raw version string, as written in `.xcodeversions.yml` or a `--xcode` flag.
    public let rawValue: String

    /// Creates a version spec from a raw string.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
