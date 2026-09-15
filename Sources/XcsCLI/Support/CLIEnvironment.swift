import FileManagerProtocol
import Foundation
import XcsKit

enum CLIEnvironment {
    static func currentDirectory(fileManager: any FileManagerProtocol = FileManager.default) -> URL {
        URL(fileURLWithPath: fileManager.currentDirectoryPath)
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
}
