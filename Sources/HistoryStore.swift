import Foundation

struct HistoryItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var createdAt: Date
}

enum HistoryStore {
    static let displayName = "Capture to Issue"

    static var directory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/\(displayName)", isDirectory: true)
    }

    static var fileURL: URL {
        directory.appendingPathComponent("history.json")
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func load() -> (items: [HistoryItem], error: String?) {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ([], nil)
        }
        do {
            let data = try Data(contentsOf: url)
            let items = try decoder.decode([HistoryItem].self, from: data)
            return (items, nil)
        } catch {
            return ([], error.localizedDescription)
        }
    }

    static func save(_ items: [HistoryItem]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let trimmed = Array(items.prefix(10))
        let data = try encoder.encode(trimmed)
        try data.write(to: fileURL, options: .atomic)
    }

    static func prepend(title: String, onto items: inout [HistoryItem]) throws {
        let item = HistoryItem(id: UUID(), title: title, createdAt: Date())
        items.insert(item, at: 0)
        if items.count > 10 {
            items = Array(items.prefix(10))
        }
        try save(items)
    }
}
