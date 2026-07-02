import Foundation
import SwiftData

enum ClipStore {
    static func clearHistory(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ClipItem>()
        guard let items = try? modelContext.fetch(descriptor) else { return }

        for item in items {
            if let imagePath = item.imagePath {
                try? FileManager.default.removeItem(atPath: imagePath)
            }
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
