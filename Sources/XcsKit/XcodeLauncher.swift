import Foundation
import XcsCore

public protocol XcodeLauncher: Sendable {
    func launch(installation: XcodeInstallation, filePath: URL) throws
}

/// Launches Xcode by directly exec'ing the app bundle's binary, bypassing
/// Launch Services entirely. This is the only mechanism confirmed to work
/// when multiple Xcode versions share the same bundle identifier
/// (`com.apple.dt.Xcode`) — `open -a`/`xed` fail with `-10664` in that case
/// (verified on-device, see design spec).
public struct DirectExecXcodeLauncher: XcodeLauncher {
    public init() {}

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
