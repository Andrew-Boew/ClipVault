import SwiftUI
import SwiftData

@main
struct ClipVaultApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClipItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let pasteboardMonitor: PasteboardMonitor
    private let hotKeyManager: HotKeyManager

    init() {
        let container = sharedModelContainer
        let monitor = PasteboardMonitor(modelContext: container.mainContext)
        monitor.startMonitoring()
        pasteboardMonitor = monitor
        hotKeyManager = HotKeyManager(modelContainer: container)
    }

    var body: some Scene {
        MenuBarExtra("ClipVault", systemImage: "doc.on.clipboard") {
            MenuBarView()
                .modelContainer(sharedModelContainer)
        }
    }
}
