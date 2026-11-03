import Foundation
import Testing
@testable import XcsCore
@testable import XcsKit

struct ApplicationsGlobXcodeDiscoveryTests {
    private func makeApp(
        named name: String,
        in directory: URL,
        bundleIdentifier: String? = "com.apple.dt.Xcode",
        version: String? = "27.2"
    ) throws -> URL {
        let app = directory.appending(path: name)
        var plist: [String: Any] = [:]
        if let bundleIdentifier { plist["CFBundleIdentifier"] = bundleIdentifier }
        if let version { plist["CFBundleShortVersionString"] = version }
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try FileManager.default.createDirectory(
            at: app.appending(path: "Contents"),
            withIntermediateDirectories: true
        )
        try data.write(to: app.appending(path: "Contents/Info.plist"))
        return app
    }

    private func discover(in directory: URL) async throws -> [XcodeInstallation] {
        try await ApplicationsGlobXcodeDiscovery(
            fileManager: FileManager.default,
            applicationsDirectory: directory
        ).discoverInstallations()
    }

    @Test
    func findsAnXcodeBundleDirectlyUnderTheDirectory() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let app = try makeApp(named: "Xcode_27.2.app", in: root)

            let result = try await discover(in: root)

            #expect(result.map(\.shortVersion) == ["27.2"])
            #expect(result.map(\.appPath) == [app])
        }
    }

    @Test
    func ignoresAnXcodeNamedAppWhoseBundleIdentifierIsNotXcode() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            _ = try makeApp(named: "XcodesApp.app", in: root, bundleIdentifier: "com.robotsandpencils.XcodesApp")
            _ = try makeApp(named: "Xcode_27.2.app", in: root)

            let result = try await discover(in: root)

            #expect(result.map(\.appPath.lastPathComponent) == ["Xcode_27.2.app"])
        }
    }

    @Test
    func ignoresAppsWhoseNameDoesNotStartWithXcode() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            _ = try makeApp(named: "Simulator.app", in: root)

            let result = try await discover(in: root)

            #expect(result.isEmpty)
        }
    }

    @Test
    func skipsABundleWithAnUnreadableInfoPlistWithoutThrowing() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let broken = root.appending(path: "Xcode-broken.app/Contents")
            try FileManager.default.createDirectory(at: broken, withIntermediateDirectories: true)
            try Data("not a plist".utf8).write(to: broken.appending(path: "Info.plist"))
            _ = try makeApp(named: "Xcode_27.2.app", in: root)

            let result = try await discover(in: root)

            #expect(result.map(\.appPath.lastPathComponent) == ["Xcode_27.2.app"])
        }
    }

    @Test
    func skipsABundleWithoutAVersion() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            _ = try makeApp(named: "Xcode-noversion.app", in: root, version: nil)

            let result = try await discover(in: root)

            #expect(result.isEmpty)
        }
    }

    @Test
    func doesNotDescendIntoSubdirectories() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let nested = root.appending(path: "Xcodes")
            try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
            _ = try makeApp(named: "Xcode_26.6.app", in: nested)

            let result = try await discover(in: root)

            #expect(result.isEmpty)
        }
    }

    @Test
    func returnsNothingForAMissingDirectory() async throws {
        let missing = FileManager.default.temporaryDirectory.appending(path: "xcs-missing-\(UUID().uuidString)")

        let result = try await discover(in: missing)

        #expect(result.isEmpty)
    }
}
