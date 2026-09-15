import XcsCLI

@main
struct XcsMain {
    static func main() async throws {
        await XcsCommand.main()
    }
}
