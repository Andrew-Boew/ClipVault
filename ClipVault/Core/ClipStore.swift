import Foundation
import SwiftData

enum ClipStore {
    static func delete(_ item: ClipItem, in modelContext: ModelContext) {
        if let imagePath = item.imagePath {
            try? FileManager.default.removeItem(atPath: imagePath)
        }
        modelContext.delete(item)
    }

    static func clearHistory(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate { !$0.isPinned }
        )
        guard let items = try? modelContext.fetch(descriptor) else { return }

        for item in items {
            delete(item, in: modelContext)
        }
        try? modelContext.save()
    }

    static func enforceLimits(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate { !$0.isPinned },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let items = try? modelContext.fetch(descriptor) else { return }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -AppSettings.maxAgeDays, to: Date()) ?? .distantPast

        var removed = false
        for (index, item) in items.enumerated() {
            if index >= AppSettings.maxItems || item.createdAt < cutoffDate {
                delete(item, in: modelContext)
                removed = true
            }
        }
        if removed {
            try? modelContext.save()
        }
    }
}
