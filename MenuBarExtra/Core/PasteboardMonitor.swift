import Foundation
import AppKit
import SwiftData

@Observable
class PasteboardMonitor {
    private var lastChangeCount: Int
    private var timer: Timer?
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let currentChangeCount = NSPasteboard.general.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        guard let copiedText = NSPasteboard.general.string(forType: .string) else { return }

        let preview = String(copiedText.prefix(100))
        let clipItem = ClipItem(type: .text, textContent: copiedText, preview: preview)

        modelContext.insert(clipItem)
        try? modelContext.save()
    }

    deinit {
        stopMonitoring()
    }
}
