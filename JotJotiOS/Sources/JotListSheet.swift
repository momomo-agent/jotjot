import SwiftUI

struct JotListSheet: View {
    let jots: [Jot]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(Array(jots.enumerated()), id: \.element.id) { index, jot in
                        Button {
                            impactFeedback.impactOccurred()
                            currentIndex = index
                            dismiss()
                        } label: {
                            JotListRow(jot: jot, isSelected: index == currentIndex)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .id(index)
                    }
                }
                .listStyle(.plain)
                .onAppear {
                    // 滚动到当前选中的笔记
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(currentIndex, anchor: .center)
                        }
                    }
                }
            }
            .navigationTitle("所有笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        impactFeedback.impactOccurred()
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
