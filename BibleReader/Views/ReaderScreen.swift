import SwiftData
import SwiftUI

/// The main reading screen: a chapter of text with a book/chapter picker in the title.
struct ReaderScreen: View {
    @Environment(BibleStore.self) private var bible
    @Environment(ReaderState.self) private var reader
    @State private var showingPicker = false

    var body: some View {
        let location = bible.clamp(reader.location)
        let book = bible.books[location.book]

        NavigationStack {
            ChapterView(book: book, chapter: location.chapter)
                .id(location)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Button {
                            showingPicker = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("\(book.name) \(location.chapter)")
                                    .font(.headline)
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.primary)
                        }
                        .accessibilityHint("Choose a book and chapter")
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if let previous = bible.location(before: location) { go(to: previous) }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(bible.location(before: location) == nil)
                        .accessibilityLabel("Previous chapter")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if let next = bible.location(after: location) { go(to: next) }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(bible.location(after: location) == nil)
                        .accessibilityLabel("Next chapter")
                    }
                }
                .sheet(isPresented: $showingPicker) {
                    BookPickerView()
                }
        }
    }

    private func go(to location: Location) {
        withAnimation(.easeInOut(duration: 0.2)) {
            reader.go(to: location)
        }
    }
}

/// Displays one chapter, with verse selection, highlighting, and bookmarking.
struct ChapterView: View {
    let book: Book
    let chapter: Int

    @Environment(BibleStore.self) private var bible
    @Environment(ReaderState.self) private var reader
    @Environment(\.modelContext) private var modelContext

    @Query private var highlights: [Highlight]
    @Query private var bookmarks: [Bookmark]

    @State private var selection: Set<Int> = []

    init(book: Book, chapter: Int) {
        self.book = book
        self.chapter = chapter
        let bookID = book.id
        _highlights = Query(filter: #Predicate<Highlight> { $0.book == bookID && $0.chapter == chapter })
        _bookmarks = Query(filter: #Predicate<Bookmark> { $0.book == bookID && $0.chapter == chapter })
    }

    private var location: Location { Location(book: book.id, chapter: chapter) }
    private var verses: [String] { book.chapters[chapter - 1] }

    var body: some View {
        let highlightByVerse = Dictionary(highlights.map { ($0.verse, $0.color) }, uniquingKeysWith: { first, _ in first })
        let bookmarkedVerses = Set(bookmarks.map(\.verse))

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    header

                    ForEach(Array(verses.enumerated()), id: \.offset) { index, text in
                        let number = index + 1
                        VerseRow(
                            number: number,
                            text: text,
                            highlight: highlightByVerse[number],
                            isBookmarked: bookmarkedVerses.contains(number),
                            isSelected: selection.contains(number)
                        )
                        .id(number)
                        .onTapGesture { toggleSelection(number) }
                    }

                    footer
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .simultaneousGesture(swipeToChangeChapter)
            .task { await scrollToTarget(using: proxy) }
            .onChange(of: reader.scrollTarget) {
                Task { await scrollToTarget(using: proxy) }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !selection.isEmpty {
                SelectionActionBar(
                    reference: bible.reference(book: book.id, chapter: chapter, verses: Array(selection)),
                    shareText: bible.shareText(book: book.id, chapter: chapter, verses: Array(selection)),
                    allBookmarked: selection.isSubset(of: bookmarkedVerses),
                    onHighlight: applyHighlight,
                    onToggleBookmark: { toggleBookmarks(currentlyAllBookmarked: selection.isSubset(of: bookmarkedVerses)) },
                    onDismiss: { selection.removeAll() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.25), value: selection.isEmpty)
        .sensoryFeedback(.selection, trigger: selection)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.name.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(.tint)
            Text("Chapter \(chapter)")
                .font(.system(.largeTitle, design: .serif, weight: .bold))
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var footer: some View {
        HStack {
            if let previous = bible.location(before: location) {
                Button {
                    navigate(to: previous)
                } label: {
                    Label("\(bible.books[previous.book].abbrev) \(previous.chapter)", systemImage: "chevron.left")
                }
            }
            Spacer()
            if let next = bible.location(after: location) {
                Button {
                    navigate(to: next)
                } label: {
                    HStack(spacing: 6) {
                        Text("\(bible.books[next.book].abbrev) \(next.chapter)")
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
        .buttonStyle(.bordered)
        .padding(.top, 24)
    }

    // MARK: - Gestures & navigation

    private var swipeToChangeChapter: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > 90, abs(dx) > abs(dy) * 2 else { return }
                let target = dx < 0 ? bible.location(after: location) : bible.location(before: location)
                if let target { navigate(to: target) }
            }
    }

    private func navigate(to location: Location) {
        withAnimation(.easeInOut(duration: 0.2)) {
            reader.go(to: location)
        }
    }

    private func scrollToTarget(using proxy: ScrollViewProxy) async {
        guard let verse = reader.scrollTarget else { return }
        // Give the lazy stack a moment to lay out before jumping.
        try? await Task.sleep(for: .milliseconds(80))
        withAnimation { proxy.scrollTo(verse, anchor: .top) }
        selection = [verse]
        reader.scrollTarget = nil
    }

    // MARK: - Actions

    private func toggleSelection(_ verse: Int) {
        if selection.contains(verse) {
            selection.remove(verse)
        } else {
            selection.insert(verse)
        }
    }

    /// Applies `color` to every selected verse, or removes highlights when `color` is nil.
    private func applyHighlight(_ color: HighlightColor?) {
        let existing = Dictionary(highlights.map { ($0.verse, $0) }, uniquingKeysWith: { first, _ in first })
        for verse in selection {
            if let color {
                if let highlight = existing[verse] {
                    highlight.color = color
                } else {
                    modelContext.insert(Highlight(book: book.id, chapter: chapter, verse: verse, color: color))
                }
            } else if let highlight = existing[verse] {
                modelContext.delete(highlight)
            }
        }
        selection.removeAll()
    }

    private func toggleBookmarks(currentlyAllBookmarked: Bool) {
        if currentlyAllBookmarked {
            for bookmark in bookmarks where selection.contains(bookmark.verse) {
                modelContext.delete(bookmark)
            }
        } else {
            let already = Set(bookmarks.map(\.verse))
            for verse in selection.subtracting(already).sorted() {
                modelContext.insert(Bookmark(book: book.id, chapter: chapter, verse: verse))
            }
        }
        selection.removeAll()
    }
}

/// A single verse: superscript number, optional bookmark glyph, and serif text.
struct VerseRow: View {
    let number: Int
    let text: String
    let highlight: HighlightColor?
    let isBookmarked: Bool
    let isSelected: Bool

    var body: some View {
        let numberText = Text("\(number) ")
            .font(.system(.caption, design: .serif, weight: .semibold))
            .foregroundStyle(.secondary)
            .baselineOffset(6)
        let bookmarkText = isBookmarked
            ? Text("\(Image(systemName: "bookmark.fill")) ").font(.caption2).foregroundStyle(.tint)
            : Text("")

        Text("\(numberText)\(bookmarkText)\(text)")
            .font(.system(.title3, design: .serif))
            .lineSpacing(6)
            .underline(isSelected, pattern: .dot, color: .accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(highlight?.background ?? .clear, in: .rect(cornerRadius: 6))
            .padding(.horizontal, -6)
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Verse \(number). \(text)")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Floating toolbar shown while verses are selected.
struct SelectionActionBar: View {
    let reference: String
    let shareText: String
    let allBookmarked: Bool
    let onHighlight: (HighlightColor?) -> Void
    let onToggleBookmark: () -> Void
    let onDismiss: () -> Void

    @State private var copied = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(reference)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear selection")
            }

            HStack(spacing: 12) {
                ForEach(HighlightColor.allCases) { color in
                    Button {
                        onHighlight(color)
                    } label: {
                        Circle()
                            .fill(color.swatch)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().strokeBorder(.primary.opacity(0.15)))
                    }
                    .accessibilityLabel("Highlight \(color.rawValue)")
                }
                Button {
                    onHighlight(nil)
                } label: {
                    Image(systemName: "circle.slash")
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Remove highlight")

                Spacer(minLength: 4)

                Button(action: onToggleBookmark) {
                    Image(systemName: allBookmarked ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(allBookmarked ? "Remove bookmark" : "Add bookmark")

                Button {
                    UIPasteboard.general.string = shareText
                    copied = true
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                }
                .accessibilityLabel("Copy")

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")
            }
            .font(.title3)
        }
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .sensoryFeedback(.success, trigger: copied) { _, new in new }
    }
}
