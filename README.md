# ClipVault

**Smart clipboard history for macOS.** Lives in your menu bar, remembers everything you copy, and pastes it back with a global hotkey.

macOS only remembers the last thing you copied — copy something new and the previous item is gone. ClipVault fixes that.

<!-- TODO: add demo GIF: ⌘⇧V → search → Enter → pasted -->

## Features

- **Clipboard history** — text, links, images, and files, captured automatically in the background
- **Global hotkey** — press <kbd>⌘⇧V</kbd> anywhere, pick an item, hit <kbd>Enter</kbd> — it pastes straight into the active app
- **Search** — filter history by content or source app as you type
- **Multi-select paste** — <kbd>⌘</kbd>-click several items and paste them together (files combine, texts join)
- **Pinning** — keep frequently used items at the top; pins survive history limits and Clear History
- **Screenshot auto-copy** — take a screenshot (<kbd>⌘⇧4</kbd>) and it's instantly ready to paste, no clicking the thumbnail
- **Deduplication** — copying the same thing twice doesn't clutter your history (SHA-256 content hashing)
- **History limits** — cap by item count and age, auto-pruned on launch and on every save
- **Launch at login**, configurable hotkey, and a native Settings window

## Privacy

- **Local only.** Everything stays on your Mac — SwiftData store and image files in `~/Library/Application Support`. No network access, no analytics, nothing leaves the machine.
- **Excluded apps.** Add any app (password managers, terminals) to the exclusion list and nothing copied from it is recorded.
- **One-click wipe.** Clear History removes database entries *and* image files from disk.
- **Honest limitation:** text you select and copy by hand is indistinguishable from any other text — no clipboard manager can tell it's a password. The exclusion list is the reliable layer; use it for sensitive apps.

## Requirements

- macOS 14+
- Accessibility permission (only used to simulate <kbd>⌘V</kbd> for pasting — that's the entire reason)

## Building

```bash
git clone <this repo>
open MenuBarExtra.xcodeproj
```

Build and run in Xcode (⌘R). Swift Package Manager resolves the single dependency ([KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)) automatically.

On first paste, macOS will ask for Accessibility permission: **System Settings → Privacy & Security → Accessibility** → enable ClipVault.

## Architecture

```
PasteboardMonitor ──► ClipStore (SwiftData) ──► Views (MenuBarExtra, HistoryWindow)
   polls NSPasteboard      dedup, limits,            search, multi-select,
   every 0.5 s             pinned priority           pinning, settings

HotKeyManager ──► floating NSPanel with history      Paster ──► NSPasteboard + CGEvent ⌘V
ScreenshotWatcher ──► kqueue watch on screenshot folder → clipboard in ~0.15 s
```

Key implementation details:

- **Clipboard monitoring** polls `changeCount` (there is no notification API) — near-zero CPU
- **Global hotkey panel** is a custom non-activating `NSPanel` (`canBecomeKey` + `acceptsFirstMouse`), so it opens over any app without stealing focus from your work
- **Screenshot detection** uses a kernel-level directory watch (`DispatchSource`), not Spotlight — ~0.15 s from file to clipboard
- **Images** are stored as PNG files on disk; the database keeps only paths
- **Files** are stored as references — pasting into Finder pastes the original files

## Tech stack

Swift 5.9 · SwiftUI · SwiftData · AppKit (NSPasteboard, NSPanel, CGEvent) · KeyboardShortcuts · SMAppService
