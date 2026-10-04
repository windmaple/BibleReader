import SwiftUI

struct ContentView: View {
    @Environment(BibleStore.self) private var bible
    @Environment(ReaderState.self) private var reader

    var body: some View {
        @Bindable var reader = reader

        Group {
            if bible.isLoaded {
                TabView(selection: $reader.selectedTab) {
                    ReaderScreen()
                        .tabItem { Label("Read", systemImage: "book") }
                        .tag(AppTab.read)

                    SavedScreen()
                        .tabItem { Label("Saved", systemImage: "bookmark") }
                        .tag(AppTab.saved)
                }
            } else if let error = bible.loadError {
                ContentUnavailableView(
                    "Couldn't Load the Bible",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                ProgressView("Loading…")
            }
        }
        .task {
            await bible.load()
            reader.location = bible.clamp(reader.location)
        }
    }
}
