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
                        Paster.copy(item)
                    } label: {
                        Text(item.preview)
                            .lineLimit(1)
                    }
                }
            }

            Divider()

            SettingsLink {
                Text("Settings…")
            }

            Button("Clear History") {
                ClipStore.clearHistory(in: modelContext)
            }
            .disabled(allItems.isEmpty)

            Button("Quit ClipVault") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
    }

}
