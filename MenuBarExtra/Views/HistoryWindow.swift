import SwiftUI
import SwiftData

struct HistoryWindow: View {
    @Query(sort: \ClipItem.createdAt, order: .reverse)
    private var items: [ClipItem]

    @State private var selectedID: ClipItem.ID?

    var body: some View {
        List(items, selection: $selectedID) { item in
            Text(item.preview)
                .lineLimit(1)
                .tag(item.id)
        }
        .onKeyPress(.return) {
            pasteSelected()
            return .handled
        }
        .frame(width: 400, height: 500)
        .onAppear {
            selectedID = items.first?.id
        }
    }

    private func pasteSelected() {
        guard let selectedID,
              let item = items.first(where: { $0.id == selectedID }) else { return }
        Paster.paste(item)
    }
}
