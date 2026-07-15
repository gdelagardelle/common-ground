import WidgetKit
import SwiftUI
import CommonGroundCore

struct CustodyWidgetEntry: WidgetKit.TimelineEntry {
    let date: Date
    let childName: String
    let currentParent: String
    let nextExchange: Date
    let nextEvent: String
}

struct CustodyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CustodyWidgetEntry {
        CustodyWidgetEntry(
            date: Date(),
            childName: "Emma",
            currentParent: "Sarah",
            nextExchange: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            nextEvent: "Soccer Practice"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CustodyWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CustodyWidgetEntry>) -> Void) {
        let entry = placeholder(in: context)
        let timeline = Timeline(entries: [entry], policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: Date())!))
        completion(timeline)
    }
}

struct CustodyWidgetView: View {
    var entry: CustodyWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircular
        case .accessoryRectangular:
            accessoryRectangular
        default:
            systemWidget
        }
    }

    private var systemWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.caption.weight(.bold))
                Text(L10n.appName)
                    .font(.caption.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.secondary)

            Text(entry.childName)
                .font(.title2.weight(.bold))

            Label(L10n.format("custody.withParent", entry.currentParent), systemImage: "house.fill")
                .font(.subheadline)
                .foregroundStyle(.blue)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.widgetNextExchange)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.nextExchange, style: .relative)
                        .font(.caption.weight(.medium))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(L10n.widgetUpcoming)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.nextEvent)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var accessoryCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "house.fill")
                    .font(.caption)
                Text(entry.currentParent.prefix(1))
                    .font(.caption2.weight(.bold))
            }
        }
    }

    private var accessoryRectangular: some View {
        HStack {
            Image(systemName: "arrow.left.arrow.right")
            VStack(alignment: .leading) {
                Text("\(entry.childName) · \(entry.currentParent)")
                    .font(.headline)
                Text(L10n.format(
                    "widget.exchangeRelative",
                    entry.nextExchange.formatted(.relative(presentation: .named))
                ))
                    .font(.caption)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct CustodyWidget: Widget {
    let kind = "CustodyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustodyWidgetProvider()) { entry in
            CustodyWidgetView(entry: entry)
        }
        .configurationDisplayName(L10n.widgetCustodyName)
        .description(L10n.widgetCustodyDescription)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct CommonGroundWidgetBundle: WidgetBundle {
    var body: some Widget {
        CustodyWidget()
        ExchangeLiveActivity()
    }
}
