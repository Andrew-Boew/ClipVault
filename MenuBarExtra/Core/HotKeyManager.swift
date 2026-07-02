import Foundation
import AppKit
import SwiftUI
import SwiftData
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleHistory = Self("toggleHistory", initial: .init(.v, modifiers: [.command, .shift]))
}

@Observable
@MainActor
class HotKeyManager {
    private var panel: FloatingPanel?
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer

        KeyboardShortcuts.onKeyUp(for: .toggleHistory) { [weak self] in
            self?.togglePanel()
        }
    }

    private func togglePanel() {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        let panel = self.panel ?? makePanel()
        self.panel = panel

        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makePanel() -> FloatingPanel {
        let hostingView = FirstMouseHostingView(
            rootView: HistoryWindow()
                .modelContainer(modelContainer)
        )

        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false

        return panel
    }

    deinit {
        MainActor.assumeIsolated {
            KeyboardShortcuts.disable(.toggleHistory)
            panel?.close()
        }
    }
}
