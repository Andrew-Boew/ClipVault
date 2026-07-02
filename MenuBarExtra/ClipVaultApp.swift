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

    @State private var pasteboardMonitor: PasteboardMonitor?

    var body: some Scene {
        MenuBarExtra("ClipVault", systemImage: "doc.on.clipboard") {
            MenuBarView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    if pasteboardMonitor == nil {
                        let monitor = PasteboardMonitor(modelContext: sharedModelContainer.mainContext)
                        monitor.startMonitoring()
                        pasteboardMonitor = monitor
                    }
                }
        }
    }
}
