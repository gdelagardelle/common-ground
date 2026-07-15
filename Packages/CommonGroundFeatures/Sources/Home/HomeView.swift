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
                    if let child = selectedChild {
                        childHeroSection(child)
                    }
                    quickActionsSection
                    if showExchangeBanner, let exchange = upcomingExchange {
                        ExchangeLocationBanner(event: exchange) {
                            showExchangeLocation = true
                        }
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
            .background(CGColor.canvas)
            .navigationTitle(L10n.homeTitle)
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
        .tint(CGColor.primary)
    }

    // MARK: - Sections

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: CGSpacing.xxs) {
            Text(greeting)
                .font(CGTypography.title)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

            if let name = currentMember?.displayName.split(separator: " ").first.map(String.init) {
                Text(L10n.format("home.subtitle", name))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .padding(.top, CGSpacing.sm)
    }

    private func childHeroSection(_ child: Child) -> some View {
        NavigationLink {
            ChildDetailView(child: child)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    CGGradient.heroHeader
                        .frame(height: 110)
                    CGGradient.aurora
                        .opacity(0.12)
                        .frame(height: 110)
                        .blur(radius: 20)

                    HStack(alignment: .bottom, spacing: CGSpacing.md) {
                        CGAvatar(
                            name: child.firstName,
                            imageData: child.photoData,
                            genmojiData: child.genmojiData,
                            emoji: child.avatarEmoji,
                            size: 76
                        )
                            .offset(y: 20)

                        VStack(alignment: .leading, spacing: CGSpacing.xxs) {
                            if children.count > 1 {
                                childPicker(child)
                            } else {
                                Text(child.firstName)
                                    .font(CGTypography.headline)
                                    .foregroundStyle(.primary)
                            }
                            Text(L10n.format("common.age", child.age))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let parent = parentNameToday(for: child) {
                                Label(L10n.format("common.withToday", parent), systemImage: "house.fill")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(CGColor.primary)
                            }
                        }
                        .padding(.bottom, CGSpacing.sm)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .padding(.bottom, CGSpacing.md)
                    }
                    .padding(.horizontal, CGSpacing.md)
                }

                VStack(alignment: .leading, spacing: CGSpacing.sm) {
                    if let schedule = activeSchedule(for: child) {
                        CGCustodyWeekStrip(
                            assignments: CustodyScheduleGenerator.weekAssignments(for: schedule),
                            parentAName: schedule.parentAName,
                            parentBName: schedule.parentBName,
                            compact: true
                        )
                    }

                    if !child.allergies.isEmpty, PermissionService.canViewMedical(currentMember) {
                        HStack(spacing: CGSpacing.xs) {
                            Image(systemName: "allergens")
                                .font(.caption.weight(.semibold))
                            Text(child.allergies.joined(separator: " · "))
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(CGColor.warmAmber)
                        .padding(.horizontal, CGSpacing.sm)
                        .padding(.vertical, CGSpacing.xxs)
                        .background(CGColor.warmAmberSoft, in: Capsule())
                    }
                }
                .padding(CGSpacing.md)
                .padding(.top, CGSpacing.sm)
            }
            .background(CGColor.elevatedSurface, in: RoundedRectangle(cornerRadius: CGRadius.xl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CGRadius.xl, style: .continuous)
                    .strokeBorder(CGGradient.aurora.opacity(0.35), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: CGRadius.xl, style: .continuous))
            .shadow(color: CGColor.shadow, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .animation(CGAnimation.smooth.delay(0.08), value: appeared)
    }

    @ViewBuilder
    private func childPicker(_ child: Child) -> some View {
        Menu {
            ForEach(children, id: \.id) { option in
                Button(option.firstName) {
                    appState.selectedChildId = option.id
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(child.firstName)
                    .font(CGTypography.headline)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(.primary)
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: CGSpacing.sm) {
            Text(L10n.homeQuickActions)
                .font(CGTypography.captionEmphasis)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CGSpacing.md) {
                    if PermissionService.canPostDailyUpdate(currentMember), selectedChild != nil {
                        CGQuickAction(icon: "sun.horizon.fill", title: L10n.homeActionUpdate, emphasis: .warm) {
                            showDailyUpdate = true
                        }
                    }
                    if PermissionService.canEditCalendar(currentMember) {
                        CGQuickAction(icon: "calendar.badge.plus", title: L10n.homeActionEvent) {
                            showAddEvent = true
                        }
                    }
                    if PermissionService.canEditExpenses(currentMember) {
                        CGQuickAction(icon: "dollarsign.circle.fill", title: L10n.homeActionExpense, emphasis: .mint) {
                            showAddExpense = true
                        }
                    }
                    if PermissionService.canSendMessages(currentMember) {
                        CGQuickAction(icon: "bubble.left.fill", title: L10n.homeActionMessage, emphasis: .primary) {
                            appState.selectedTab = .messages
                        }
                    }
                    CGQuickAction(icon: "sparkles", title: L10n.homeActionAskAI, emphasis: .purple) {
                        appState.isAIAssistantPresented = true
                    }
                }
                .padding(.vertical, CGSpacing.xxs)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(CGAnimation.smooth.delay(0.12), value: appeared)
    }

    private var dailyUpdatesSection: some View {
        Group {
            if PermissionService.canViewTimeline(currentMember) {
                VStack(alignment: .leading, spacing: CGSpacing.sm) {
                    CGSectionHeader(L10n.homeTodaysUpdates, action: recentDailyUpdates.isEmpty ? nil : L10n.commonSeeAll) {
                        if let child = selectedChild {
                            appState.selectedChildId = child.id
                        }
                        appState.selectedTab = .children
                    }

                    if recentDailyUpdates.isEmpty {
                        CGCard(style: .warm) {
                            VStack(alignment: .leading, spacing: CGSpacing.sm) {
                                Label(L10n.homeUpdatePromptTitle, systemImage: "sun.horizon")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(CGColor.warmAmber)

                                Text(L10n.homeUpdatePromptBody)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if PermissionService.canPostDailyUpdate(currentMember) {
                                    Button(L10n.homeShareWhatHappened) {
                                        showDailyUpdate = true
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .tint(CGColor.primary)
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
            CGSectionHeader(L10n.homeComingUp, action: L10n.commonSeeAll) {
                appState.selectedTab = .calendar
            }

            if upcomingEvents.isEmpty {
                CGCard {
                    Text(L10n.homeNoUpcomingEvents)
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
                CGSectionHeader(L10n.homeNeedsAttention)
            }

            if unpaidTotal > 0, PermissionService.canViewExpenses(currentMember) {
                AlertCard(
                    icon: "dollarsign.circle.fill",
                    color: CGColor.schoolGreen,
                    title: L10n.homeOutstandingExpenses,
                    detail: L10n.format("home.expensePending", formattedAmount(unpaidTotal))
                )
            }

            if !activeMedications.isEmpty, PermissionService.canViewMedical(currentMember) {
                AlertCard(
                    icon: "pills.fill",
                    color: CGColor.medicalRed,
                    title: L10n.homeActiveMedications,
                    detail: activeMedications.count == 1
                        ? L10n.format("home.medicationCount", activeMedications.count)
                        : L10n.format("home.medicationsCount", activeMedications.count)
                )
            }

            if let child = selectedChild, PermissionService.canViewEmergency(currentMember),
               let expiry = child.emergencyInfo?.passportExpiry,
               expiry < Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date() {
                AlertCard(
                    icon: "person.text.rectangle.fill",
                    color: CGColor.warmAmber,
                    title: L10n.homePassportExpiring,
                    detail: L10n.format("home.passportRenew", expiry.formatted(date: .abbreviated, time: .omitted))
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
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(CGColor.primary)
            }
            .accessibilityLabel(L10n.homeAiAssistant)
        }
    }

    // MARK: - Helpers

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return L10n.homeGreetingMorning
        case 12..<17: return L10n.homeGreetingAfternoon
        default: return L10n.homeGreetingEvening
        }
    }

    private func activeSchedule(for child: Child) -> CustodySchedule? {
        child.custodySchedules.first(where: \.isActive) ?? child.custodySchedules.first
    }

    private func parentNameToday(for child: Child) -> String? {
        if let schedule = activeSchedule(for: child) {
            return CustodyScheduleGenerator.parentName(on: Date(), schedule: schedule)
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let event = child.events.first(where: {
            $0.category == .custody && calendar.isDate($0.startDate, inSameDayAs: today)
        }) {
            return event.title.replacingOccurrences(of: "With ", with: "")
        }
        return nil
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)
    }
}

struct EventRow: View {
    let event: CalendarEvent

    private var categoryColor: Color {
        CGColor.forEventCategory(event.category.color)
    }

    var body: some View {
        CGCard(padding: CGSpacing.sm) {
            HStack(spacing: CGSpacing.sm) {
                Image(systemName: event.category.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(categoryColor)
                    .frame(width: 36, height: 36)
                    .background(categoryColor.opacity(0.12), in: RoundedRectangle(cornerRadius: CGRadius.sm, style: .continuous))

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
                    .frame(width: 36)

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
