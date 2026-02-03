import SwiftUI

struct JotListRow: View {
    let jot: Jot
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if jot.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(jot.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var title: String {
        let line = jot.content.components(separatedBy: .newlines).first ?? ""
        return line.isEmpty ? "新笔记" : line
    }
}
