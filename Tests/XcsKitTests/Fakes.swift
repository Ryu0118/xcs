import Foundation
import Interaction
import XcsCore
import XcsKit

/// Returns a canned list of installations, or throws a canned error.
/// Unused unless configured — never touches mdfind or the filesystem.
struct FakeXcodeDiscovery: XcodeDiscovery {
    enum Result: Sendable {
        case installations([XcodeInstallation])
        case failure(any Error)
    }

    let result: Result

    static func returning(_ installations: [XcodeInstallation]) -> FakeXcodeDiscovery {
        FakeXcodeDiscovery(result: .installations(installations))
    }

    static func throwing(_ error: any Error) -> FakeXcodeDiscovery {
        FakeXcodeDiscovery(result: .failure(error))
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

/// Fails the test if `choose` is ever invoked — used to assert that a
/// single-candidate resolution never touches the interactive picker.
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

/// Returns a fixed option from `choose`, for exercising the interactive-picker branch.
struct FixedChoiceInteraction: InteractionProviding {
    let chosenIndex: Int

    func write(_: StyledText) {}
    func writeStatus(_: Status, _: StyledText) {}
    func writeTable(_: Table) {}
    func readText(_: TextPrompt) async -> String {
        preconditionFailure("FixedChoiceInteraction.readText was called without a configured answer.")
    }

    func confirm(_: ConfirmationPrompt) -> Bool {
        preconditionFailure("FixedChoiceInteraction.confirm was called without a configured answer.")
    }

    func choose<Option>(_ prompt: ChoicePrompt<Option>) -> Option {
        prompt.options[chosenIndex]
    }

    func chooseMany<Option>(_: MultipleChoicePrompt<Option>) -> [Option] {
        preconditionFailure("FixedChoiceInteraction.chooseMany was called without a configured answer.")
    }
}

/// Records the command/environment passed to `exec`, then throws instead of
/// replacing the process image — `exec`'s `Never` return type means a fake
/// can't "succeed" and return, so tests observe the recorded call by
/// catching this marker error.
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

/// Reports every installation as not running unless configured otherwise.
struct FakeRunningXcodeChecker: RunningXcodeChecker {
    var runningAppPaths: Set<URL> = []

    func isRunning(installation: XcodeInstallation) -> Bool {
        runningAppPaths.contains(installation.appPath)
    }
}
