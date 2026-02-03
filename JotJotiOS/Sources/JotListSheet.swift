import SwiftUI

struct JotListSheet: View {
    let jots: [Jot]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(jots.enumerated()), id: \.element.id) { index, jot in
                    Button {
                        currentIndex = index
                        dismiss()
                    } label: {
                        JotListRow(jot: jot, isSelected: index == currentIndex)
                    }
                }
            }
            .navigationTitle("所有笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
