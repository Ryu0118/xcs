import ArgumentParser
import Testing
@testable import XcsCLI

struct XcsCommandTests {
    @Test
    func bareTargetArgumentParsesAsOpenViaTheDefaultSubcommand() throws {
        let parsed = try XcsCommand.parseAsRoot(["App.xcworkspace"])

        let open = try #require(parsed as? OpenCommand)
        #expect(open.target == "App.xcworkspace")
    }

    @Test
    func explicitOpenSubcommandParsesTheSameWay() throws {
        let parsed = try XcsCommand.parseAsRoot(["open", "App.xcworkspace"])

        let open = try #require(parsed as? OpenCommand)
        #expect(open.target == "App.xcworkspace")
    }
}
