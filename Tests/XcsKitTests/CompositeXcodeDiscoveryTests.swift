import Foundation
import Testing
@testable import XcsCore
@testable import XcsKit

struct CompositeXcodeDiscoveryTests {
    private func installation(_ version: String, at path: String? = nil) -> XcodeInstallation {
        XcodeInstallation(
            appPath: URL(filePath: path ?? "/Applications/Xcode_\(version).app"),
            shortVersion: version
        )
    }

    @Test
    func mergesInstallationsFromEveryMechanismInOrder() async throws {
        // Spotlight finds an install that lives off /Applications, but /Applications
        // itself is not indexed, so only the direct scan sees Xcode_27.2.app.
        let composite = CompositeXcodeDiscovery([
            FakeXcodeDiscovery.returning([installation("27.0", at: "/Volumes/Work/Xcode-27.0.app")]),
            FakeXcodeDiscovery.returning([installation("27.2")]),
        ])

        let result = try await composite.discoverInstallations()

        #expect(result.map(\.shortVersion) == ["27.0", "27.2"])
    }

    @Test
    func keepsOnlyTheFirstEntryForTheSamePath() async throws {
        let composite = CompositeXcodeDiscovery([
            FakeXcodeDiscovery.returning([
                XcodeInstallation(
                    appPath: URL(filePath: "/Applications/Xcode_27.2.app"),
                    shortVersion: "27.2",
                    licenseType: .gm
                ),
            ]),
            FakeXcodeDiscovery.returning([installation("27.2"), installation("26.6")]),
        ])

        let result = try await composite.discoverInstallations()

        #expect(result.map(\.shortVersion) == ["27.2", "26.6"])
        #expect(result.first?.licenseType == .gm)
    }

    @Test
    func treatsPathsThatDifferOnlyByTrailingSlashOrDotSegmentsAsTheSameApp() async throws {
        let composite = CompositeXcodeDiscovery([
            FakeXcodeDiscovery.returning([installation("27.2", at: "/Applications/Xcode_27.2.app/")]),
            FakeXcodeDiscovery.returning([installation("27.2", at: "/Applications/./Xcode_27.2.app")]),
        ])

        let result = try await composite.discoverInstallations()

        #expect(result.count == 1)
    }

    @Test
    func treatsASymlinkAndItsTargetAsTheSameApp() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let realApp = root.appending(path: "Xcode_27.2.app")
            try FileManager.default.createDirectory(at: realApp, withIntermediateDirectories: true)
            let link = root.appending(path: "Xcode.app")
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: realApp)

            let composite = CompositeXcodeDiscovery([
                FakeXcodeDiscovery.returning([installation("27.2", at: link.path)]),
                FakeXcodeDiscovery.returning([installation("27.2", at: realApp.path)]),
            ])

            let result = try await composite.discoverInstallations()

            #expect(result.count == 1)
            #expect(result.first?.appPath == URL(filePath: link.path))
        }
    }

    @Test
    func usesTheRemainingMechanismsWhenOneReturnsNothing() async throws {
        let composite = CompositeXcodeDiscovery([
            FakeXcodeDiscovery.returning([]),
            FakeXcodeDiscovery.returning([installation("26.6")]),
        ])

        let result = try await composite.discoverInstallations()

        #expect(result.map(\.shortVersion) == ["26.6"])
    }

    @Test
    func usesTheRemainingMechanismsWhenOneThrows() async throws {
        struct SomeError: Error {}
        let composite = CompositeXcodeDiscovery([
            FakeXcodeDiscovery.throwing(SomeError()),
            FakeXcodeDiscovery.returning([installation("26.6")]),
        ])

        let result = try await composite.discoverInstallations()

        #expect(result.map(\.shortVersion) == ["26.6"])
    }

    @Test
    func throwsWhenNoMechanismFindsAnything() async throws {
        struct SomeError: Error {}
        let composite = CompositeXcodeDiscovery([
            FakeXcodeDiscovery.returning([]),
            FakeXcodeDiscovery.throwing(SomeError()),
        ])

        await #expect(throws: XcodeDiscoveryError.noInstallationsFound) {
            try await composite.discoverInstallations()
        }
    }
}
