import SwiftUI
import SwiftData

struct HistoryWindow: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ClipItem.createdAt, order: .reverse)
    private var items: [ClipItem]

    @State private var searchText = ""
    @State private var selectedID: ClipItem.ID?
    @FocusState private var isSearchFocused: Bool

    private var filteredItems: [ClipItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter { item in
            item.preview.localizedCaseInsensitiveContains(searchText)
                || (item.textContent?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredItems) { item in
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
            .safeAreaInset(edge: .top, spacing: 0) {
                searchBar(proxy: proxy)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
            }
            .onAppear {
                selectedID = filteredItems.first?.id
                isSearchFocused = true
            }
            .onChange(of: searchText) {
                selectedID = filteredItems.first?.id
                if let selectedID {
                    proxy.scrollTo(selectedID, anchor: .top)
                }
            }
        }
        .frame(width: 400, height: 500)
    }

    private func searchBar(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search history…", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .onSubmit {
                    pasteSelected()
                }
                .onKeyPress(.upArrow) {
                    moveSelection(-1, proxy: proxy)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    moveSelection(1, proxy: proxy)
                    return .handled
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var bottomBar: some View {
        HStack {
            Text("\(filteredItems.count) items")
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
        let visible = filteredItems
        guard !visible.isEmpty else { return }
        let currentIndex = visible.firstIndex(where: { $0.id == selectedID }) ?? 0
        let newIndex = min(max(currentIndex + delta, 0), visible.count - 1)
        selectedID = visible[newIndex].id
        proxy.scrollTo(visible[newIndex].id, anchor: .center)
    }

    private func pasteSelected() {
        guard let selectedID,
              let item = filteredItems.first(where: { $0.id == selectedID }) else { return }
        Paster.paste(item)
    }
}
