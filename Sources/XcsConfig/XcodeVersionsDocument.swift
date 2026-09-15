public struct XcodeVersionsDocument: Codable, Equatable, Sendable {
    public let targets: [String: String]

    public init(targets: [String: String]) {
        self.targets = targets
    }
}
