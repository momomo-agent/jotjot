import SwiftUI

struct EmptyStateView: View {
    var onCreateNew: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)
            
            Text("选择或创建笔记")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Button(action: onCreateNew) {
                Label("新建笔记", systemImage: "plus")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("n", modifiers: .command)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
