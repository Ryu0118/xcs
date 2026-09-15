#if canImport(Glibc)
    import Glibc
#else
    import Darwin
#endif
import Foundation

public protocol Execer: Sendable {
    func exec(command: [String], developerDirectory: String) throws -> Never
}

/// Replaces the current process image with `command`, having set
/// `DEVELOPER_DIR`. Used by `xcs exec` so stdio, signals, and exit codes are
/// inherited transparently by the replaced process — no wrapper process
/// stays around to relay them.
///
/// Note: `execvpe` is a glibc extension and does not exist on Darwin. The
/// portable form here sets the environment variable in the current process
/// and calls `execvp`, which resolves via `PATH` and inherits `environ`.
public struct SystemExecer: Execer {
    public init() {}

    public enum Error: Swift.Error, Equatable, Sendable, CustomStringConvertible {
        case emptyCommand
        case execFailed(errno: Int32)

        public var description: String {
            switch self {
            case .emptyCommand:
                "xcs exec requires a command to run."
            case let .execFailed(errno):
                "execvp failed with errno \(errno): \(String(cString: strerror(errno)))."
            }
        }
    }

    public func exec(command: [String], developerDirectory: String) throws -> Never {
        guard let executableName = command.first else {
            throw Error.emptyCommand
        }

        setenv("DEVELOPER_DIR", developerDirectory, 1)
        fflush(nil) // flush stdio buffers before the process image is replaced

        var cArgs: [UnsafeMutablePointer<CChar>?] = command.map { strdup($0) }
        cArgs.append(nil)
        defer { cArgs.forEach { free($0) } }

        execvp(executableName, &cArgs)
        // Only reached if execvp fails.
        throw Error.execFailed(errno: errno)
    }
}
