import Foundation
import Interaction
import XcsCore
import XcsKit

/// Returns a canned list of installations, or throws a canned error.
struct FakeXcodeDiscovery: XcodeDiscovery {
    enum Result: Sendable {
        case installations([XcodeInstallation])
        case failure(any Error)
    }

    let result: Result

    static func returning(_ installations: [XcodeInstallation]) -> FakeXcodeDiscovery {
        FakeXcodeDiscovery(result: .installations(installations))
    }

    func discoverInstallations() async throws -> [XcodeInstallation] {
        switch result {
        case let .installations(installations): installations
        case let .failure(error): throw error
        }
    }
}

/// Records every `launch` call instead of exec'ing anything.
final class FakeXcodeLauncher: XcodeLauncher, @unchecked Sendable {
    private(set) var launchedCalls: [(installation: XcodeInstallation, filePath: URL)] = []

    func launch(installation: XcodeInstallation, filePath: URL) throws {
        launchedCalls.append((installation, filePath))
    }
}

/// Fails the test if `choose` is ever invoked.
struct GuardedInteraction: InteractionProviding {
    func write(_: StyledText) {}
    func writeStatus(_: Status, _: StyledText) {}
    func writeTable(_: Table) {}
    func readText(_: TextPrompt) async -> String {
        preconditionFailure("GuardedInteraction.readText was called without a configured answer.")
    }

    func confirm(_: ConfirmationPrompt) -> Bool {
        preconditionFailure("GuardedInteraction.confirm was called without a configured answer.")
    }

    func choose<Option>(_: ChoicePrompt<Option>) -> Option {
        preconditionFailure("GuardedInteraction.choose was called without a configured answer.")
    }

    func chooseMany<Option>(_: MultipleChoicePrompt<Option>) -> [Option] {
        preconditionFailure("GuardedInteraction.chooseMany was called without a configured answer.")
    }
}

/// Reports every installation as not running unless configured otherwise.
struct FakeRunningXcodeChecker: RunningXcodeChecker {
    var runningAppPaths: Set<URL> = []

    func isRunning(installation: XcodeInstallation) -> Bool {
        runningAppPaths.contains(installation.appPath)
    }
}

/// Records the command/environment passed to `exec`, then throws instead of
/// replacing the process image.
final class FakeExecer: Execer, @unchecked Sendable {
    struct Invoked: Error, Equatable {
        let command: [String]
        let developerDirectory: String
    }

    private(set) var lastCommand: [String]?
    private(set) var lastDeveloperDirectory: String?

    func exec(command: [String], developerDirectory: String) throws -> Never {
        lastCommand = command
        lastDeveloperDirectory = developerDirectory
        throw Invoked(command: command, developerDirectory: developerDirectory)
    }
}

enum ConfigurationTestSupport {
    static func withDirectory(_ body: (URL) async throws -> Void) async throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "xcs-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try await body(root)
    }

    static func write(_ source: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try source.write(to: url, atomically: true, encoding: .utf8)
    }
}
