import Foundation
import AppKit

enum Paster {
    static func paste(_ item: ClipItem) {
        guard copy(item) else { return }

        guard AXIsProcessTrusted() else {
            promptForAccessibilityAccess()
            return
        }

        simulatePasteKeystroke()
    }

    @discardableResult
    static func copy(_ item: ClipItem) -> Bool {
        switch item.type {
        case .text, .url:
            guard let text = item.textContent else { return false }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            return true

        case .image:
            guard let imagePath = item.imagePath,
                  let image = NSImage(contentsOfFile: imagePath) else { return false }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])
            return true
        }
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
