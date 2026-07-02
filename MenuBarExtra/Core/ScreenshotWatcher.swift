import Foundation
import AppKit

final class ScreenshotWatcher {
    private let query = NSMetadataQuery()
    private var startedAt = Date()

    func start() {
        startedAt = Date()

        query.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "kMDItemIsScreenCapture == 1"),
            NSPredicate(format: "kMDItemFSName BEGINSWITH 'Screenshot'"),
        ])
        query.searchScopes = [screenshotDirectory]

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUpdate(_:)),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )
        query.enableUpdates()
        query.start()
    }

    func stop() {
        query.stop()
        NotificationCenter.default.removeObserver(self)
    }

    private var screenshotDirectory: String {
        if let custom = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location"),
           !custom.isEmpty {
            return (custom as NSString).expandingTildeInPath
        }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].path
    }

    @objc private func handleUpdate(_ notification: Notification) {
        guard AppSettings.copyScreenshotsToClipboard else { return }
        guard let added = notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem],
              let item = added.last,
              let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else { return }

        if let created = item.value(forAttribute: NSMetadataItemFSCreationDateKey) as? Date,
           created < startedAt { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard let image = NSImage(contentsOfFile: path) else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])
        }
    }

    deinit {
        stop()
    }
}
