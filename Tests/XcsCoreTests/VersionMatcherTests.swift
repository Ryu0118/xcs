import Foundation
import Testing
@testable import XcsCore

struct VersionMatcherTests {
    private func installation(
        _ version: String,
        licenseType: XcodeInstallation.LicenseType? = nil
    ) -> XcodeInstallation {
        XcodeInstallation(
            appPath: URL(filePath: "/Applications/Xcode_\(version).app"),
            shortVersion: version,
            licenseType: licenseType
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
                .ambiguous(
                    spec: "27",
                    candidates: [
                        "27.0 (/Applications/Xcode_27.0.app)",
                        "27.1 (/Applications/Xcode_27.1.app)",
                    ]
                )
            )
        )
    }

    @Test
    func ambiguousCandidatesIncludeLicenseTypeWhenAvailable() {
        let installations = [
            installation("27.0", licenseType: .gm),
            installation("27.1", licenseType: .beta),
        ]
        let result = VersionMatcher.resolve(
            spec: VersionSpec(rawValue: "27"),
            installations: installations
        )
        #expect(
            result == .failure(
                .ambiguous(
                    spec: "27",
                    candidates: [
                        "27.0 (/Applications/Xcode_27.0.app) [GM]",
                        "27.1 (/Applications/Xcode_27.1.app) [Beta]",
                    ]
                )
            )
        )
    }

    @Test
    func ambiguousCandidatesShareIdenticalShortVersionButDifferentPaths() {
        // Regression: a beta seed and a GM build reporting the same shortVersion
        // ("27.0") used to render as an unactionable "27.0, 27.0" candidate list.
        let gm = XcodeInstallation(
            appPath: URL(filePath: "/Applications/Xcode_27.app"),
            shortVersion: "27.0",
            licenseType: .gm
        )
        let beta = XcodeInstallation(
            appPath: URL(filePath: "/Applications/Xcode-27.0.0-Beta.app"),
            shortVersion: "27.0",
            licenseType: .beta
        )
        let result = VersionMatcher.resolve(
            spec: VersionSpec(rawValue: "27"),
            installations: [gm, beta]
        )
        #expect(
            result == .failure(
                .ambiguous(
                    spec: "27",
                    candidates: [
                        "27.0 (/Applications/Xcode_27.app) [GM]",
                        "27.0 (/Applications/Xcode-27.0.0-Beta.app) [Beta]",
                    ]
                )
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
                .noMatch(
                    spec: "28",
                    available: [
                        "26.6 (/Applications/Xcode_26.6.app)",
                        "27.0 (/Applications/Xcode_27.0.app)",
                    ]
                )
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
