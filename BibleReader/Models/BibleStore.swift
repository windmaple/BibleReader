import Foundation
import Observation

enum Testament: String, CaseIterable, Identifiable {
    case old = "Old Testament"
    case new = "New Testament"

    var id: String { rawValue }
}

/// A single book of the Bible. `chapters[c][v]` holds the text of chapter `c + 1`, verse `v + 1`.
struct Book: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let abbrev: String
    let chapters: [[String]]

    var testament: Testament { id < 39 ? .old : .new }
    var chapterCount: Int { chapters.count }

    static func == (lhs: Book, rhs: Book) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A position in the Bible (1-based chapter and verse).
struct Location: Hashable, Sendable {
    var book: Int
    var chapter: Int
}

/// Loads and serves the bundled King James Version text.
@MainActor
@Observable
final class BibleStore {
    private(set) var books: [Book] = []
    private(set) var loadError: String?

    var isLoaded: Bool { !books.isEmpty }

    func load() async {
        guard books.isEmpty else { return }
        do {
            books = try await Task.detached(priority: .userInitiated) {
                try BibleStore.decodeBundledText()
            }.value
        } catch {
            loadError = error.localizedDescription
        }
    }

    private struct RawBook: Decodable {
        let name: String
        let abbrev: String
        let chapters: [[String]]
    }

    nonisolated private static func decodeBundledText() throws -> [Book] {
        guard let url = Bundle.main.url(forResource: "kjv", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let raw = try JSONDecoder().decode([RawBook].self, from: Data(contentsOf: url))
        return raw.enumerated().map { index, book in
            Book(id: index, name: book.name, abbrev: book.abbrev, chapters: book.chapters)
        }
    }

    // MARK: - Lookup

    func verses(book: Int, chapter: Int) -> [String] {
        guard books.indices.contains(book),
              books[book].chapters.indices.contains(chapter - 1) else { return [] }
        return books[book].chapters[chapter - 1]
    }

    func text(book: Int, chapter: Int, verse: Int) -> String {
        let verses = verses(book: book, chapter: chapter)
        return verses.indices.contains(verse - 1) ? verses[verse - 1] : ""
    }

    func clamp(_ location: Location) -> Location {
        guard isLoaded else { return location }
        let book = min(max(location.book, 0), books.count - 1)
        let chapter = min(max(location.chapter, 1), books[book].chapterCount)
        return Location(book: book, chapter: chapter)
    }

    // MARK: - Chapter navigation

    func location(before location: Location) -> Location? {
        if location.chapter > 1 {
            return Location(book: location.book, chapter: location.chapter - 1)
        }
        guard location.book > 0 else { return nil }
        let previous = location.book - 1
        return Location(book: previous, chapter: books[previous].chapterCount)
    }

    func location(after location: Location) -> Location? {
        guard books.indices.contains(location.book) else { return nil }
        if location.chapter < books[location.book].chapterCount {
            return Location(book: location.book, chapter: location.chapter + 1)
        }
        guard location.book + 1 < books.count else { return nil }
        return Location(book: location.book + 1, chapter: 1)
    }

    // MARK: - Formatting

    /// e.g. "John 3:16" or "Genesis 1:1-3, 5".
    func reference(book: Int, chapter: Int, verses: [Int]) -> String {
        guard books.indices.contains(book) else { return "" }
        let base = "\(books[book].name) \(chapter)"
        let ranges = Self.compactRanges(verses)
        return ranges.isEmpty ? base : "\(base):\(ranges)"
    }

    /// Text suitable for copying or sharing, with a trailing reference line.
    func shareText(book: Int, chapter: Int, verses: [Int]) -> String {
        let sorted = verses.sorted()
        let body: String
        if sorted.count == 1 {
            body = text(book: book, chapter: chapter, verse: sorted[0])
        } else {
            body = sorted
                .map { "\($0) \(text(book: book, chapter: chapter, verse: $0))" }
                .joined(separator: " ")
        }
        return "\(body)\n— \(reference(book: book, chapter: chapter, verses: sorted)) (KJV)"
    }

    static func compactRanges(_ verses: [Int]) -> String {
        let sorted = Array(Set(verses)).sorted()
        var parts: [String] = []
        var index = 0
        while index < sorted.count {
            let start = sorted[index]
            var end = start
            while index + 1 < sorted.count, sorted[index + 1] == end + 1 {
                index += 1
                end = sorted[index]
            }
            parts.append(start == end ? "\(start)" : "\(start)-\(end)")
            index += 1
        }
        return parts.joined(separator: ", ")
    }
}
