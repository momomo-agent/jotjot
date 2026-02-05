import SwiftUI
import WidgetKit

struct JotJotWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }
    
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.blue)
                Spacer()
            }
            
            Spacer()
            
            Text("JotJot")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            
            Text("点击记录")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.blue)
                
                Spacer()
                
                Text("JotJot")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                
                Text("想到就记，记完就走")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack {
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                Text("新建")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
    }
}
