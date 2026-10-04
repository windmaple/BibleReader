import Foundation
import Observation

enum AppTab: Hashable {
    case read
    case saved
}

/// Current reading position and cross-screen navigation state. The position is persisted
/// so the app reopens where the reader left off.
@MainActor
@Observable
final class ReaderState {
    private static let bookKey = "reader.book"
    private static let chapterKey = "reader.chapter"

    var location: Location {
        didSet {
            UserDefaults.standard.set(location.book, forKey: Self.bookKey)
            UserDefaults.standard.set(location.chapter, forKey: Self.chapterKey)
        }
    }

    /// Verse the reader should scroll to once the chapter is displayed.
    var scrollTarget: Int?

    var selectedTab: AppTab = .read

    init() {
        let defaults = UserDefaults.standard
        let book = defaults.object(forKey: Self.bookKey) as? Int ?? 0
        let chapter = defaults.object(forKey: Self.chapterKey) as? Int ?? 1
        location = Location(book: book, chapter: chapter)
    }

    func go(to location: Location, verse: Int? = nil) {
        self.location = location
        scrollTarget = verse
        selectedTab = .read
    }
}
