import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ClipItem.createdAt, order: .reverse)
    private var allItems: [ClipItem]

    private var recentItems: [ClipItem] {
        Array(allItems.prefix(10))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if recentItems.isEmpty {
                Text("No clipboard history yet")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(recentItems) { item in
                    Button {
                        copyToPasteboard(item)
                    } label: {
                        Text(item.preview)
                            .lineLimit(1)
                    }
                }
            }

            Divider()

            Button("Clear History") {
                clearHistory()
            }
            .disabled(allItems.isEmpty)

            Button("Quit ClipVault") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
    }

    private func copyToPasteboard(_ item: ClipItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.textContent ?? "", forType: .string)
    }

    private func clearHistory() {
        for item in allItems {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
