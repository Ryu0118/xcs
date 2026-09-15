import XcsCore

/// An Xcode installation paired with whether it is currently running.
public struct ListedInstallation: Equatable, Sendable {
    /// The discovered installation.
    public let installation: XcodeInstallation
    /// Whether this installation is currently running.
    public let isRunning: Bool

    /// Creates a listed installation.
    public init(installation: XcodeInstallation, isRunning: Bool) {
        self.installation = installation
        self.isRunning = isRunning
    }
}

/// Discovers installed Xcode versions and reports which are currently running.
public struct ListRunner: Sendable {
    private let discovery: any XcodeDiscovery
    private let runningChecker: any RunningXcodeChecker

    /// Creates the runner.
    public init(discovery: any XcodeDiscovery, runningChecker: any RunningXcodeChecker) {
        self.discovery = discovery
        self.runningChecker = runningChecker
    }

    /// Discovers installations and annotates each with its running state.
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
