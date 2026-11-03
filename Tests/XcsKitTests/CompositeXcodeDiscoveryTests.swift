import Foundation
import Testing
@testable import XcsCore
@testable import XcsKit

struct CompositeXcodeDiscoveryTests {
    private struct SomeError: Error {}

    private func installation(_ version: String, in directory: String = "/Applications") -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "\(directory)/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func mergesFallbackInstallationsThatThePrimaryMissed() async throws {
        // Spotlight indexes an external volume but not /Applications: mdfind returns a
        // partial, non-empty list, so the /Applications scan must still contribute.
        let composite = CompositeXcodeDiscovery(
            primary: FakeXcodeDiscovery.returning([installation("27.0", in: "/Volumes/External/Applications")]),
            fallback: FakeXcodeDiscovery.returning([installation("27.2")])
        )

        let result = try await composite.discoverInstallations()

        #expect(result.map(\.appPath.path) == [
            "/Volumes/External/Applications/Xcode_27.0.app",
            "/Applications/Xcode_27.2.app",
        ])
    }

    @Test
    func listsAnInstallationFoundByBothMechanismsOnce() async throws {
        let composite = CompositeXcodeDiscovery(
            primary: FakeXcodeDiscovery.returning([installation("27.0"), installation("26.6")]),
            fallback: FakeXcodeDiscovery.returning([installation("26.6"), installation("27.0")])
        )

        let result = try await composite.discoverInstallations()

        #expect(result.map(\.shortVersion) == ["27.0", "26.6"])
    }

    @Test
    func treatsAnEquivalentPathSpellingAsTheSameInstallation() async throws {
        let composite = CompositeXcodeDiscovery(
            primary: FakeXcodeDiscovery.returning([
                XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_27.0.app/"), shortVersion: "27.0"),
            ]),
            fallback: FakeXcodeDiscovery.returning([
                XcodeInstallation(appPath: URL(filePath: "/Applications/./Xcode_27.0.app"), shortVersion: "27.0"),
            ])
        )

        let result = try await composite.discoverInstallations()

        #expect(result.count == 1)
    }

    @Test
    func keepsThePrimaryResultWhenTheFallbackThrows() async throws {
        let composite = CompositeXcodeDiscovery(
            primary: FakeXcodeDiscovery.returning([installation("27.0")]),
            fallback: FakeXcodeDiscovery.throwing(SomeError())
        )

        let result = try await composite.discoverInstallations()

        #expect(result.map(\.shortVersion) == ["27.0"])
    }

    @Test
    func fallsBackWhenThePrimaryReturnsNothing() async throws {
        let composite = CompositeXcodeDiscovery(
            primary: FakeXcodeDiscovery.returning([]),
            fallback: FakeXcodeDiscovery.returning([installation("26.6")])
        )

        let result = try await composite.discoverInstallations()

        #expect(result.map(\.shortVersion) == ["26.6"])
    }

    @Test
    func fallsBackWhenThePrimaryThrows() async throws {
        let composite = CompositeXcodeDiscovery(
            primary: FakeXcodeDiscovery.throwing(SomeError()),
            fallback: FakeXcodeDiscovery.returning([installation("26.6")])
        )

        let result = try await composite.discoverInstallations()

        #expect(result.map(\.shortVersion) == ["26.6"])
    }

    @Test
    func throwsWhenBothMechanismsFindNothing() async throws {
        let composite = CompositeXcodeDiscovery(
            primary: FakeXcodeDiscovery.returning([]),
            fallback: FakeXcodeDiscovery.returning([])
        )

        await #expect(throws: XcodeDiscoveryError.noInstallationsFound) {
            try await composite.discoverInstallations()
        }
    }

    @Test
    func throwsWhenBothMechanismsFail() async throws {
        let composite = CompositeXcodeDiscovery(
            primary: FakeXcodeDiscovery.throwing(SomeError()),
            fallback: FakeXcodeDiscovery.throwing(SomeError())
        )

        await #expect(throws: XcodeDiscoveryError.noInstallationsFound) {
            try await composite.discoverInstallations()
        }
    }
}
