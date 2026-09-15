import AppKit
import Foundation

enum SubmitError: LocalizedError {
    case emptyTitle
    case badRepo
    case pngFailed
    case ghFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Title cannot be empty."
        case .badRepo:
            return "Enter a repo as owner/repo."
        case .pngFailed:
            return "Could not encode PNG."
        case .ghFailed(let message):
            return message
        }
    }
}

enum IssueSubmitter {
    enum GHOutcome: Sendable {
        case created(url: String)
        case unauthenticated
    }

    static func pngData(from image: NSImage) throws -> Data {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else {
            throw SubmitError.pngFailed
        }
        return png
    }

    static func writeTempPNG(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("capture-\(UUID().uuidString).png")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func markdown(title: String, body: String) -> String {
        "# \(title)\n\n\(body)"
    }

    static func copyMarkdownOnly(title: String, body: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(markdown(title: title, body: body), forType: .string)
    }

    static func putPNGOnPasteboard(_ data: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
    }

    static func putMarkdownOnPasteboard(title: String, body: String) {
        NSPasteboard.general.setString(markdown(title: title, body: body), forType: .string)
    }

    static func validate(title: String, repo: String) throws -> (title: String, repo: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRepo = repo.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            throw SubmitError.emptyTitle
        }
        if trimmedRepo.split(separator: "/").filter({ !$0.isEmpty }).count != 2 {
            throw SubmitError.badRepo
        }
        return (trimmedTitle, trimmedRepo)
    }

    nonisolated static func createIssue(title: String, body: String, repo: String) throws -> GHOutcome {
        let auth = try runGH(["auth", "status"])
        if auth.exitCode != 0 {
            return .unauthenticated
        }
        let issueBody = body + "\n\n_Image on clipboard_"
        let created = try runGH([
            "issue", "create",
            "--repo", repo,
            "--title", title,
            "--body", issueBody
        ])
        if created.exitCode != 0 {
            let message = created.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            let fallback = created.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            throw SubmitError.ghFailed(message.isEmpty ? (fallback.isEmpty ? "gh issue create failed." : fallback) : message)
        }
        let url = created.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return .created(url: url)
    }

    private struct ProcessResult: Sendable {
        var exitCode: Int32
        var stdout: String
        var stderr: String
    }

    nonisolated private static func runGH(_ arguments: [String]) throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gh"] + arguments
        var environment = ProcessInfo.processInfo.environment
        let existing = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + existing
        process.environment = environment
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.standardInput = FileHandle.nullDevice
        try process.run()
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: String(data: outData, encoding: .utf8) ?? "",
            stderr: String(data: errData, encoding: .utf8) ?? ""
        )
    }
}
