import SwiftUI
import SwiftData

@main
struct JotJotMacApp: App {
    @StateObject private var hotKeyManager = HotKeyManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Jot.self])
        // 先尝试正常创建
        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
        ) {
            return container
        }
        // 失败则用内存模式兜底
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
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
            
            CommandGroup(after: .textEditing) {
                Button("固定/取消固定") {
                    NotificationCenter.default.post(name: .togglePin, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)
                
                Button("删除笔记") {
                    NotificationCenter.default.post(name: .deleteJot, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
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
    static let selectJot = Notification.Name("selectJot")
    static let togglePin = Notification.Name("togglePin")
    static let deleteJot = Notification.Name("deleteJot")
}
