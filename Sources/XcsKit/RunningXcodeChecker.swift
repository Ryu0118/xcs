import AppKit
import XcsCore

/// Checks whether a specific Xcode installation is currently running.
public protocol RunningXcodeChecker: Sendable {
    /// Returns whether `installation` is currently running.
    func isRunning(installation: XcodeInstallation) -> Bool
}

/// Checks whether a specific Xcode installation is currently running via
/// `NSWorkspace.runningApplications`. This reads Launch Services' notion of
/// running apps without going through its "launch" path, so it is unrelated
/// to the `-10664` bundle-ID collision that blocks `open -a`/`xed`.
public struct NSWorkspaceRunningXcodeChecker: RunningXcodeChecker {
    /// Creates the checker.
    public init() {}

    /// Returns whether `installation`'s app bundle matches a currently running Xcode process.
    public func isRunning(installation: XcodeInstallation) -> Bool {
        let target = installation.appPath.standardizedFileURL.resolvingSymlinksInPath().path
        return NSWorkspace.shared.runningApplications.contains { app in
            guard app.bundleIdentifier == "com.apple.dt.Xcode" else { return false }
            let runningPath = app.bundleURL?.standardizedFileURL.resolvingSymlinksInPath().path
            return runningPath == target
        }
    }
}
