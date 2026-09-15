import Foundation

public enum CLIOutput {
    public static func printError(_ message: String) {
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    }

    public static func printJSONError(_ message: String) {
        let payload: [String: String] = ["error": message]
        printJSON(payload)
    }

    public static func printJSON(_ encodable: some Encodable) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(encodable), let string = String(data: data, encoding: .utf8) else {
            printError("Failed to encode JSON output.")
            return
        }
        print(string)
    }
}
