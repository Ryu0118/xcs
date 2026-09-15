import ArgumentParser
import Foundation
import XcsKit

public struct DoctorCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Diagnose .xcodeversions.yml discovery and Xcode installation resolvability."
    )

    public init() {}

    public mutating func run() async throws {
        let workingDirectory = CLIEnvironment.currentDirectory()
        let discovery = CLIEnvironment.makeDiscovery()
        let runner = DoctorRunner(
            fileManager: FileManager.default,
            discovery: discovery,
            workingDirectory: workingDirectory
        )

        let report = try await runner.run()

        if let config = report.configurationFound {
            print("✅ configuration: \(config.path)")
        } else {
            print("⚠️  configuration: no .xcodeversions.yml found in \(workingDirectory.path) or any ancestor")
        }

        if report.discoveredInstallations.isEmpty {
            print("⚠️  installations: none discovered")
        } else {
            print("✅ installations: \(report.discoveredInstallations.map(\.shortVersion).joined(separator: ", "))")
        }

        for (key, result) in report.entryResolutions.sorted(by: { $0.key < $1.key }) {
            switch result {
            case let .ok(version):
                print("✅ \(key): resolves to \(version)")
            case let .error(message):
                print("❌ \(key): \(message)")
            }
        }
    }
}
