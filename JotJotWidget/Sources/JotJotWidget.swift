import WidgetKit
import SwiftUI

struct JotJotWidget: Widget {
    let kind: String = "JotJotWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            JotJotWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("JotJot")
        .description("快速记录灵感")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
