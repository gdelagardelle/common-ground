import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct CalendarView: View {
    @Query(sort: \CalendarEvent.startDate) private var events: [CalendarEvent]
    @Query private var children: [Child]
    @State private var selectedDate = Date()
    @State private var viewMode: CalendarViewMode = .month
    @State private var showAddEvent = false
    @State private var exchangeLocationEvent: CalendarEvent?

    public init() {}

    private var filteredEvents: [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, equalTo: selectedDate, toGranularity: viewMode == .month ? .month : .day)
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                datePickerHeader

                Picker(L10n.calendarViewMode, selection: $viewMode) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, CGSpacing.md)
                .padding(.bottom, CGSpacing.sm)

                if viewMode == .custody {
                    CustodyScheduleView(children: children)
                } else {
                    eventsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.calendarTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(L10n.calendarAddEvent)
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView(preselectedDate: selectedDate)
            }
            .sheet(item: $exchangeLocationEvent) { event in
                ExchangeLocationShareView(event: event)
            }
        }
    }

    private var datePickerHeader: some View {
        VStack(spacing: CGSpacing.sm) {
            HStack {
                Button {
                    withAnimation(CGAnimation.quick) {
                        selectedDate = Calendar.current.date(byAdding: viewMode == .month ? .month : .day, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }

                Spacer()

                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation(CGAnimation.quick) {
                        selectedDate = Calendar.current.date(byAdding: viewMode == .month ? .month : .day, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                }
            }
            .padding(.horizontal, CGSpacing.md)
            .padding(.top, CGSpacing.sm)

            MonthGridView(selectedDate: $selectedDate, events: events)
                .padding(.horizontal, CGSpacing.md)
        }
        .padding(.bottom, CGSpacing.sm)
    }

    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: CGSpacing.sm) {
                if filteredEvents.isEmpty {
                    CGEmptyState(
                        icon: "calendar",
                        title: L10n.calendarEmptyTitle,
                        message: L10n.calendarEmptyMessage,
                        actionTitle: L10n.calendarAddEvent
                    ) {
                        showAddEvent = true
                    }
                } else {
                    ForEach(filteredEvents, id: \.id) { event in
                        CalendarEventCard(event: event) {
                            if event.category == .exchange {
                                exchangeLocationEvent = event
                            }
                        }
                    }
                }
            }
            .padding(CGSpacing.md)
        }
    }
}

enum CalendarViewMode: CaseIterable {
    case month, day, custody

    var title: String {
        switch self {
        case .month: L10n.calendarMonth
        case .day: L10n.calendarDay
        case .custody: L10n.calendarCustody
        }
    }
}

struct MonthGridView: View {
    @Binding var selectedDate: Date
    let events: [CalendarEvent]

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(spacing: CGSpacing.xs) {
            LazyVGrid(columns: columns, spacing: CGSpacing.xs) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: columns, spacing: CGSpacing.xs) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            hasEvents: events.contains { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
                        ) {
                            withAnimation(CGAnimation.quick) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
    }

    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: selectedDate),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmpty = firstWeekday - calendar.firstWeekday
        let adjustedLeading = leadingEmpty < 0 ? leadingEmpty + 7 : leadingEmpty

        var days: [Date?] = Array(repeating: nil, count: adjustedLeading)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        return days
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : (Calendar.current.isDateInToday(date) ? Color.accentColor : .primary))

                if hasEvents {
                    Circle()
                        .fill(isSelected ? .white : Color.accentColor)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.clear),
                in: Circle()
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
    }
}

struct CalendarEventCard: View {
    let event: CalendarEvent
    var onTap: (() -> Void)?

    init(event: CalendarEvent, onTap: (() -> Void)? = nil) {
        self.event = event
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private var cardContent: some View {
        CGCard(padding: CGSpacing.sm) {
            HStack(spacing: CGSpacing.sm) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: CGSpacing.xxs) {
                    HStack {
                        Image(systemName: event.category.icon)
                            .font(.caption)
                        Text(event.category.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        if event.category == .exchange {
                            Spacer()
                            if event.hasSharedLocation {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            } else {
                                Text(L10n.calendarTapShareLocation)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    Text(event.title)
                        .font(.subheadline.weight(.semibold))

                    Text(event.startDate.formatted(date: .abbreviated, time: event.isAllDay ? .omitted : .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let location = event.location {
                        Label(location, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if event.category == .exchange, onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

struct CustodyScheduleView: View {
    let children: [Child]
    @State private var builderChild: Child?

    var body: some View {
        ScrollView {
            VStack(spacing: CGSpacing.md) {
                ForEach(children, id: \.id) { child in
                    CustodyChildCard(child: child) {
                        builderChild = child
                    }
                }

                CGCard {
                    VStack(alignment: .leading, spacing: CGSpacing.sm) {
                        Label(L10n.calendarScheduleChanges, systemImage: "hand.draw")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(L10n.calendarScheduleChangesNote)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(CGSpacing.md)
        }
        .sheet(isPresented: Binding(
            get: { builderChild != nil },
            set: { if !$0 { builderChild = nil } }
        )) {
            if let child = builderChild {
                CustodyScheduleBuilderView(child: child)
            }
        }
    }
}

struct CustodyChildCard: View {
    let child: Child
    let onSetup: () -> Void

    private var activeSchedule: CustodySchedule? {
        child.custodySchedules.first(where: \.isActive) ?? child.custodySchedules.first
    }

    private var nextExchange: CalendarEvent? {
        child.events
            .filter { $0.category == .exchange && $0.startDate >= Date() }
            .sorted(by: { $0.startDate < $1.startDate })
            .first
    }

    var body: some View {
        CGCard {
            VStack(alignment: .leading, spacing: CGSpacing.sm) {
                HStack {
                    CGAvatar(
                        name: child.firstName,
                        genmojiData: child.genmojiData,
                        emoji: child.avatarEmoji,
                        size: 40
                    )
                    Text(child.firstName)
                        .font(.headline)
                    Spacer()
                    if let schedule = activeSchedule {
                        CGBadge(schedule.pattern.displayName)
                    }
                }

                if activeSchedule != nil, let schedule = activeSchedule {
                    CGCustodyWeekStrip(
                        assignments: CustodyScheduleGenerator.weekAssignments(for: schedule),
                        parentAName: schedule.parentAName,
                        parentBName: schedule.parentBName
                    )
                    if let exchange = nextExchange {
                        Text(L10n.format("calendar.nextExchange", exchange.startDate.formatted(date: .abbreviated, time: .shortened)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(L10n.calendarNoCustodySchedule)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(activeSchedule == nil ? L10n.calendarSetupSchedule : L10n.calendarUpdateSchedule) {
                    onSetup()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
}
