import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct CalendarSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Child.firstName) private var children: [Child]

    @State private var selectedChildId: UUID?
    @State private var daysAhead = 90
    @State private var autoSync = CalendarSyncPreferences.isAutoSyncEnabled
    @State private var exportAllEvents = CalendarSyncPreferences.exportAllEvents
    @State private var isSyncing = false
    @State private var syncResult: CalendarSyncResult?
    @State private var accessDenied = false
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Keep custody schedules in sync with Apple Calendar. Common Ground creates a dedicated calendar and exports your events while importing new ones from your other calendars.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Sync Settings") {
                    Toggle("Auto-sync on launch", isOn: $autoSync)
                        .onChange(of: autoSync) { _, value in
                            CalendarSyncPreferences.isAutoSyncEnabled = value
                        }

                    Toggle("Export all events", isOn: $exportAllEvents)
                        .onChange(of: exportAllEvents) { _, value in
                            CalendarSyncPreferences.exportAllEvents = value
                        }

                    if !exportAllEvents {
                        Text("When off, only custody and exchange events are exported.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !children.isEmpty {
                        Picker("Import assign to", selection: $selectedChildId) {
                            Text("No specific child").tag(UUID?.none)
                            ForEach(children, id: \.id) { child in
                                Text(child.firstName).tag(Optional(child.id))
                            }
                        }
                    }

                    Stepper("Sync window: \(daysAhead) days", value: $daysAhead, in: 30...180, step: 30)
                }

                Section {
                    Button {
                        syncNow()
                    } label: {
                        HStack {
                            Spacer()
                            if isSyncing {
                                ProgressView()
                            } else {
                                Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSyncing)
                }

                if let syncResult {
                    Section("Last Sync") {
                        LabeledContent("Exported", value: "\(syncResult.exported)")
                        LabeledContent("Updated", value: "\(syncResult.updated)")
                        LabeledContent("Imported", value: "\(syncResult.imported)")
                        if let lastSync = CalendarSyncPreferences.lastSyncDate {
                            LabeledContent("Time", value: lastSync.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }

                if accessDenied {
                    Section {
                        Text("Calendar access was denied. Enable it in Settings → Common Ground → Calendars.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Apple Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func syncNow() {
        isSyncing = true
        errorMessage = nil
        syncResult = nil
        accessDenied = false

        Task {
            let granted = await CalendarSyncService.requestAccess()
            guard granted else {
                accessDenied = true
                isSyncing = false
                return
            }

            let child = children.first { $0.id == selectedChildId }
            do {
                syncResult = try await CalendarSyncService.performFullSync(
                    context: modelContext,
                    child: child,
                    daysAhead: daysAhead
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isSyncing = false
        }
    }
}

// Backward-compatible alias
public typealias CalendarImportView = CalendarSyncView

public struct InviteCoParentView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var families: [Family]
    @Environment(AppState.self) private var appState

    @State private var coParentEmail = ""
    @State private var showShare = false

    public init() {}

    private var family: Family? { families.first }

    private var inviteBody: String {
        guard let family, let inviter = family.members.first(where: { $0.id == appState.currentMemberId }) ?? family.members.first else {
            return "Join me on Common Ground for co-parenting."
        }
        return InviteService.inviteMessage(
            familyName: family.name,
            inviterName: inviter.displayName,
            familyId: family.id
        )
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Invite your co-parent to share custody schedules, expenses, and messages.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let family {
                    Section("Family Code") {
                        Text(String(family.id.uuidString.prefix(8)).uppercased())
                            .font(.title2.weight(.bold))
                            .monospaced()
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("Your co-parent can enter this code when they sign up.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Send Invite") {
                    TextField("Co-parent email (optional)", text: $coParentEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)

                    Button {
                        showShare = true
                    } label: {
                        Label("Share Invite", systemImage: "square.and.arrow.up")
                    }

                    if !coParentEmail.isEmpty, let url = InviteService.mailtoURL(
                        email: coParentEmail,
                        subject: "Join our family on Common Ground",
                        body: inviteBody
                    ) {
                        Link(destination: url) {
                            Label("Send Email", systemImage: "envelope")
                        }
                    }
                }
            }
            .navigationTitle("Invite Co-Parent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            #if canImport(UIKit)
            .sheet(isPresented: $showShare) {
                ShareSheet(items: [inviteBody, InviteService.inviteURL(familyId: family?.id ?? UUID())])
            }
            #endif
        }
    }
}

public struct SyncSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var families: [Family]

    @State private var cloudKitEnabled = SyncPreferences.isCloudKitEnabled
    @State private var showRestartNotice = false
    @State private var showCloudShare = false
    @State private var shareError: String?

    public init() {}

    public var body: some View {
        Form {
            Section {
                Toggle("iCloud Sync", isOn: $cloudKitEnabled)
                    .onChange(of: cloudKitEnabled) { _, newValue in
                        SyncPreferences.isCloudKitEnabled = newValue
                        showRestartNotice = true
                    }
            } footer: {
                Text("Sync family data across your devices via iCloud. Requires an iCloud account and app restart.")
            }

            if showRestartNotice {
                Section {
                    Label(SyncPreferences.requiresRestartMessage, systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("Status") {
                LabeledContent("Current Mode", value: SyncPreferences.isCloudKitEnabled ? "iCloud (pending restart)" : "Local only")
                LabeledContent("CloudKit", value: CloudKitShareService.statusMessage)
            }

            Section("Co-Parent Sharing") {
                Button {
                    showCloudShare = true
                } label: {
                    Label("Share Family via iCloud", systemImage: "person.2.crop.square.stack")
                }
                .disabled(families.isEmpty || !CloudKitShareService.canShare)

                if !CloudKitShareService.isSignedInToiCloud {
                    Text("Sign in to iCloud to share with your co-parent in real time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !SyncPreferences.isCloudKitEnabled {
                    Text("Enable iCloud Sync above and restart the app before sharing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Invite your co-parent's Apple ID. They'll see family data sync in their Common Ground app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let shareError {
                Section {
                    Text(shareError).font(.caption).foregroundStyle(.red)
                }
            }

            Section {
                Text("Family code join works on the same device. iCloud sharing syncs across devices in real time when CloudKit is enabled in Xcode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sync")
        .background {
            #if canImport(CloudKit) && canImport(UIKit)
            if let family = families.first {
                CloudSharingView(
                    family: family,
                    modelContext: modelContext,
                    isPresented: $showCloudShare
                )
                .frame(width: 0, height: 0)
            }
            #endif
        }
    }
}
