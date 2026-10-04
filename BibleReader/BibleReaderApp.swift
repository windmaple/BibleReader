import SwiftData
import SwiftUI

@main
struct BibleReaderApp: App {
    @State private var bible = BibleStore()
    @State private var reader = ReaderState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(bible)
                .environment(reader)
        }
        .modelContainer(for: [Bookmark.self, Highlight.self])
    }
}
