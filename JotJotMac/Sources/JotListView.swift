import SwiftUI
import SwiftData

struct JotListView: View {
    let jots: [Jot]
    @Binding var selectedJot: Jot?
    @Environment(\.modelContext) private var modelContext
    
    var pinnedJots: [Jot] { jots.filter { $0.isPinned } }
    var unpinnedJots: [Jot] { jots.filter { !$0.isPinned } }
    
    var body: some View {
        List(selection: $selectedJot) {
            if !pinnedJots.isEmpty {
                Section {
                    ForEach(pinnedJots) { jot in
                        JotRowView(jot: jot)
                            .tag(jot)
                    }
                    .onDelete(perform: deletePinnedJots)
                } header: {
                    Label("固定", systemImage: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Section {
                ForEach(unpinnedJots) { jot in
                    JotRowView(jot: jot)
                        .tag(jot)
                }
                .onDelete(perform: deleteUnpinnedJots)
            } header: {
                Label("笔记", systemImage: "note.text")
                    .font(.caption)
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem {
                Button(action: createNewJot) {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title2)
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("新建笔记 ⌘N")
            }
        }
    }
    
    private func createNewJot() {
        NotificationCenter.default.post(name: .createNewJot, object: nil)
    }
    
    private func deletePinnedJots(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(pinnedJots[index])
        }
    }
    
    private func deleteUnpinnedJots(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(unpinnedJots[index])
        }
    }
}
