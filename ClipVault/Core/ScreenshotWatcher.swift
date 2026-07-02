import Foundation
import AppKit
import Darwin

final class ScreenshotWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var directoryDescriptor: CInt = -1
    private var knownFiles: Set<String> = []
    private var directoryPath = ""

    private static let namePrefixes = ["Screenshot", "Снимок"]

    func start() {
        directoryPath = screenshotDirectory
        directoryDescriptor = open(directoryPath, O_EVTONLY)
        guard directoryDescriptor >= 0 else { return }

        knownFiles = screenshotFiles()

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: directoryDescriptor,
            eventMask: .write,
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.directoryChanged()
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.directoryDescriptor, fd >= 0 {
                close(fd)
                self?.directoryDescriptor = -1
            }
        }
        source.resume()
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    private var screenshotDirectory: String {
        if let custom = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location"),
           !custom.isEmpty {
            return (custom as NSString).expandingTildeInPath
        }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].path
    }

    private func screenshotFiles() -> Set<String> {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directoryPath)) ?? []
        return Set(names.filter { name in
            !name.hasPrefix(".") && name.lowercased().hasSuffix(".png")
        })
    }

    private func directoryChanged() {
        guard AppSettings.copyScreenshotsToClipboard else { return }

        let current = screenshotFiles()
        let added = current.subtracting(knownFiles)
        knownFiles = current

        guard let name = added.first(where: isScreenshotName) else { return }
        let path = (directoryPath as NSString).appendingPathComponent(name)
        copyWhenReady(path: path, attemptsLeft: 10)
    }

    private func isScreenshotName(_ name: String) -> Bool {
        Self.namePrefixes.contains { name.hasPrefix($0) }
    }

    private func copyWhenReady(path: String, attemptsLeft: Int) {
        guard attemptsLeft > 0 else { return }

        if let image = NSImage(contentsOfFile: path), image.isValid {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.copyWhenReady(path: path, attemptsLeft: attemptsLeft - 1)
            }
        }
    }

    deinit {
        stop()
    }
}
