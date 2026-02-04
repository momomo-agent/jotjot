import SwiftUI

/// 合并推荐卡片
struct MergeSuggestionCard: View {
    let pair: JotSimilarityAnalyzer.SimilarPair
    let onMerge: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
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
                        .foregroundStyle(.secondary)
                }
            }
            
            // 原因
            Text(pair.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // 预览
            HStack(spacing: 8) {
                previewBox(pair.jot1.content)
                Image(systemName: "plus")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                previewBox(pair.jot2.content)
            }
            
            // 操作按钮
            Button(action: onMerge) {
                Text("合并笔记")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func previewBox(_ text: String) -> some View {
        Text(text.prefix(50) + (text.count > 50 ? "..." : ""))
            .font(.caption)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
