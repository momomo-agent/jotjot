import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Jot.updatedAt, order: .reverse) private var jots: [Jot]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(jots.prefix(5)) { jot in
                Button(action: { openJot(jot) }) {
                    Text(jot.content.isEmpty ? "新笔记" : firstLine(of: jot))
                        .lineLimit(1)
                }
            }
            
            Divider()
            
            Button("新建笔记") {
                createNewJot()
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
    }
    
    private func firstLine(of jot: Jot) -> String {
        jot.content.components(separatedBy: .newlines).first ?? ""
    }
    
    private func openJot(_ jot: Jot) {
        WindowManager.shared.show()
        NotificationCenter.default.post(name: .selectJot, object: jot.id)
    }
    
    private func createNewJot() {
        let jot = Jot(content: "")
        modelContext.insert(jot)
    }
}
