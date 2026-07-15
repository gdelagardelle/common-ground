import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct MoreView: View {
    @Environment(AppState.self) private var appState
    @Environment(SecurityService.self) private var security
    @Environment(\.modelContext) private var modelContext
    @Query private var checklists: [Checklist]
    @Query(sort: \Child.firstName) private var children: [Child]
    @Query private var families: [Family]

    @State private var showAddExpense = false
    @State private var showAddMember = false
    @State private var showCalendarImport = false
    @State private var showInvite = false
    @State private var showJoinFamily = false
    @State private var showHealthImport = false
    @State private var notificationsEnabled = false

    private var currentMember: FamilyMember? {
        PermissionService.currentMember(in: families.first, memberId: appState.currentMemberId)
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section(L10n.moreFamilyTools) {
                    if families.first != nil, (families.first?.members.count ?? 0) > 1 {
                        NavigationLink { ActingAsMemberView() } label: {
                            Label(L10n.format("more.actingAs", appState.currentMemberName), systemImage: "person.crop.circle.badge.checkmark")
                        }
                    }

                    Button {
                        showAddExpense = true
                    } label: {
                        Label(L10n.moreAddExpense, systemImage: "dollarsign.circle")
                    }

                    Button {
                        showAddMember = true
                    } label: {
                        Label(L10n.moreAddCoParent, systemImage: "person.badge.plus")
                    }

                    NavigationLink { ChecklistsView(checklists: checklists) } label: {
                        Label(L10n.moreChecklists, systemImage: "checklist")
                    }
                    NavigationLink { AuditLogView() } label: {
                        Label(L10n.moreAuditLog, systemImage: "list.bullet.rectangle.portrait")
                    }
                    NavigationLink { ExportView() } label: {
                        Label(L10n.moreCourtExport, systemImage: "doc.text.magnifyingglass")
                    }

                    NavigationLink { CustodyAgreementsListView() } label: {
                        Label(L10n.moreCustodyAgreements, systemImage: "signature")
                    }
                }

                Section(L10n.moreProfessionalAccess) {
                    NavigationLink { ProfessionalPortalView() } label: {
                        Label(L10n.moreProfessionalPortal, systemImage: "briefcase.fill")
                    }
                    Text(L10n.moreProfessionalHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(L10n.moreIntegrations) {
                    Button {
                        showCalendarImport = true
                    } label: {
                        Label(L10n.moreAppleCalendar, systemImage: "calendar.badge.clock")
                    }

                    Button {
                        showInvite = true
                    } label: {
                        Label(L10n.moreInviteCoParent, systemImage: "person.2.badge.gearshape")
                    }

                    Button {
                        showJoinFamily = true
                    } label: {
                        Label(L10n.moreJoinFamily, systemImage: "person.2.fill")
                    }

                    NavigationLink { SyncSettingsView() } label: {
                        Label(L10n.moreICloudSync, systemImage: "icloud")
                    }

                    Button {
                        showHealthImport = true
                    } label: {
                        Label(L10n.moreAppleHealth, systemImage: "heart.text.square")
                    }

                    if let child = children.first {
                        NavigationLink {
                            SchoolPortalView(child: child)
                        } label: {
                            Label(L10n.moreSchoolPortal, systemImage: "building.columns.fill")
                        }
                    }
                }

                Section {
                    Toggle(isOn: lockEnabledBinding) {
                        Label(L10n.format("lock.require", lockMethodLabel), systemImage: lockIcon)
                    }

                    if security.isLockEnabled {
                        Button(L10n.lockNow) {
                            security.lock()
                        }
                    }

                    Toggle(isOn: $notificationsEnabled) {
                        Label(L10n.moreReminders, systemImage: "bell.badge")
                    }
                    .onChange(of: notificationsEnabled) { _, enabled in
                        Task {
                            if enabled {
                                let granted = await NotificationService.requestAuthorization()
                                notificationsEnabled = granted
                                if granted {
                                    NotificationService.syncAll(from: modelContext)
                                }
                            }
                        }
                    }

                    NavigationLink { PermissionsView() } label: {
                        Label(L10n.morePermissions, systemImage: "person.badge.shield.checkmark")
                    }

                    NavigationLink { LanguageSettingsView() } label: {
                        Label(L10n.languageTitle, systemImage: "globe")
                    }
                } header: {
                    Text(L10n.morePrivacySecurity)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if security.isLockEnabled {
                            Text(L10n.moreLockOnFooter)
                        } else {
                            Text(L10n.format("more.lockOff.footer", lockMethodLabel))
                        }
                        Text(notificationsEnabled
                             ? L10n.moreRemindersOnFooter
                             : L10n.moreRemindersOffFooter)
                    }
                }

                Section(L10n.moreAbout) {
                    LabeledContent(L10n.commonVersion, value: "1.0.0")
                    LabeledContent(L10n.moreSync, value: SyncPreferences.isCloudKitEnabled ? L10n.moreSyncICloud : L10n.moreSyncLocal)
                }
            }
            .navigationTitle(L10n.moreTitle)
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showAddMember) {
                AddFamilyMemberView()
            }
            .sheet(isPresented: $showCalendarImport) {
                CalendarSyncView()
            }
            .sheet(isPresented: $showInvite) {
                InviteCoParentView()
            }
            .sheet(isPresented: $showJoinFamily) {
                JoinFamilyView()
            }
            .sheet(isPresented: $showHealthImport) {
                HealthImportView()
            }
            .task {
                let status = await NotificationService.authorizationStatus()
                notificationsEnabled = status == .authorized
            }
        }
    }

    private var lockEnabledBinding: Binding<Bool> {
        Binding(
            get: { security.isLockEnabled },
            set: { security.setLockEnabled($0) }
        )
    }

    private var lockMethodLabel: String {
        switch security.biometricType {
        case .faceID: L10n.lockMethodFaceID
        case .touchID: L10n.lockMethodTouchID
        default: L10n.lockMethodPasscode
        }
    }

    private var lockIcon: String {
        switch security.biometricType {
        case .faceID: "faceid"
        case .touchID: "touchid"
        default: "lock.shield.fill"
        }
    }
}

struct ChecklistsView: View {
    let checklists: [Checklist]

    var body: some View {
        List(checklists, id: \.id) { checklist in
            VStack(alignment: .leading, spacing: CGSpacing.xs) {
                HStack {
                    Text(checklist.title)
                        .font(.headline)
                    Spacer()
                    CGProgressRing(progress: checklist.progress)
                        .frame(width: 28, height: 28)
                }

                Text(L10n.format("more.checklists.complete", checklist.completedCount, checklist.items.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(checklist.items.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.id) { item in
                    HStack {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                        Text(item.title)
                            .strikethrough(item.isCompleted)
                            .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.vertical, CGSpacing.xxs)
        }
        .navigationTitle(L10n.moreChecklists)
    }
}

struct AuditLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var families: [Family]

    private var entries: [AuditEntry] {
        AuditLogService.recentEntries(context: modelContext, family: families.first)
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    L10n.auditEmptyTitle,
                    systemImage: "list.bullet.rectangle.portrait",
                    description: Text(L10n.auditEmptyMessage)
                )
            } else {
                List(entries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.subheadline.weight(.medium))
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(entry.actorName)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .navigationTitle(L10n.moreAuditLog)
    }
}

struct ActingAsMemberView: View {
    @Environment(AppState.self) private var appState
    @Query private var families: [Family]

    private var members: [FamilyMember] {
        families.first?.members.sorted { $0.displayName < $1.displayName } ?? []
    }

    var body: some View {
        List(members, id: \.id) { member in
            Button {
                appState.currentMemberId = member.id
                appState.currentMemberName = member.displayName
            } label: {
                HStack {
                    CGAvatar(
                        name: member.displayName,
                        genmojiData: member.genmojiData,
                        emoji: member.avatarEmoji,
                        size: 36,
                        showGradientRing: false
                    )
                    VStack(alignment: .leading) {
                        Text(member.displayName)
                        Text(member.role.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if appState.currentMemberId == member.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle(L10n.moreActingAsTitle)
    }
}

struct PermissionsView: View {
    @Query private var families: [Family]

    private var members: [FamilyMember] {
        families.first?.members.sorted { $0.displayName < $1.displayName } ?? []
    }

    var body: some View {
        List {
            Section(L10n.permissionsMembers) {
                if members.isEmpty {
                    Text(L10n.permissionsMembersEmpty)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(members, id: \.id) { member in
                        NavigationLink {
                            MemberPermissionsEditorView(member: member)
                        } label: {
                            HStack(spacing: CGSpacing.sm) {
                                CGAvatar(
                                    name: member.displayName,
                                    genmojiData: member.genmojiData,
                                    emoji: member.avatarEmoji,
                                    size: 36,
                                    showGradientRing: false
                                )
                                VStack(alignment: .leading) {
                                    Text(member.displayName)
                                    Text(member.role.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section(L10n.permissionsDefaultRoles) {
                PermissionRow(role: L10n.permissionsRoleParent, access: L10n.permissionsRoleParentAccess)
                PermissionRow(role: L10n.permissionsRoleGrandparent, access: L10n.permissionsRoleGrandparentAccess)
                PermissionRow(role: L10n.permissionsRoleProfessional, access: L10n.permissionsRoleProfessionalAccess)
            }
        }
        .navigationTitle(L10n.permissionsTitle)
    }
}

struct PermissionRow: View {
    let role: String
    let access: String

    var body: some View {
        HStack {
            Text(role)
            Spacer()
            Text(access)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
