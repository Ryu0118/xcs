import FileManagerProtocol
import Foundation
import XcsKit

enum CLIEnvironment {
    static func currentDirectory(fileManager: any FileManagerProtocol = FileManager.default) -> URL {
        URL(filePath: fileManager.currentDirectoryPath)
    }

    static func makeDiscovery() -> any XcodeDiscovery {
        CompositeXcodeDiscovery(
            primary: MDFindXcodeDiscovery(),
            fallback: ApplicationsGlobXcodeDiscovery(fileManager: FileManager.default)
        )
    }

    static func makeCandidateDiscovery(
        workingDirectory: URL,
        discovery: any XcodeDiscovery
    ) -> CandidateDiscovery {
        CandidateDiscovery(
            fileManager: FileManager.default,
            discovery: discovery,
            workingDirectory: workingDirectory
        )
    }

    /// Builds the one-off `--xcode`/`--xcode-path` override shared by every
    /// command that resolves a target. `--xcode-path` wins if both are given.
    static func makeVersionOverride(xcode: String?, xcodePath: String?) -> VersionOverride? {
        if let xcodePath {
            return .appPath(URL(filePath: xcodePath))
        }
        if let xcode {
            return .version(xcode)
        }
        return nil
    }
}
