import Foundation
import SwiftData
import SwiftUI

/// A bookmarked verse.
@Model
final class Bookmark {
    var book: Int
    var chapter: Int
    var verse: Int
    var createdAt: Date

    init(book: Int, chapter: Int, verse: Int, createdAt: Date = .now) {
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.createdAt = createdAt
    }
}

/// A highlighted verse. Each verse has at most one highlight.
@Model
final class Highlight {
    @Attribute(.unique) var key: String
    var book: Int
    var chapter: Int
    var verse: Int
    var colorRaw: String
    var createdAt: Date

    init(book: Int, chapter: Int, verse: Int, color: HighlightColor, createdAt: Date = .now) {
        self.key = Highlight.key(book: book, chapter: chapter, verse: verse)
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.colorRaw = color.rawValue
        self.createdAt = createdAt
    }

    var color: HighlightColor {
        get { HighlightColor(rawValue: colorRaw) ?? .yellow }
        set { colorRaw = newValue.rawValue }
    }

    static func key(book: Int, chapter: Int, verse: Int) -> String {
        "\(book).\(chapter).\(verse)"
    }
}

enum HighlightColor: String, CaseIterable, Identifiable {
    case yellow, green, blue, pink, orange

    var id: String { rawValue }

    /// Solid swatch color used in pickers.
    var swatch: Color {
        switch self {
        case .yellow: Color(red: 0.98, green: 0.84, blue: 0.25)
        case .green: Color(red: 0.45, green: 0.80, blue: 0.45)
        case .blue: Color(red: 0.40, green: 0.65, blue: 0.95)
        case .pink: Color(red: 0.96, green: 0.52, blue: 0.70)
        case .orange: Color(red: 0.98, green: 0.62, blue: 0.30)
        }
    }

    /// Translucent background used behind highlighted text (works in light and dark mode).
    var background: Color { swatch.opacity(0.35) }
}
