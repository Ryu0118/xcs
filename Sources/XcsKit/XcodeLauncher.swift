import Foundation
import XcsCore

/// Launches Xcode to open a workspace or project.
public protocol XcodeLauncher: Sendable {
    /// Opens `filePath` with the given Xcode `installation`.
    func launch(installation: XcodeInstallation, filePath: URL) throws
}

/// Launches Xcode by directly exec'ing the app bundle's binary, bypassing
/// Launch Services entirely. This is the only mechanism confirmed to work
/// when multiple Xcode versions share the same bundle identifier
/// (`com.apple.dt.Xcode`) — `open -a`/`xed` fail with `-10664` in that case
/// (verified on-device, see design spec).
public struct DirectExecXcodeLauncher: XcodeLauncher {
    /// Creates the launcher.
    public init() {}

    /// Execs the Xcode binary at `installation`'s bundle directly, passing `filePath` to open.
    public func launch(installation: XcodeInstallation, filePath: URL) throws {
        let process = Process()
        process.executableURL = installation.appPath.appending(path: "Contents/MacOS/Xcode")
        process.arguments = [filePath.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        try process.run()
        // Deliberately not calling waitUntilExit() — fire-and-forget, matching xed's non-blocking default.
    }
}
