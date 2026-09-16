import Foundation
import Testing
@testable import XcsCore
@testable import XcsKit

struct CompositeXcodeDiscoveryTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func returnsThePrimaryResultWhenNonEmpty() async throws {
        let composite = CompositeXcodeDiscovery(
            primary: FakeXcodeDiscovery.returning([installation("27.0")]),
            fallback: FakeXcodeDiscovery.returning([installation("26.6")])
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
        struct SomeError: Error {}
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
}
