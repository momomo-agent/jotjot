import SwiftUI
import SwiftData

@main
struct JotJotiOSApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Jot.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // 启用 iCloud 同步
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(sharedModelContainer)
    }
}
