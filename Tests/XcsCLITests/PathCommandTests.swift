import ArgumentParser
import Foundation
import Testing
@testable import XcsCLI
@testable import XcsCore
@testable import XcsKit

struct PathCommandTests {
    private func installation(_ version: String) -> XcodeInstallation {
        XcodeInstallation(appPath: URL(filePath: "/Applications/Xcode_\(version).app"), shortVersion: version)
    }

    @Test
    func printsTheAppPathByDefault() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            try ConfigurationTestSupport.write(
                "targets:\n  App.xcworkspace: \"27.0\"\n",
                to: root.appending(path: ".xcodeversions.yml")
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "App.xcworkspace"), withIntermediateDirectories: true
            )

            let output = try await OutputCapture.capture {
                try await PathCommand.execute(
                    target: nil,
                    xcode: nil,
                    xcodePath: nil,
                    developerDir: false,
                    json: false,
                    candidateDiscovery: CandidateDiscovery(
                        fileManager: FileManager.default,
                        discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                        workingDirectory: root,
                        stopAt: root
                    )
                )
            }

            #expect(output.trimmingCharacters(in: .whitespacesAndNewlines) == "/Applications/Xcode_27.0.app")
        }
    }

    @Test
    func printsTheDeveloperDirWithFlag() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            try ConfigurationTestSupport.write(
                "targets:\n  App.xcworkspace: \"27.0\"\n",
                to: root.appending(path: ".xcodeversions.yml")
            )
            try FileManager.default.createDirectory(
                at: root.appending(path: "App.xcworkspace"), withIntermediateDirectories: true
            )

            let output = try await OutputCapture.capture {
                try await PathCommand.execute(
                    target: nil,
                    xcode: nil,
                    xcodePath: nil,
                    developerDir: true,
                    json: false,
                    candidateDiscovery: CandidateDiscovery(
                        fileManager: FileManager.default,
                        discovery: FakeXcodeDiscovery.returning([installation("27.0")]),
                        workingDirectory: root,
                        stopAt: root
                    )
                )
            }

            #expect(output.trimmingCharacters(in: .whitespacesAndNewlines) == "/Applications/Xcode_27.0.app/Contents/Developer")
        }
    }

    @Test
    func xcodeOverrideBypassesTheConfigFile() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            try FileManager.default.createDirectory(
                at: root.appending(path: "App.xcworkspace"), withIntermediateDirectories: true
            )

            let output = try await OutputCapture.capture {
                try await PathCommand.execute(
                    target: "App.xcworkspace",
                    xcode: "26.6",
                    xcodePath: nil,
                    developerDir: false,
                    json: false,
                    candidateDiscovery: CandidateDiscovery(
                        fileManager: FileManager.default,
                        discovery: FakeXcodeDiscovery.returning([installation("27.0"), installation("26.6")]),
                        workingDirectory: root,
                        stopAt: root
                    )
                )
            }

            #expect(output.trimmingCharacters(in: .whitespacesAndNewlines) == "/Applications/Xcode_26.6.app")
        }
    }
}
