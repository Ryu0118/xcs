import XcsCore

public struct ListedInstallation: Equatable, Sendable {
    public let installation: XcodeInstallation
    public let isRunning: Bool

    public init(installation: XcodeInstallation, isRunning: Bool) {
        self.installation = installation
        self.isRunning = isRunning
    }
}

public struct ListRunner: Sendable {
    private let discovery: any XcodeDiscovery
    private let runningChecker: any RunningXcodeChecker

    public init(discovery: any XcodeDiscovery, runningChecker: any RunningXcodeChecker) {
        self.discovery = discovery
        self.runningChecker = runningChecker
    }

    public func run() async throws -> [ListedInstallation] {
        let installations = try await discovery.discoverInstallations()
        return installations.map { installation in
            ListedInstallation(
                installation: installation,
                isRunning: runningChecker.isRunning(installation: installation)
            )
        }
    }
}
