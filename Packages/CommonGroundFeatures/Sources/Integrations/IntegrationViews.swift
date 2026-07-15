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
    @State private var exportDestination = CalendarSyncPreferences.exportDestination
    @State private var exportTargetId = CalendarSyncPreferences.exportTargetCalendarIdentifier
    @State private var writableCalendars: [WritableCalendarInfo] = []
    @State private var isSyncing = false
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var syncResult: CalendarSyncResult?
    @State private var accessDenied = false
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(L10n.calendarSyncIntro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section(L10n.calendarSyncSettings) {
                    Toggle(L10n.calendarSyncAutoSync, isOn: $autoSync)
                        .onChange(of: autoSync) { _, value in
                            CalendarSyncPreferences.isAutoSyncEnabled = value
                        }

                    Toggle(L10n.calendarSyncExportAll, isOn: $exportAllEvents)
                        .onChange(of: exportAllEvents) { _, value in
                            CalendarSyncPreferences.exportAllEvents = value
                        }

                    if !exportAllEvents {
                        Text(L10n.calendarSyncExportAllHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !children.isEmpty {
                        Picker(L10n.calendarSyncImportAssign, selection: $selectedChildId) {
                            Text(L10n.calendarSyncNoChild).tag(UUID?.none)
                            ForEach(children, id: \.id) { child in
                                Text(child.firstName).tag(Optional(child.id))
                            }
                        }
                    }

                    Stepper(L10n.format("calendarSync.syncWindow", daysAhead), value: $daysAhead, in: 30...180, step: 30)
                }

                Section(L10n.calendarSyncExportTitle) {
                    Text(L10n.calendarSyncExportHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker(L10n.calendarSyncExportDestination, selection: $exportDestination) {
                        Text(L10n.calendarSyncExportDedicated).tag(CalendarExportDestination.dedicated)
                        Text(L10n.calendarSyncExportExisting).tag(CalendarExportDestination.existing)
                    }
                    .onChange(of: exportDestination) { _, value in
                        CalendarSyncPreferences.exportDestination = value
                    }

                    if exportDestination == .existing {
                        if writableCalendars.isEmpty {
                            Text(L10n.calendarSyncNoCalendars)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker(L10n.calendarSyncExportChoose, selection: $exportTargetId) {
                                Text(L10n.commonNone).tag(String?.none)
                                ForEach(writableCalendars) { calendar in
                                    Text(calendar.displayTitle).tag(Optional(calendar.id))
                                }
                            }
                            .onChange(of: exportTargetId) { _, value in
                                CalendarSyncPreferences.exportTargetCalendarIdentifier = value
                            }
                        }
                    }

                    Button {
                        exportNow()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                            } else {
                                Label(L10n.calendarSyncExportNow, systemImage: "square.and.arrow.up")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isExporting || (exportDestination == .existing && exportTargetId == nil))
                }

                Section(L10n.calendarSyncImportTitle) {
                    Button {
                        importNow()
                    } label: {
                        HStack {
                            Spacer()
                            if isImporting {
                                ProgressView()
                            } else {
                                Label(L10n.calendarSyncImportNow, systemImage: "square.and.arrow.down")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isImporting)
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
                                Label(L10n.calendarSyncSyncNow, systemImage: "arrow.triangle.2.circlepath")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSyncing)
                }

                if let syncResult {
                    Section(L10n.calendarSyncLastSync) {
                        LabeledContent(L10n.calendarSyncExported, value: "\(syncResult.exported)")
                        LabeledContent(L10n.calendarSyncUpdated, value: "\(syncResult.updated)")
                        LabeledContent(L10n.calendarSyncImported, value: "\(syncResult.imported)")
                        if let lastSync = CalendarSyncPreferences.lastSyncDate {
                            LabeledContent(L10n.calendarSyncTime, value: lastSync.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }

                if accessDenied {
                    Section {
                        Text(L10n.calendarSyncAccessDenied)
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
            .navigationTitle(L10n.calendarSyncTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone) { dismiss() }
                }
            }
            .task {
                await refreshCalendars()
            }
        }
    }

    private func refreshCalendars() async {
        guard await CalendarSyncService.requestAccess() else { return }
        writableCalendars = CalendarSyncService.writableCalendars()
        if exportTargetId == nil {
            exportTargetId = writableCalendars.first?.id
            CalendarSyncPreferences.exportTargetCalendarIdentifier = exportTargetId
        }
    }

    private func syncNow() {
        runTask(flag: .sync) {
            syncResult = try await CalendarSyncService.performFullSync(
                context: modelContext,
                child: children.first { $0.id == selectedChildId },
                daysAhead: daysAhead
            )
        }
    }

    private func exportNow() {
        runTask(flag: .export) {
            syncResult = try await CalendarSyncService.exportOnly(context: modelContext)
        }
    }

    private func importNow() {
        runTask(flag: .importing) {
            syncResult = try await CalendarSyncService.importOnly(
                context: modelContext,
                child: children.first { $0.id == selectedChildId },
                daysAhead: daysAhead
            )
        }
    }

    private enum TaskFlag { case sync, export, importing }

    private func runTask(flag: TaskFlag, operation: @escaping () async throws -> Void) {
        errorMessage = nil
        accessDenied = false
        switch flag {
        case .sync: isSyncing = true
        case .export: isExporting = true
        case .importing: isImporting = true
        }

        Task {
            let granted = await CalendarSyncService.requestAccess()
            guard granted else {
                accessDenied = true
                isSyncing = false
                isExporting = false
                isImporting = false
                return
            }

            if flag == .export || flag == .sync {
                writableCalendars = CalendarSyncService.writableCalendars()
            }

            do {
                try await operation()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSyncing = false
            isExporting = false
            isImporting = false
        }
    }
}

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
            return L10n.inviteDefaultBody
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
                    Text(L10n.inviteIntro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let family {
                    Section(L10n.inviteSectionFamilyCode) {
                        Text(String(family.id.uuidString.prefix(8)).uppercased())
                            .font(.title2.weight(.bold))
                            .monospaced()
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(L10n.inviteFamilyCodeHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(L10n.inviteSectionSendInvite) {
                    TextField(L10n.inviteCoParentEmail, text: $coParentEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)

                    Button {
                        showShare = true
                    } label: {
                        Label(L10n.inviteShareInvite, systemImage: "square.and.arrow.up")
                    }

                    if !coParentEmail.isEmpty, let url = InviteService.mailtoURL(
                        email: coParentEmail,
                        subject: L10n.inviteEmailSubject,
                        body: inviteBody
                    ) {
                        Link(destination: url) {
                            Label(L10n.inviteSendEmail, systemImage: "envelope")
                        }
                    }
                }
            }
            .navigationTitle(L10n.inviteTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonDone) { dismiss() }
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
    @State private var showCloudShare = false
    @State private var shareError: String?
    @State private var isMigrating = false
    @State private var migrationMessage: String?

    public init() {}

    public var body: some View {
        Form {
            Section {
                Toggle(L10n.moreICloudSync, isOn: $cloudKitEnabled)
                    .disabled(isMigrating)
                    .onChange(of: cloudKitEnabled) { _, newValue in
                        Task { await handleCloudKitToggle(enabled: newValue) }
                    }
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.syncFooter)
                    if !SyncPreferences.isCloudSyncActive {
                        Text(L10n.syncMigrationFooter)
                    }
                }
            }

            if isMigrating {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(L10n.syncMigrating)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let migrationMessage {
                Section {
                    Label(migrationMessage, systemImage: "checkmark.icloud")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Section(L10n.syncSectionStatus) {
                LabeledContent(L10n.syncCurrentMode, value: currentModeLabel)
                LabeledContent(L10n.syncCloudKit, value: CloudKitShareService.statusMessage)
                if CloudKitCapability.isConfigured {
                    Label(L10n.cloudStatusCapabilityReady, systemImage: "checkmark.icloud")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Section(L10n.syncSectionCoParentSharing) {
                Button {
                    showCloudShare = true
                } label: {
                    Label(L10n.syncShareFamily, systemImage: "person.2.crop.square.stack")
                }
                .disabled(families.isEmpty || !CloudKitShareService.canShare)

                if !CloudKitShareService.isSignedInToiCloud {
                    Text(L10n.syncSignInRequired)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !SyncPreferences.isCloudKitEnabled {
                    Text(L10n.syncEnableFirst)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(L10n.syncInviteAppleID)
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
                Text(L10n.syncFamilyCodeNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.moreSync)
        .background {
            #if canImport(CloudKit) && canImport(UIKit)
            if let family = families.first {
                CloudSharingView(
                    family: family,
                    modelContext: modelContext,
                    isPresented: $showCloudShare,
                    shareError: $shareError
                )
                .frame(width: 0, height: 0)
            }
            #endif
        }
        .onAppear {
            cloudKitEnabled = SyncPreferences.isCloudKitEnabled
            migrationMessage = positiveMigrationSummary
        }
        .onChange(of: PersistenceReloadCoordinator.shared.generation) { _, _ in
            cloudKitEnabled = SyncPreferences.isCloudKitEnabled
            isMigrating = false
            migrationMessage = positiveMigrationSummary
            if !SyncPreferences.isCloudKitEnabled, let summary = SyncPreferences.lastMigrationSummary {
                shareError = summary
            }
        }
    }

    private var positiveMigrationSummary: String? {
        guard let summary = SyncPreferences.lastMigrationSummary else { return nil }
        if summary.localizedCaseInsensitiveContains("failed") || summary.localizedCaseInsensitiveContains("fehlgeschlagen") {
            return nil
        }
        return summary
    }

    private var currentModeLabel: String {
        if SyncPreferences.isCloudSyncActive {
            L10n.syncModeICloudActive
        } else if SyncPreferences.isCloudKitEnabled {
            L10n.syncModeICloudPending
        } else {
            L10n.syncModeLocal
        }
    }

    @MainActor
    private func handleCloudKitToggle(enabled: Bool) async {
        shareError = nil
        migrationMessage = nil
        SyncPreferences.lastMigrationSummary = nil

        guard enabled else {
            SyncPreferences.isCloudKitEnabled = false
            CloudKitMigrationService.isMigrationCompleted = false
            isMigrating = true
            PersistenceReloadCoordinator.shared.requestReload()
            try? await Task.sleep(nanoseconds: 800_000_000)
            isMigrating = false
            cloudKitEnabled = false
            return
        }

        guard CloudKitCapability.isConfigured else {
            cloudKitEnabled = false
            shareError = L10n.cloudErrorUnavailable
            return
        }

        guard CloudKitShareService.isSignedInToiCloud else {
            cloudKitEnabled = false
            shareError = L10n.cloudErrorNotSignedIn
            return
        }

        isMigrating = true
        PersistenceBackupService.createBackup(label: "pre-cloud-toggle")
        SyncPreferences.isCloudKitEnabled = true
        PersistenceReloadCoordinator.shared.requestReload()
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        isMigrating = false
        cloudKitEnabled = SyncPreferences.isCloudKitEnabled
        migrationMessage = positiveMigrationSummary

        if !SyncPreferences.isCloudKitEnabled {
            shareError = SyncPreferences.lastMigrationSummary ?? L10n.syncMigrationFailedGeneric
        }
    }
}
