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

    /// Reports a caught error in the format the `--json` flag selected.
    /// Shared by every command's `catch` block to avoid repeating the
    /// json/non-json branch at each call site.
    public static func reportFailure(_ error: some Swift.Error, json: Bool) {
        if json {
            printJSONError(String(describing: error))
        } else {
            printError(String(describing: error))
        }
    }
}
