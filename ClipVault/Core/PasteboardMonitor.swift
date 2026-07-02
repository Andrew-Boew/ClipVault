import Foundation
import AppKit
import SwiftData
import CryptoKit

@Observable
class PasteboardMonitor {
    private var lastChangeCount: Int
    private var lastSavedHash: String?
    private var timer: Timer?
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lastChangeCount = NSPasteboard.general.changeCount
        self.lastSavedHash = Self.mostRecentItem(in: modelContext)?.contentHash
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

        if isExcludedApp() { return }

        if let fileItem = readFiles() {
            save(fileItem)
            return
        }

        if let imageItem = readImage() {
            save(imageItem)
            return
        }

        guard let copiedText = NSPasteboard.general.string(forType: .string), !copiedText.isEmpty else { return }
        guard let item = makeTextOrURLItem(from: copiedText) else { return }
        save(item)
    }

    private func isExcludedApp() -> Bool {
        guard let appName = frontmostAppName else { return false }
        return AppSettings.excludedApps.contains { $0.caseInsensitiveCompare(appName) == .orderedSame }
    }

    private var frontmostAppName: String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    private func readImage() -> ClipItem? {
        guard let imageData = NSPasteboard.general.data(forType: .tiff) ?? NSPasteboard.general.data(forType: .png) else { return nil }
        return makeImageItem(from: imageData)
    }

    private func readFiles() -> ClipItem? {
        guard let urls = NSPasteboard.general.readObjects(
                  forClasses: [NSURL.self],
                  options: [.urlReadingFileURLsOnly: true]
              ) as? [URL],
              !urls.isEmpty else { return nil }

        if urls.count == 1,
           let imageData = try? Data(contentsOf: urls[0]),
           NSBitmapImageRep(data: imageData) != nil {
            return makeImageItem(from: imageData)
        }

        let paths = urls.map(\.path)
        let hash = sha256(Data(paths.joined(separator: "\n").utf8))
        guard hash != lastSavedHash else { return nil }

        let names = urls.map(\.lastPathComponent)
        let preview = urls.count == 1
            ? names[0]
            : "\(urls.count) files: \(names.joined(separator: ", "))"

        return ClipItem(
            type: .file,
            filePaths: paths,
            preview: String(preview.prefix(100)),
            sourceApp: frontmostAppName,
            contentHash: hash
        )
    }

    private func makeImageItem(from imageData: Data) -> ClipItem? {
        guard let bitmap = NSBitmapImageRep(data: imageData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return nil }

        let hash = sha256(pngData)
        guard hash != lastSavedHash else { return nil }

        guard let path = saveImageToDisk(pngData) else { return nil }

        let preview = "Image (\(bitmap.pixelsWide)×\(bitmap.pixelsHigh))"
        return ClipItem(type: .image, imagePath: path, preview: preview, sourceApp: frontmostAppName, contentHash: hash)
    }

    private func saveImageToDisk(_ pngData: Data) -> String? {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipVault/images", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent("\(UUID().uuidString).png")
            try pngData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }

    private func makeTextOrURLItem(from text: String) -> ClipItem? {
        let hash = sha256(Data(text.utf8))
        guard hash != lastSavedHash else { return nil }

        if let url = URL(string: text), url.scheme != nil, url.host != nil {
            return ClipItem(type: .url, textContent: text, preview: text, sourceApp: frontmostAppName, contentHash: hash)
        }

        let preview = String(text.prefix(100))
        return ClipItem(type: .text, textContent: text, preview: preview, sourceApp: frontmostAppName, contentHash: hash)
    }

    private func save(_ item: ClipItem) {
        modelContext.insert(item)
        try? modelContext.save()
        lastSavedHash = item.contentHash
        ClipStore.enforceLimits(in: modelContext)
    }

    private func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func mostRecentItem(in context: ModelContext) -> ClipItem? {
        var descriptor = FetchDescriptor<ClipItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    deinit {
        stopMonitoring()
    }
}
