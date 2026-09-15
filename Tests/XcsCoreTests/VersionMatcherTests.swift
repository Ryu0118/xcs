import Foundation
import Testing
@testable import XcsCore

struct VersionMatcherTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(
            appPath: URL(filePath: "/Applications/Xcode_\(version).app"),
            shortVersion: version
        )
    }

    @Test
    func exactMatchWinsOverPrefixCandidates() {
        let installations = [installation("27.0"), installation("27.0.1")]
        let result = VersionMatcher.resolve(
            spec: VersionSpec(rawValue: "27.0"),
            installations: installations
        )
        #expect(result == .success(installations[0]))
    }

    @Test
    func singlePrefixMatchResolves() {
        let installations = [installation("26.6"), installation("27.0")]
        let result = VersionMatcher.resolve(
            spec: VersionSpec(rawValue: "26"),
            installations: installations
        )
        #expect(result == .success(installations[0]))
    }

    @Test
    func multiplePrefixMatchesAreAmbiguous() {
        let installations = [installation("27.0"), installation("27.1")]
        let result = VersionMatcher.resolve(
            spec: VersionSpec(rawValue: "27"),
            installations: installations
        )
        #expect(
            result == .failure(
                .ambiguous(spec: "27", candidates: ["27.0", "27.1"])
            )
        )
    }

    @Test
    func noMatchListsAvailableVersions() {
        let installations = [installation("26.6"), installation("27.0")]
        let result = VersionMatcher.resolve(
            spec: VersionSpec(rawValue: "28"),
            installations: installations
        )
        #expect(
            result == .failure(
                .noMatch(spec: "28", available: ["26.6", "27.0"])
            )
        )
    }

    @Test
    func emptyInstallationsYieldsNoMatch() {
        let result = VersionMatcher.resolve(
            spec: VersionSpec(rawValue: "27.0"),
            installations: []
        )
        #expect(result == .failure(.noMatch(spec: "27.0", available: [])))
    }
}
