import SwiftUI
import SwiftData

struct HistoryWindow: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ClipItem.createdAt, order: .reverse)
    private var items: [ClipItem]

    @State private var selectedID: ClipItem.ID?
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(items) { item in
                        ClipRow(item: item, isSelected: item.id == selectedID)
                            .id(item.id)
                            .onTapGesture {
                                selectedID = item.id
                            }
                            .simultaneousGesture(
                                TapGesture(count: 2).onEnded {
                                    selectedID = item.id
                                    pasteSelected()
                                }
                            )
                    }
                }
                .padding(8)
            }
            .focusable()
            .focused($isFocused)
            .onKeyPress(.upArrow) {
                moveSelection(-1, proxy: proxy)
                return .handled
            }
            .onKeyPress(.downArrow) {
                moveSelection(1, proxy: proxy)
                return .handled
            }
            .onKeyPress(.return) {
                pasteSelected()
                return .handled
            }
            .onAppear {
                selectedID = items.first?.id
                isFocused = true
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
            }
        }
        .frame(width: 400, height: 500)
    }

    private var bottomBar: some View {
        HStack {
            Text("\(items.count) items")
                .foregroundStyle(.secondary)

            Spacer()

            Button("Clear History") {
                ClipStore.clearHistory(in: modelContext)
                selectedID = nil
            }
            .disabled(items.isEmpty)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func moveSelection(_ delta: Int, proxy: ScrollViewProxy) {
        guard !items.isEmpty else { return }
        let currentIndex = items.firstIndex(where: { $0.id == selectedID }) ?? 0
        let newIndex = min(max(currentIndex + delta, 0), items.count - 1)
        selectedID = items[newIndex].id
        proxy.scrollTo(items[newIndex].id, anchor: .center)
    }

    private func pasteSelected() {
        guard let selectedID,
              let item = items.first(where: { $0.id == selectedID }) else { return }
        Paster.paste(item)
    }
}
