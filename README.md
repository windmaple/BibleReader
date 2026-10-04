# KJV Bible — iOS Reader

A clean, offline SwiftUI Bible reader for iPhone and iPad featuring the King James Version.

## Features

- **Offline KJV text**: all 66 books, 1,189 chapters, and 31,102 verses are bundled in the app.
- **Reader**: serif typography that scales with Dynamic Type, plus light/dark mode.
- **Navigation**: tap the title to open a searchable book list and chapter grid. Move between chapters with the toolbar chevrons, the footer buttons, or a horizontal swipe.
- **Resume reading**: the app reopens at the last chapter you read.
- **Highlights**: tap one or more verses and choose from 5 colors (or remove a highlight).
- **Bookmarks**: bookmark any selected verses. Bookmarked verses show a small ribbon icon.
- **Copy & share**: selected verses are copied or shared with a reference such as `John 3:16-17 (KJV)`.
- **Saved tab**: shows your bookmarks and highlights. Tap an entry to jump to that verse. Swipe or use Edit to delete.

Bookmarks and highlights are stored on-device with SwiftData.

## Requirements

- Xcode 16 or later (the project uses synchronized folders)
- iOS 17.0 or later

## Run

1. Open `BibleReader.xcodeproj` in Xcode.
2. Select the **BibleReader** scheme and a simulator or device.
3. Press **⌘R**.

To run on a physical device, set your Team under *Signing & Capabilities*. You may also need to change the bundle identifier (`com.example.BibleReader`).

## Project layout

```
BibleReader/
├── BibleReaderApp.swift        App entry, SwiftData container
├── Models/
│   ├── BibleStore.swift        Loads kjv.json, navigation and reference helpers
│   ├── ReaderState.swift       Current position (persisted), tab and scroll state
│   └── Annotations.swift       Bookmark and Highlight models, highlight colors
├── Views/
│   ├── ContentView.swift       Loading state and tabs
│   ├── ReaderScreen.swift      Chapter reader, verse rows, selection action bar
│   ├── BookPickerView.swift    Book list and chapter grid
│   └── SavedScreen.swift       Bookmarks and highlights lists
├── Resources/kjv.json          KJV text (public domain)
└── Assets.xcassets             App icon and accent color
```

`kjv.json` has the format `[{ "name", "abbrev", "chapters": [[verse, ...], ...] }, ...]`.

## Text source

The King James Version is in the public domain in most of the world. The text comes from [thiagobodruk/bible](https://github.com/thiagobodruk/bible) and has been re-keyed with English book names.
