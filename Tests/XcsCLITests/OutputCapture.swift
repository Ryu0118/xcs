import Foundation

/// Captures everything written to stdout during `body`, for asserting on a
/// command's printed output (including `print`-based JSON output).
///
/// Redirects fd 1 to a temp file rather than a `Pipe`: a pipe's read side
/// blocks on `readDataToEndOfFile()` until every reference to the write end
/// is closed, and `dup2`-ing fd 1 leaves the process's original stdout
/// reference open — the pipe's write end never fully closes, so the read
/// hangs forever. A temp file has no such "still open elsewhere" ambiguity.
///
/// Because fd 1 is a single process-wide resource, capture calls across
/// concurrently-running test suites would otherwise interleave into each
/// other's output. `lock` serializes them regardless of which suite or test
/// runner thread is calling.
enum OutputCapture {
    private actor Lock {
        private var isLocked = false
        private var waiters: [CheckedContinuation<Void, Never>] = []

        func acquire() async {
            if !isLocked {
                isLocked = true
                return
            }
            await withCheckedContinuation { waiters.append($0) }
        }

        func release() {
            if waiters.isEmpty {
                isLocked = false
            } else {
                waiters.removeFirst().resume()
            }
        }
    }

    private static let lock = Lock()

    static func capture(_ body: () async throws -> Void) async throws -> String {
        await lock.acquire()
        do {
            let result = try await captureUnlocked(body)
            await lock.release()
            return result
        } catch {
            await lock.release()
            throw error
        }
    }

    private static func captureUnlocked(_ body: () async throws -> Void) async throws -> String {
        let tempURL = FileManager.default.temporaryDirectory
            .appending(path: "xcs-output-capture-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: tempURL.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let captureHandle = try FileHandle(forWritingTo: tempURL)
        let originalStdout = dup(1)
        dup2(captureHandle.fileDescriptor, 1)

        do {
            try await body()
        } catch {
            fflush(stdout)
            dup2(originalStdout, 1)
            close(originalStdout)
            try captureHandle.close()
            throw error
        }

        fflush(stdout)
        dup2(originalStdout, 1)
        close(originalStdout)
        try captureHandle.close()

        let data = try Data(contentsOf: tempURL)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
