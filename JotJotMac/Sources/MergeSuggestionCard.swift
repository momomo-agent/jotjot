import SwiftUI

/// Mac 版合并推荐卡片
struct MergeSuggestionCard: View {
    let pair: JotSimilarityAnalyzer.SimilarPair
    let onMerge: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("发现相似笔记")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            Text(pair.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                previewBox(pair.jot1.content)
                previewBox(pair.jot2.content)
            }
            
            Button(action: onMerge) {
                Text("合并笔记")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.small)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func previewBox(_ text: String) -> some View {
        Text(String(text.prefix(40)))
            .font(.caption)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
