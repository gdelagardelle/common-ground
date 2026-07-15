import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct RootView: View {
    @Environment(SecurityService.self) private var security
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var families: [Family]

    public init() {}

    private var isProfessionalUser: Bool {
        guard let family = families.first else { return false }
        let member = PermissionService.currentMember(in: family, memberId: appState.currentMemberId)
        return PermissionService.isProfessional(member: member)
    }

    public var body: some View {
        Group {
            if !security.isUnlocked {
                LockScreenView()
            } else if families.isEmpty {
                OnboardingView()
            } else if isProfessionalUser {
                ProfessionalMainView()
            } else {
                MainTabView()
            }
        }
        .task {
            restoreSessionContext()
            #if DEBUG
            applyScreenshotLaunchArguments()
            #endif
            await configureNotificationsIfNeeded()
            await performCalendarSyncIfNeeded()
            #if canImport(ActivityKit)
            if !ScreenshotMode.isEnabled {
                await LiveActivityService.syncUpcomingExchanges(from: modelContext)
            }
            #endif
            WidgetSnapshotBuilder.refresh(from: modelContext)
        }
        .onChange(of: families.count) { _, _ in
            WidgetSnapshotBuilder.refresh(from: modelContext)
        }
        .sheet(isPresented: joinFamilySheetBinding) {
            JoinFamilyView(prefilledCode: deepLinkInviteCode)
        }
    }

    @Environment(DeepLinkCoordinator.self) private var deepLinks

    private var deepLinkInviteCode: String? {
        deepLinks.pendingInviteCode
    }

    private var joinFamilySheetBinding: Binding<Bool> {
        Binding(
            get: { deepLinks.shouldPresentJoinFamily },
            set: { deepLinks.shouldPresentJoinFamily = $0 }
        )
    }

    private func performCalendarSyncIfNeeded() async {
        #if DEBUG
        if ScreenshotMode.isEnabled {
            return
        }
        #endif
        guard CalendarSyncPreferences.isAutoSyncEnabled, !families.isEmpty else { return }
        guard await CalendarSyncService.requestAccess() else { return }
        let child = families.first?.children.first
        _ = try? await CalendarSyncService.performFullSync(
            context: modelContext,
            child: child,
            daysAhead: 90
        )
    }

    private func configureNotificationsIfNeeded() async {
        #if DEBUG
        if ScreenshotMode.isEnabled {
            return
        }
        #endif
        guard !families.isEmpty else { return }
        let key = "notifications.configured"
        guard !UserDefaults.standard.bool(forKey: key) else {
            NotificationService.syncAll(from: modelContext)
            return
        }
        let granted = await NotificationService.requestAuthorization()
        if granted {
            NotificationService.syncAll(from: modelContext)
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    private func restoreSessionContext() {
        guard let family = families.first else { return }

        if appState.currentMemberId == nil, let parent = family.members.first {
            appState.currentMemberId = parent.id
            appState.currentMemberName = parent.displayName
        }

        if appState.selectedChildId == nil {
            appState.selectedChildId = family.children.first?.id
        }
    }

    #if DEBUG
    private func applyScreenshotLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments

        if ScreenshotMode.isEnabled {
            SampleDataService.seedIfNeeded(context: modelContext)
            if let family = families.first ?? (try? modelContext.fetch(FetchDescriptor<Family>()))?.first,
               let parent = family.members.first,
               let child = family.children.first {
                appState.currentMemberId = parent.id
                appState.currentMemberName = parent.displayName
                appState.selectedChildId = child.id
                appState.isOnboardingComplete = true
            }
        }

        if let tabArgument = arguments.first(where: { $0.hasPrefix("-ScreenshotTab=") }) {
            let tabName = tabArgument.replacingOccurrences(of: "-ScreenshotTab=", with: "")
            if let tab = AppTab(rawValue: tabName) {
                appState.selectedTab = tab
            }
        }
    }
    #endif
}

struct LockScreenView: View {
    @Environment(SecurityService.self) private var security

    var body: some View {
        VStack(spacing: CGSpacing.xl) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(CGColor.primary)
                .symbolEffect(.bounce, value: security.isUnlocked)

            VStack(spacing: CGSpacing.xs) {
                Text(L10n.appName)
                    .font(.largeTitle.weight(.bold))

                Text(L10n.appTagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { _ = await security.authenticate() }
            } label: {
                Label(unlockLabel, systemImage: unlockIcon)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, CGSpacing.xl)
            .padding(.bottom, CGSpacing.xxl)
        }
        .background(CGGradient.hero.ignoresSafeArea())
    }

    private var unlockIcon: String {
        switch security.biometricType {
        case .faceID: "faceid"
        case .touchID: "touchid"
        default: "lock.open.fill"
        }
    }

    private var unlockLabel: String {
        switch security.biometricType {
        case .faceID: L10n.lockUnlockFaceID
        case .touchID: L10n.lockUnlockTouchID
        default: L10n.lockUnlock
        }
    }
}

public struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(AIAssistantService.self) private var aiService
    @Query private var families: [Family]

    private var currentMember: FamilyMember? {
        PermissionService.currentMember(in: families.first, memberId: appState.currentMemberId)
    }

    public init() {}

    public var body: some View {
        @Bindable var state = appState

        TabView(selection: $state.selectedTab) {
            HomeView()
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.icon) }
                .tag(AppTab.home)

            if PermissionService.canViewCalendar(currentMember) {
                CalendarView()
                    .tabItem { Label(AppTab.calendar.title, systemImage: AppTab.calendar.icon) }
                    .tag(AppTab.calendar)
            }

            ChildrenListView()
                .tabItem { Label(AppTab.children.title, systemImage: AppTab.children.icon) }
                .tag(AppTab.children)

            if PermissionService.canViewMessages(currentMember) {
                MessagesView()
                    .tabItem { Label(AppTab.messages.title, systemImage: AppTab.messages.icon) }
                    .tag(AppTab.messages)
            }

            MoreView()
                .tabItem { Label(AppTab.more.title, systemImage: AppTab.more.icon) }
                .tag(AppTab.more)
        }
        .tint(CGColor.primary)
        .sheet(isPresented: $state.isAIAssistantPresented) {
            AIAssistantView(aiService: aiService)
                .environment(appState)
        }
    }
}

public struct ProfessionalMainView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ProfessionalPortalView()
        }
    }
}
