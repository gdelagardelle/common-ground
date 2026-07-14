import ActivityKit
import WidgetKit
import SwiftUI
import CommonGroundCore

struct ExchangeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ExchangeActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Custody Exchange")
                        .font(.headline)
                }
                Text(context.attributes.childName)
                    .font(.title2.weight(.bold))
                Text("With \(context.state.withParent)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(context.state.exchangeTime, style: .time)
                    .font(.title3.weight(.semibold))
                if let location = context.state.location {
                    Label(location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(Color.blue.opacity(0.15))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.blue)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading) {
                        Text(context.attributes.childName)
                            .font(.headline)
                        Text("Exchange at \(context.state.exchangeTime.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.hoursRemaining)h")
                        .font(.headline)
                        .monospacedDigit()
                }
            } compactLeading: {
                Image(systemName: "arrow.left.arrow.right")
            } compactTrailing: {
                Text("\(context.state.hoursRemaining)h")
                    .font(.caption2.weight(.bold))
            } minimal: {
                Image(systemName: "arrow.left.arrow.right")
            }
        }
    }
}
