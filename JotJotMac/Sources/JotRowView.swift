import SwiftUI

struct JotRowView: View {
    let jot: Jot
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(jot.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if jot.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
    
    private var title: String {
        let firstLine = jot.content
            .components(separatedBy: .newlines)
            .first ?? ""
        return firstLine.isEmpty ? "新笔记" : firstLine
    }
}
