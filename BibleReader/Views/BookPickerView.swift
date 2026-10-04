import SwiftUI

/// Sheet for choosing a book, then a chapter.
struct BookPickerView: View {
    @Environment(BibleStore.self) private var bible
    @Environment(ReaderState.self) private var reader
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var path: [Book] = []

    private func books(in testament: Testament) -> [Book] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return bible.books.filter { book in
            book.testament == testament
                && (query.isEmpty
                    || book.name.localizedCaseInsensitiveContains(query)
                    || book.abbrev.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollViewReader { proxy in
                List {
                    ForEach(Testament.allCases) { testament in
                        let books = books(in: testament)
                        if !books.isEmpty {
                            Section(testament.rawValue) {
                                ForEach(books) { book in
                                    bookRow(book)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .onAppear {
                    proxy.scrollTo(reader.location.book, anchor: .center)
                }
            }
            .overlay {
                if Testament.allCases.allSatisfy({ books(in: $0).isEmpty }) {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find a book")
            .navigationTitle("Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .navigationDestination(for: Book.self) { book in
                ChapterGridView(book: book) { chapter in
                    select(book: book, chapter: chapter)
                }
            }
        }
    }

    private func bookRow(_ book: Book) -> some View {
        let isCurrent = book.id == reader.location.book
        return Button {
            if book.chapterCount == 1 {
                select(book: book, chapter: 1)
            } else {
                path.append(book)
            }
        } label: {
            HStack {
                Text(book.name)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundStyle(isCurrent ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                Spacer()
                Text("\(book.chapterCount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
        }
        .id(book.id)
        .accessibilityLabel("\(book.name), \(book.chapterCount) chapters")
    }

    private func select(book: Book, chapter: Int) {
        reader.go(to: Location(book: book.id, chapter: chapter))
        dismiss()
    }
}

/// Grid of chapter numbers for a book.
struct ChapterGridView: View {
    let book: Book
    let onSelect: (Int) -> Void

    @Environment(ReaderState.self) private var reader

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...book.chapterCount, id: \.self) { chapter in
                    let isCurrent = reader.location == Location(book: book.id, chapter: chapter)
                    Button {
                        onSelect(chapter)
                    } label: {
                        Text("\(chapter)")
                            .font(.body.monospacedDigit().weight(isCurrent ? .bold : .medium))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(isCurrent ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                            .background(
                                isCurrent ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary),
                                in: .rect(cornerRadius: 10)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Chapter \(chapter)")
                }
            }
            .padding()
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
