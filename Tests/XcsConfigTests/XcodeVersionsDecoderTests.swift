import FileManagerProtocol
import Foundation
import Testing
@testable import XcsConfig

struct XcodeVersionsDecoderTests {
    @Test
    func decodesAValidDocument() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let configURL = root.appending(path: ".xcodeversions.yml")
            try ConfigurationTestSupport.write(
                """
                targets:
                  App.xcworkspace: "27.0"
                  Tools.xcodeproj: "26.6"
                """,
                to: configURL
            )

            let decoder = XcodeVersionsDecoder(fileManager: FileManager.default)
            let document = try decoder.decode(configURL)

            #expect(document.targets == ["App.xcworkspace": "27.0", "Tools.xcodeproj": "26.6"])
        }
    }

    @Test
    func throwsInvalidYAMLForMalformedContent() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let configURL = root.appending(path: ".xcodeversions.yml")
            try ConfigurationTestSupport.write("targets: [this, is, not, a, mapping]", to: configURL)

            let decoder = XcodeVersionsDecoder(fileManager: FileManager.default)

            #expect(throws: XcodeVersionsLoadingError.invalidYAML(configURL)) {
                try decoder.decode(configURL)
            }
        }
    }

    @Test
    func throwsUnreadableForAMissingFile() async throws {
        try await ConfigurationTestSupport.withDirectory { root in
            let configURL = root.appending(path: "does-not-exist.yml")
            let decoder = XcodeVersionsDecoder(fileManager: FileManager.default)

            #expect(throws: XcodeVersionsLoadingError.configurationFileUnreadable(configURL)) {
                try decoder.decode(configURL)
            }
        }
    }
}
