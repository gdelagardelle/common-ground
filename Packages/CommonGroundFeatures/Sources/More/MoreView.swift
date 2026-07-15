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
                Section("Family Tools") {
                    Button {
                        showAddExpense = true
                    } label: {
                        Label("Add Expense", systemImage: "dollarsign.circle")
                    }

                    Button {
                        showAddMember = true
                    } label: {
                        Label("Add Co-Parent", systemImage: "person.badge.plus")
                    }

                    NavigationLink { ChecklistsView(checklists: checklists) } label: {
                        Label("Checklists", systemImage: "checklist")
                    }
                    NavigationLink { AuditLogView() } label: {
                        Label("Audit Log", systemImage: "list.bullet.rectangle.portrait")
                    }
                    NavigationLink { ExportView() } label: {
                        Label("Court Export", systemImage: "doc.text.magnifyingglass")
                    }

                    NavigationLink { CustodyAgreementsListView() } label: {
                        Label("Custody Agreements", systemImage: "signature")
                    }
                }

                Section("Professional Access") {
                    NavigationLink { ProfessionalPortalView() } label: {
                        Label("Professional Portal", systemImage: "briefcase.fill")
                    }
                    Text("Add an attorney or GAL as a family member with the Professional role for read-only access.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Integrations") {
                    Button {
                        showCalendarImport = true
                    } label: {
                        Label("Apple Calendar Sync", systemImage: "calendar.badge.clock")
                    }

                    Button {
                        showInvite = true
                    } label: {
                        Label("Invite Co-Parent", systemImage: "person.2.badge.gearshape")
                    }

                    Button {
                        showJoinFamily = true
                    } label: {
                        Label("Join Family", systemImage: "person.2.fill")
                    }

                    NavigationLink { SyncSettingsView() } label: {
                        Label("iCloud Sync", systemImage: "icloud")
                    }

                    Button {
                        showHealthImport = true
                    } label: {
                        Label("Apple Health", systemImage: "heart.text.square")
                    }

                    if let child = children.first {
                        NavigationLink {
                            SchoolPortalView(child: child)
                        } label: {
                            Label("School Portal", systemImage: "building.columns.fill")
                        }
                    }
                }

                Section {
                    Toggle(isOn: lockEnabledBinding) {
                        Label("Require \(security.lockMethodDescription)", systemImage: lockIcon)
                    }

                    if security.isLockEnabled {
                        Button("Lock Now") {
                            security.lock()
                        }
                    }

                    Toggle(isOn: $notificationsEnabled) {
                        Label("Reminders", systemImage: "bell.badge")
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
                        Label("Permissions", systemImage: "person.badge.shield.checkmark")
                    }
                } header: {
                    Text("Privacy & Security")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if security.isLockEnabled {
                            Text("You'll be asked to unlock when opening the app and after tapping Lock Now.")
                        } else {
                            Text("Lock is off. Turn this on to require \(security.lockMethodDescription) before viewing family data.")
                        }
                        Text(notificationsEnabled
                             ? "Reminders are scheduled for custody exchanges and medications."
                             : "Enable reminders for custody exchanges and medications.")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Sync", value: SyncPreferences.isCloudKitEnabled ? "iCloud" : "Local")
                }
            }
            .navigationTitle("More")
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

                Text("\(checklist.completedCount) of \(checklist.items.count) complete")
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
        .navigationTitle("Checklists")
    }
}

struct AuditLogView: View {
    private let entries = [
        ("Message sent", "Today 2:34 PM", "Sarah"),
        ("Expense added", "Today 10:15 AM", "Michael"),
        ("Calendar updated", "Yesterday", "Sarah"),
        ("Document uploaded", "Mar 10", "Sarah"),
    ]

    var body: some View {
        List(entries, id: \.0) { entry in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.0)
                        .font(.subheadline.weight(.medium))
                    Text(entry.1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(entry.2)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .navigationTitle("Audit Log")
    }
}

struct PermissionsView: View {
    var body: some View {
        List {
            Section("Role Permissions") {
                PermissionRow(role: "Parent", access: "Full access")
                PermissionRow(role: "Grandparent", access: "View only (no messaging)")
                PermissionRow(role: "Professional", access: "Read-only export")
            }

            Section {
                Text("Invite family members and set granular permissions per module.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Permissions")
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
