import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Jot.updatedAt, order: .reverse) private var jots: [Jot]
    @State private var selectedJot: Jot?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            JotListView(jots: jots, selectedJot: $selectedJot)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
            if let jot = selectedJot {
                JotEditorView(jot: jot)
                    .id(jot.id)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                EmptyStateView(onCreateNew: createNewJot)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedJot?.id)
        .onAppear {
            if selectedJot == nil {
                selectedJot = jots.first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewJot)) { _ in
            createNewJot()
        }
    }
    
    private func createNewJot() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            let jot = Jot(content: "")
            modelContext.insert(jot)
            selectedJot = jot
        }
    }
}
