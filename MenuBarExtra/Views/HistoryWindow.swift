import SwiftUI
import SwiftData

struct HistoryWindow: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ClipItem.createdAt, order: .reverse)
    private var items: [ClipItem]

    @State private var searchText = ""
    @State private var selectedIDs: Set<ClipItem.ID> = []
    @State private var anchorID: ClipItem.ID?
    @FocusState private var isSearchFocused: Bool

    private var filteredItems: [ClipItem] {
        let matching: [ClipItem]
        if searchText.isEmpty {
            matching = items
        } else {
            matching = items.filter { item in
                item.preview.localizedCaseInsensitiveContains(searchText)
                    || (item.textContent?.localizedCaseInsensitiveContains(searchText) ?? false)
                    || (item.sourceApp?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return matching.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.createdAt > rhs.createdAt
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredItems) { item in
                        ClipRow(item: item, isSelected: selectedIDs.contains(item.id))
                            .id(item.id)
                            .onTapGesture {
                                handleTap(item)
                            }
                            .simultaneousGesture(
                                TapGesture(count: 2).onEnded {
                                    selectedIDs = [item.id]
                                    anchorID = item.id
                                    pasteSelected()
                                }
                            )
                            .contextMenu {
                                Button(item.isPinned ? "Unpin" : "Pin") {
                                    item.isPinned.toggle()
                                    try? modelContext.save()
                                }
                                Button("Delete", role: .destructive) {
                                    selectedIDs.remove(item.id)
                                    ClipStore.delete(item, in: modelContext)
                                    try? modelContext.save()
                                }
                            }
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
                selectFirst()
                isSearchFocused = true
            }
            .onChange(of: searchText) {
                selectFirst()
                if let anchorID {
                    proxy.scrollTo(anchorID, anchor: .top)
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
            Text(selectionSummary)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Clear History") {
                ClipStore.clearHistory(in: modelContext)
                selectedIDs = []
                anchorID = nil
            }
            .disabled(items.isEmpty)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var selectionSummary: String {
        selectedIDs.count > 1
            ? "\(filteredItems.count) items · \(selectedIDs.count) selected"
            : "\(filteredItems.count) items"
    }

    private func handleTap(_ item: ClipItem) {
        if NSEvent.modifierFlags.contains(.command) {
            if selectedIDs.contains(item.id) {
                selectedIDs.remove(item.id)
            } else {
                selectedIDs.insert(item.id)
            }
        } else {
            selectedIDs = [item.id]
        }
        anchorID = item.id
    }

    private func selectFirst() {
        anchorID = filteredItems.first?.id
        selectedIDs = anchorID.map { [$0] } ?? []
    }

    private func moveSelection(_ delta: Int, proxy: ScrollViewProxy) {
        let visible = filteredItems
        guard !visible.isEmpty else { return }
        let currentIndex = visible.firstIndex(where: { $0.id == anchorID }) ?? 0
        let newIndex = min(max(currentIndex + delta, 0), visible.count - 1)
        anchorID = visible[newIndex].id
        selectedIDs = [visible[newIndex].id]
        proxy.scrollTo(visible[newIndex].id, anchor: .center)
    }

    private func pasteSelected() {
        let selection = filteredItems.filter { selectedIDs.contains($0.id) }
        guard !selection.isEmpty else { return }
        Paster.paste(selection)
    }
}
