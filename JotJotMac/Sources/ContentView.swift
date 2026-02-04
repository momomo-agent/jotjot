import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Jot.updatedAt, order: .reverse) private var jots: [Jot]
    @State private var selectedJot: Jot?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var mergeSuggestion: JotSimilarityAnalyzer.SimilarPair? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
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
            
            // 合并推荐
            if let suggestion = mergeSuggestion {
                MergeSuggestionCard(
                    pair: suggestion,
                    onMerge: { mergeJots(suggestion) },
                    onDismiss: { mergeSuggestion = nil }
                )
                .frame(maxWidth: 400)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedJot?.id)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: mergeSuggestion != nil)
        .onAppear {
            if selectedJot == nil { selectedJot = jots.first }
            checkForSimilarJots()
        }
        .onChange(of: jots.count) { _, _ in
            checkForSimilarJots()
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewJot)) { _ in
            createNewJot()
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectJot)) { notification in
            if let id = notification.object as? UUID,
               let jot = jots.first(where: { $0.id == id }) {
                withAnimation { selectedJot = jot }
            }
        }
    }
    
    private func createNewJot() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            let jot = Jot(content: "")
            modelContext.insert(jot)
            selectedJot = jot
        }
    }
    
    private func checkForSimilarJots() {
        guard jots.count >= 2 else { return }
        let pairs = JotSimilarityAnalyzer.findSimilarPairs(in: jots, threshold: 0.35)
        withAnimation { mergeSuggestion = pairs.first }
    }
    
    private func mergeJots(_ pair: JotSimilarityAnalyzer.SimilarPair) {
        pair.jot1.content = "\(pair.jot1.content)\n\n---\n\n\(pair.jot2.content)"
        pair.jot1.updatedAt = Date()
        pair.jot1.mediaItems.append(contentsOf: pair.jot2.mediaItems)
        modelContext.delete(pair.jot2)
        selectedJot = pair.jot1
        withAnimation { mergeSuggestion = nil }
    }
}
