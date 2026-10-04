import SwiftData
import SwiftUI

/// Lists saved bookmarks and highlights; tapping one jumps to it in the reader.
struct SavedScreen: View {
    enum Kind: String, CaseIterable, Identifiable {
        case bookmarks = "Bookmarks"
        case highlights = "Highlights"
        var id: String { rawValue }
    }

    @Environment(BibleStore.self) private var bible
    @Environment(ReaderState.self) private var reader
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \Highlight.createdAt, order: .reverse) private var highlights: [Highlight]

    @State private var kind: Kind = .bookmarks

    var body: some View {
        NavigationStack {
            List {
                switch kind {
                case .bookmarks:
                    ForEach(bookmarks) { bookmark in
                        row(book: bookmark.book, chapter: bookmark.chapter, verse: bookmark.verse, date: bookmark.createdAt) {
                            Image(systemName: "bookmark.fill").foregroundStyle(.tint)
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { bookmarks[$0] }.forEach(modelContext.delete)
                    }
                case .highlights:
                    ForEach(highlights) { highlight in
                        row(book: highlight.book, chapter: highlight.chapter, verse: highlight.verse, date: highlight.createdAt) {
                            Circle().fill(highlight.color.swatch).frame(width: 12, height: 12)
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { highlights[$0] }.forEach(modelContext.delete)
                    }
                }
            }
            .overlay { emptyState }
            .safeAreaInset(edge: .top) {
                Picker("Show", selection: $kind) {
                    ForEach(Kind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.bar)
            }
            .navigationTitle("Saved")
            .toolbar {
                if !(kind == .bookmarks ? bookmarks.isEmpty : highlights.isEmpty) {
                    EditButton()
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch kind {
        case .bookmarks where bookmarks.isEmpty:
            ContentUnavailableView(
                "No Bookmarks",
                systemImage: "bookmark",
                description: Text("Tap a verse while reading, then tap the bookmark button to save it here.")
            )
        case .highlights where highlights.isEmpty:
            ContentUnavailableView(
                "No Highlights",
                systemImage: "highlighter",
                description: Text("Tap a verse while reading and pick a color to highlight it.")
            )
        default:
            EmptyView()
        }
    }

    private func row<Marker: View>(
        book: Int,
        chapter: Int,
        verse: Int,
        date: Date,
        @ViewBuilder marker: () -> Marker
    ) -> some View {
        Button {
            reader.go(to: Location(book: book, chapter: chapter), verse: verse)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    marker()
                    Text(bible.reference(book: book, chapter: chapter, verses: [verse]))
                        .font(.headline)
                    Spacer()
                    Text(date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(bible.text(book: book, chapter: chapter, verse: verse))
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .padding(.vertical, 4)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
