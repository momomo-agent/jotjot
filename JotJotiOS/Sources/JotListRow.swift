import SwiftUI

struct JotListRow: View {
    let jot: Jot
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            // 选中指示器
            Circle()
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 8, height: 8)
                .animation(.spring(response: 0.3), value: isSelected)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if jot.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Text(preview)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                Text(jot.updatedAt, style: .relative)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        )
        .contentShape(Rectangle())
    }
    
    private var title: String {
        let line = jot.content.components(separatedBy: .newlines).first ?? ""
        return line.isEmpty ? "新笔记" : String(line.prefix(50))
    }
    
    private var preview: String {
        let lines = jot.content.components(separatedBy: .newlines)
        if lines.count > 1 {
            return lines.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
}
