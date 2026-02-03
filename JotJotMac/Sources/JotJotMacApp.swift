import SwiftUI
import SwiftData

@main
struct JotJotMacApp: App {
    @StateObject private var hotKeyManager = HotKeyManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Jot.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { setupHotKey() }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新建笔记") {
                    NotificationCenter.default.post(name: .createNewJot, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        
        MenuBarExtra("JotJot", systemImage: "note.text") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
    
    private func setupHotKey() {
        hotKeyManager.onHotKey = {
            Task { @MainActor in
                WindowManager.shared.toggle()
            }
        }
    }
}

extension Notification.Name {
    static let createNewJot = Notification.Name("createNewJot")
}
