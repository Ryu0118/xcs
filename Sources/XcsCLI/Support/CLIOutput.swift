import Foundation

/// Shared stdout/stderr formatting helpers used by every CLI command.
public enum CLIOutput {
    /// Writes an error message to stderr, prefixed with `error:`.
    public static func printError(_ message: String) {
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    }

    /// Prints an error message to stdout as a JSON object.
    public static func printJSONError(_ message: String) {
        let payload: [String: String] = ["error": message]
        printJSON(payload)
    }

    /// Encodes a value as pretty-printed, sorted-key JSON and prints it to stdout.
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
