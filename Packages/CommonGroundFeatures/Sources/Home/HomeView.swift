import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var children: [Child]
    @Query(sort: \CalendarEvent.startDate) private var events: [CalendarEvent]
    @Query private var expenses: [Expense]
    @Query private var medications: [Medication]
    @Query private var families: [Family]

    @State private var appeared = false
    @State private var showAddEvent = false
    @State private var showAddExpense = false
    @State private var showExchangeLocation = false
    @State private var showDailyUpdate = false

    public init() {}

    private var currentMember: FamilyMember? {
        PermissionService.currentMember(in: families.first, memberId: appState.currentMemberId)
    }

    private var recentDailyUpdates: [TimelineEntry] {
        guard let child = selectedChild else { return [] }
        return DailyUpdateService.recentUpdates(for: child, limit: 3)
    }

    private var selectedChild: Child? {
        if let id = appState.selectedChildId {
            return children.first { $0.id == id }
        }
        return children.first
    }

    private var upcomingEvents: [CalendarEvent] {
        events.filter { $0.startDate >= Date() }.prefix(3).map { $0 }
    }

    private var unpaidTotal: Decimal {
        expenses.filter { !$0.isReimbursed }.reduce(Decimal.zero) { $0 + $1.owedAmount }
    }

    private var activeMedications: [Medication] {
        medications.filter(\.isActive)
    }

    private var upcomingExchange: CalendarEvent? {
        ExchangeLocationService.upcomingExchange(from: events, childId: selectedChild?.id)
    }

    private var showExchangeBanner: Bool {
        guard let exchange = upcomingExchange else { return false }
        return ExchangeLocationService.isWithinShareWindow(exchange)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CGSpacing.lg) {
                    greetingSection
                    quickActionsSection
                    if showExchangeBanner, let exchange = upcomingExchange {
                        ExchangeLocationBanner(event: exchange) {
                            showExchangeLocation = true
                        }
                    }
                    if let child = selectedChild {
                        childSummaryCard(child)
                    }
                    dailyUpdatesSection
                    if PermissionService.canViewCalendar(currentMember) {
                        upcomingSection
                    }
                    alertsSection
                }
                .padding(.horizontal, CGSpacing.md)
                .padding(.bottom, CGSpacing.xl)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showAddEvent) {
                AddEventView()
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(preselectedChild: selectedChild)
            }
            .sheet(isPresented: $showExchangeLocation) {
                if let exchange = upcomingExchange {
                    ExchangeLocationShareView(event: exchange)
                }
            }
            .sheet(isPresented: $showDailyUpdate) {
                if let child = selectedChild {
                    AddDailyUpdateView(child: child)
                }
            }
            .onAppear {
                if appState.selectedChildId == nil, let first = children.first {
                    appState.selectedChildId = first.id
                }
                withAnimation(CGAnimation.smooth.delay(0.1)) {
                    appeared = true
                }
            }
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: CGSpacing.xxs) {
            Text(greeting)
                .font(.title2.weight(.semibold))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            if let child = selectedChild {
                Text("Here's what's happening with \(child.firstName) today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .padding(.top, CGSpacing.sm)
    }

    private var quickActionsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: CGSpacing.md) {
            if PermissionService.canEditCalendar(currentMember) {
                CGQuickAction(icon: "plus.circle.fill", title: "Event") {
                    showAddEvent = true
                }
            }
            if PermissionService.canPostDailyUpdate(currentMember), selectedChild != nil {
                CGQuickAction(icon: "sun.horizon.fill", title: "Update", color: .orange) {
                    showDailyUpdate = true
                }
            }
            if PermissionService.canEditExpenses(currentMember) {
                CGQuickAction(icon: "dollarsign.circle.fill", title: "Expense", color: .green) {
                    showAddExpense = true
                }
            }
            if PermissionService.canSendMessages(currentMember) {
                CGQuickAction(icon: "bubble.left.fill", title: "Message", color: .blue) {
                    appState.selectedTab = .messages
                }
            }
            CGQuickAction(icon: "sparkles", title: "Ask AI", color: .purple) {
                appState.isAIAssistantPresented = true
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(CGAnimation.smooth.delay(0.15), value: appeared)
    }

    private func childSummaryCard(_ child: Child) -> some View {
        NavigationLink {
            ChildDetailView(child: child)
        } label: {
            CGCard {
                HStack(spacing: CGSpacing.md) {
                    CGAvatar(name: child.firstName, imageData: child.photoData, size: 56)

                    VStack(alignment: .leading, spacing: CGSpacing.xxs) {
                        Text(child.fullName)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Age \(child.age)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if !child.allergies.isEmpty {
                            HStack(spacing: CGSpacing.xxs) {
                                Image(systemName: "allergens")
                                    .font(.caption)
                                Text(child.allergies.joined(separator: ", "))
                                    .font(.caption)
                            }
                            .foregroundStyle(.orange)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var dailyUpdatesSection: some View {
        Group {
            if PermissionService.canViewTimeline(currentMember) {
                VStack(alignment: .leading, spacing: CGSpacing.sm) {
                    CGSectionHeader("Today's Updates", action: recentDailyUpdates.isEmpty ? nil : "See All") {
                        if let child = selectedChild {
                            appState.selectedChildId = child.id
                        }
                        appState.selectedTab = .children
                    }

                    if recentDailyUpdates.isEmpty {
                        CGCard {
                            VStack(alignment: .leading, spacing: CGSpacing.xs) {
                                Text("No updates yet today")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if PermissionService.canPostDailyUpdate(currentMember) {
                                    Button("Share what happened") {
                                        showDailyUpdate = true
                                    }
                                    .font(.subheadline.weight(.medium))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        ForEach(recentDailyUpdates, id: \.id) { entry in
                            DailyUpdateCard(entry: entry)
                        }
                    }
                }
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: CGSpacing.sm) {
            CGSectionHeader("Coming Up", action: "See All") {
                appState.selectedTab = .calendar
            }

            if upcomingEvents.isEmpty {
                CGCard {
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(upcomingEvents, id: \.id) { event in
                    EventRow(event: event)
                }
            }
        }
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: CGSpacing.sm) {
            if unpaidTotal > 0 && PermissionService.canViewExpenses(currentMember)
                || !activeMedications.isEmpty && PermissionService.canViewMedical(currentMember)
                || selectedChild?.emergencyInfo?.passportExpiry != nil && PermissionService.canViewEmergency(currentMember) {
                CGSectionHeader("Needs Attention")
            }

            if unpaidTotal > 0, PermissionService.canViewExpenses(currentMember) {
                AlertCard(
                    icon: "dollarsign.circle.fill",
                    color: .green,
                    title: "Outstanding Expenses",
                    detail: "$\(formattedAmount(unpaidTotal)) pending reimbursement"
                )
            }

            if !activeMedications.isEmpty, PermissionService.canViewMedical(currentMember) {
                AlertCard(
                    icon: "pills.fill",
                    color: .red,
                    title: "Active Medications",
                    detail: "\(activeMedications.count) medication\(activeMedications.count == 1 ? "" : "s") with reminders"
                )
            }

            if let child = selectedChild, PermissionService.canViewEmergency(currentMember),
               let expiry = child.emergencyInfo?.passportExpiry,
               expiry < Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date() {
                AlertCard(
                    icon: "person.text.rectangle.fill",
                    color: .orange,
                    title: "Passport Expiring",
                    detail: "Renew before \(expiry.formatted(date: .abbreviated, time: .omitted))"
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                appState.isAIAssistantPresented = true
            } label: {
                Image(systemName: "sparkles")
            }
            .accessibilityLabel("AI Assistant")
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)
    }
}

struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        CGCard(padding: CGSpacing.sm) {
            HStack(spacing: CGSpacing.sm) {
                Image(systemName: event.category.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: CGRadius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline.weight(.medium))
                    Text(event.startDate.formatted(date: .abbreviated, time: event.isAllDay ? .omitted : .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let location = event.location {
                    Text(location)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct AlertCard: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        CGCard(padding: CGSpacing.sm) {
            HStack(spacing: CGSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }
}
