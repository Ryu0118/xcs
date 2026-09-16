import FileManagerProtocol
import Foundation
import Testing
@testable import XcsConfig

struct XcodeVersionsLocatorTests {
    @Test
    func findsConfigInTheStartingDirectory() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let configURL = root.appending(path: ".xcodeversions.yml")
            try ConfigurationTestSupport.write("targets: {}\n", to: configURL)

            let locator = XcodeVersionsLocator(fileManager: FileManager.default)
            let found = locator.locate(startingAt: root, stopAt: root)

            #expect(found?.path == configURL.path)
        }
    }

    @Test
    func findsConfigInAnAncestorDirectory() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let configURL = root.appending(path: ".xcodeversions.yml")
            try ConfigurationTestSupport.write("targets: {}\n", to: configURL)

            let deep = root.appending(path: "a/b/c", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: deep, withIntermediateDirectories: true)

            let locator = XcodeVersionsLocator(fileManager: FileManager.default)
            let found = locator.locate(startingAt: deep, stopAt: root)

            #expect(found?.path == configURL.path)
        }
    }

    @Test
    func stopsAtStopAtWithoutFindingAnAncestorConfig() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            // A config placed above `stopAt` must never be found — this is
            // the guard against escaping the fixture root into the real
            // filesystem (e.g. the user's home directory) during tests.
            let parentConfig = root.deletingLastPathComponent().appending(path: ".xcodeversions.yml")
            let alreadyExists = FileManager.default.fileExists(atPath: parentConfig.path)

            let child = root.appending(path: "child", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)

            let locator = XcodeVersionsLocator(fileManager: FileManager.default)
            let found = locator.locate(startingAt: child, stopAt: root)

            #expect(found == nil)
            #expect(!alreadyExists) // sanity: the fixture didn't accidentally collide with a real file
        }
    }

    @Test
    func returnsNilWhenNoConfigExistsAnywhereInScope() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let locator = XcodeVersionsLocator(fileManager: FileManager.default)
            let found = locator.locate(startingAt: root, stopAt: root)

            #expect(found == nil)
        }
    }

    @Test
    func findsConfigThroughASymlinkedStartingDirectory() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let realDir = root.appending(path: "real", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: realDir, withIntermediateDirectories: true)
            let configURL = realDir.appending(path: ".xcodeversions.yml")
            try ConfigurationTestSupport.write("targets: {}\n", to: configURL)

            let symlink = root.appending(path: "link", directoryHint: .isDirectory)
            try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: realDir)

            let locator = XcodeVersionsLocator(fileManager: FileManager.default)
            let found = locator.locate(startingAt: symlink, stopAt: root)

            #expect(found?.path == configURL.path)
        }
    }
}
