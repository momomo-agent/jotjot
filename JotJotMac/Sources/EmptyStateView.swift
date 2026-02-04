import SwiftUI

struct EmptyStateView: View {
    var onCreateNew: () -> Void
    
    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "note.text")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 10) {
                Text("开始记录")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                Text("想到就记，记完就走")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            
            Button(action: onCreateNew) {
                Label("新建笔记", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("n", modifiers: .command)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
