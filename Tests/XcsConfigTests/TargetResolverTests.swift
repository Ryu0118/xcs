import Foundation
import Testing
@testable import XcsConfig
@testable import XcsCore

struct TargetResolverTests {
    private let configDirectory = URL(filePath: "/tmp/xcs-fixture")

    @Test
    func exactRelativePathMatchWins() {
        let document = XcodeVersionsDocument(targets: [
            "App.xcworkspace": "27.0",
            "b.xcworkspace": "26.6",
        ])
        let target = configDirectory.appending(path: "App.xcworkspace")

        let result = TargetResolver().resolve(target: target, relativeTo: configDirectory, in: document)

        #expect(result == .success(VersionSpec(rawValue: "27.0")))
    }

    @Test
    func suffixMatchIsUsedWhenNoExactKeyExists() {
        let document = XcodeVersionsDocument(targets: ["b.xcworkspace": "26.6"])
        let target = configDirectory.appending(path: "Nested/Deep/b.xcworkspace")

        let result = TargetResolver().resolve(target: target, relativeTo: configDirectory, in: document)

        #expect(result == .success(VersionSpec(rawValue: "26.6")))
    }

    @Test
    func globMatchCrossesDirectoryBoundaries() {
        let document = XcodeVersionsDocument(targets: ["Modules/**/*.xcodeproj": "26.3"])
        let target = configDirectory.appending(path: "Modules/Deep/Nested/Tools.xcodeproj")

        let result = TargetResolver().resolve(target: target, relativeTo: configDirectory, in: document)

        #expect(result == .success(VersionSpec(rawValue: "26.3")))
    }

    @Test
    func ambiguousExactTierDoesNotFallThroughToOtherTiers() {
        // Two keys can't both be an exact match to the same relative path,
        // but this documents that ambiguity is detected within a tier and
        // does not silently fall through to a lower-precedence tier.
        let document = XcodeVersionsDocument(targets: [
            "b.xcworkspace": "26.6",
            "Deep/b.xcworkspace": "26.3",
        ])
        let target = configDirectory.appending(path: "Nested/Deep/b.xcworkspace")

        let result = TargetResolver().resolve(target: target, relativeTo: configDirectory, in: document)

        guard case let .failure(.ambiguousMatch(_, matchingKeys)) = result else {
            Issue.record("expected ambiguousMatch, got \(result)")
            return
        }
        #expect(matchingKeys == ["Deep/b.xcworkspace", "b.xcworkspace"])
    }

    @Test
    func exactTierMatchIsNeverCountedAsASuffixCandidateToo() {
        // Regression guard: a key equal to the resolved relative path must
        // not additionally appear as a suffix match, which would otherwise
        // produce a spurious ambiguity once combined with another suffix key.
        let document = XcodeVersionsDocument(targets: [
            "App.xcworkspace": "27.0",
            "Other/App.xcworkspace": "26.6",
        ])
        let target = configDirectory.appending(path: "App.xcworkspace")

        let result = TargetResolver().resolve(target: target, relativeTo: configDirectory, in: document)

        #expect(result == .success(VersionSpec(rawValue: "27.0")))
    }

    @Test
    func noMatchWhenNoTierHasAnyKey() {
        let document = XcodeVersionsDocument(targets: ["b.xcworkspace": "26.6"])
        let target = configDirectory.appending(path: "Unrelated.xcworkspace")

        let result = TargetResolver().resolve(target: target, relativeTo: configDirectory, in: document)

        #expect(result == .failure(.noMatch(target: "Unrelated.xcworkspace")))
    }
}
