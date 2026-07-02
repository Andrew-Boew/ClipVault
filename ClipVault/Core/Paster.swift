import Foundation
import AppKit

enum Paster {
    static func paste(_ item: ClipItem) {
        paste([item])
    }

    static func paste(_ items: [ClipItem]) {
        guard copy(items) else { return }

        guard AXIsProcessTrusted() else {
            promptForAccessibilityAccess()
            return
        }

        simulatePasteKeystroke()
    }

    @discardableResult
    static func copy(_ item: ClipItem) -> Bool {
        copy([item])
    }

    @discardableResult
    static func copy(_ items: [ClipItem]) -> Bool {
        guard !items.isEmpty else { return false }

        if items.count == 1, items[0].type == .image {
            guard let imagePath = items[0].imagePath,
                  let image = NSImage(contentsOfFile: imagePath) else { return false }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])
            return true
        }

        var texts: [String] = []
        var urls: [NSURL] = []

        for item in items {
            switch item.type {
            case .text, .url:
                if let text = item.textContent {
                    texts.append(text)
                }
            case .image:
                if let path = item.imagePath, FileManager.default.fileExists(atPath: path) {
                    urls.append(NSURL(fileURLWithPath: path))
                }
            case .file:
                for path in item.filePaths ?? [] where FileManager.default.fileExists(atPath: path) {
                    urls.append(NSURL(fileURLWithPath: path))
                }
            }
        }

        var objects: [NSPasteboardWriting] = urls
        if !texts.isEmpty {
            objects.append(texts.joined(separator: "\n") as NSString)
        }
        guard !objects.isEmpty else { return false }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(objects)
        return true
    }

    private static func simulatePasteKeystroke() {
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode: CGKeyCode = 0x09

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }

    private static func promptForAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
