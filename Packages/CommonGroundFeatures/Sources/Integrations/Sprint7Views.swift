import SwiftUI
import SwiftData
import MapKit
import CommonGroundCore
import CommonGroundDesign

// MARK: - School Portal

public struct SchoolPortalView: View {
    let child: Child

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPortal: SchoolPortalType = SchoolPortalPreferences.connectedPortal ?? .classDojo
    @State private var isSyncing = false
    @State private var syncResult: SchoolPortalSyncResult?
    @State private var errorMessage: String?

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        List {
            Section {
                Label(L10n.schoolPortalComingSoon, systemImage: "clock.badge.exclamationmark")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            Section {
                Text(L10n.schoolPortalIntro)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.schoolPortalSectionPortal) {
                Picker(L10n.schoolPortalService, selection: $selectedPortal) {
                    ForEach(SchoolPortalType.allCases, id: \.self) { portal in
                        Label(portal.displayName, systemImage: portal.icon).tag(portal)
                    }
                }

                Button(L10n.schoolPortalConnect) {
                    SchoolPortalService.connect(selectedPortal)
                }
                .disabled(true)

                if SchoolPortalPreferences.connectedPortal != nil {
                    Button(L10n.schoolPortalDisconnect, role: .destructive) {
                        SchoolPortalService.disconnect()
                        syncResult = nil
                    }
                }
            }

            Section {
                Button {
                    syncPortal()
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
                .disabled(true)
            }

            if let syncResult {
                Section(L10n.calendarSyncLastSync) {
                    LabeledContent(L10n.schoolPortalAnnouncements, value: "\(syncResult.announcementsImported)")
                    LabeledContent(L10n.schoolPortalAssignments, value: "\(syncResult.assignmentsImported)")
                    if let date = SchoolPortalPreferences.lastSyncDate {
                        LabeledContent(L10n.commonTime, value: date.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }

            if !child.schoolAnnouncements.isEmpty {
                Section(L10n.schoolPortalSectionAnnouncements) {
                    ForEach(child.schoolAnnouncements.sorted(by: { $0.publishedAt > $1.publishedAt }), id: \.id) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.title)
                                    .font(.subheadline.weight(.medium))
                                if !item.isRead {
                                    Circle().fill(Color.accentColor).frame(width: 8, height: 8)
                                }
                            }
                            Text(item.body)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.publishedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .onAppear {
                            if !item.isRead {
                                try? SchoolSetupService.markAnnouncementRead(item, context: modelContext)
                            }
                        }
                    }
                }
            }

            if !child.schoolAssignments.isEmpty {
                Section(L10n.schoolPortalSectionHomework) {
                    ForEach(child.schoolAssignments.sorted(by: { $0.dueDate < $1.dueDate }), id: \.id) { assignment in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(assignment.title)
                                    .font(.subheadline.weight(.medium))
                                    .strikethrough(assignment.isCompleted)
                                if let subject = assignment.subject {
                                    Text(subject)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(L10n.format("schoolPortal.due", assignment.dueDate.formatted(date: .abbreviated, time: .omitted)))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            if !assignment.isCompleted {
                                Button(L10n.commonDone) {
                                    try? SchoolSetupService.markAssignmentComplete(assignment, context: modelContext)
                                }
                                .font(.caption.weight(.semibold))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(L10n.moreSchoolPortal)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func syncPortal() {
        isSyncing = true
        errorMessage = nil
        SchoolPortalService.connect(selectedPortal)

        do {
            syncResult = try SchoolPortalService.sync(context: modelContext, child: child, portal: selectedPortal)
        } catch {
            errorMessage = L10n.schoolPortalSyncError
        }
        isSyncing = false
    }
}

public struct AddSchoolInfoView: View {
    let child: Child

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var schoolName = ""
    @State private var grade = ""
    @State private var classroom = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var errorMessage: String?

    public init(child: Child) {
        self.child = child
        if let school = child.schoolInfo {
            _schoolName = State(initialValue: school.schoolName)
            _grade = State(initialValue: school.grade ?? "")
            _classroom = State(initialValue: school.classroom ?? "")
            _phone = State(initialValue: school.schoolPhone ?? "")
            _address = State(initialValue: school.schoolAddress ?? "")
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(L10n.schoolSection) {
                    TextField(L10n.schoolSchoolName, text: $schoolName)
                    TextField(L10n.schoolGrade, text: $grade)
                    TextField(L10n.schoolClassroom, text: $classroom)
                    TextField(L10n.schoolPhone, text: $phone)
                        .keyboardType(.phonePad)
                    TextField(L10n.schoolAddress, text: $address)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(child.schoolInfo == nil ? L10n.schoolAdd : L10n.schoolEdit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonSave) { save() }
                        .disabled(schoolName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        do {
            _ = try SchoolSetupService.addOrUpdateSchoolInfo(
                context: modelContext,
                child: child,
                schoolName: schoolName.trimmingCharacters(in: .whitespaces),
                grade: grade,
                classroom: classroom,
                phone: phone,
                address: address
            )
            dismiss()
        } catch {
            errorMessage = L10n.schoolSaveError
        }
    }
}

// MARK: - Exchange Location

public struct ExchangeLocationShareView: View {
    let event: CalendarEvent
    let memberName: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isSharing = false
    @State private var errorMessage: String?
    @State private var mapPosition: MapCameraPosition = .automatic

    public init(event: CalendarEvent, memberName: String) {
        self.event = event
        self.memberName = memberName
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(L10n.exchangeIntro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section(L10n.custodyExchange) {
                    LabeledContent(L10n.exchangeWhen, value: event.startDate.formatted(date: .abbreviated, time: .shortened))
                    if let location = event.location {
                        LabeledContent(L10n.exchangeMeetAt, value: location)
                    }
                }

                if event.hasSharedLocation, let latitude = event.latitude, let longitude = event.longitude {
                    Section(L10n.exchangeSharedLocation) {
                        Map(position: $mapPosition) {
                            Marker("Exchange", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        }
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: CGRadius.md))
                        .onAppear {
                            mapPosition = .region(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            ))
                        }

                        if let name = event.sharedLocationMemberName, let sharedAt = event.sharedLocationAt {
                            Text(L10n.format("exchange.sharedBy", name, sharedAt.formatted(date: .omitted, time: .shortened)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let url = event.mapsURL {
                            Link(destination: url) {
                                Label(L10n.exchangeOpenInMaps, systemImage: "map")
                            }
                        }
                    }
                }

                Section {
                    Button {
                        shareLocation()
                    } label: {
                        HStack {
                            Spacer()
                            if isSharing {
                                ProgressView()
                            } else {
                                Label(event.hasSharedLocation ? L10n.exchangeUpdateLocation : L10n.exchangeShareMyLocation, systemImage: "location.fill")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSharing)
                }

                Section {
                    Toggle(L10n.exchangeAutoShare, isOn: Binding(
                        get: { ExchangeLocationPreferences.autoShareEnabled },
                        set: { ExchangeLocationPreferences.autoShareEnabled = $0 }
                    ))
                } footer: {
                    Text(L10n.exchangeAutoShareFooter)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(L10n.exchangeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone) { dismiss() }
                }
            }
        }
    }

    private func shareLocation() {
        isSharing = true
        errorMessage = nil

        Task {
            do {
                try await ExchangeLocationManager.shareLocation(
                    for: event,
                    memberName: memberName,
                    context: modelContext
                )
                if event.location == nil || event.location?.isEmpty == true,
                   let lat = event.latitude, let lon = event.longitude,
                   let label = await ExchangeLocationManager.reverseGeocode(latitude: lat, longitude: lon) {
                    event.location = label
                    try? modelContext.save()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSharing = false
        }
    }
}

public struct ExchangeLocationBanner: View {
    let event: CalendarEvent
    let onShare: () -> Void

    public init(event: CalendarEvent, onShare: @escaping () -> Void) {
        self.event = event
        self.onShare = onShare
    }

    public var body: some View {
        CGCard(padding: CGSpacing.sm) {
            HStack(spacing: CGSpacing.sm) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.format("exchange.banner.in", event.startDate.formatted(date: .omitted, time: .shortened)))
                        .font(.subheadline.weight(.semibold))
                    if event.hasSharedLocation, let name = event.sharedLocationMemberName {
                        Text(L10n.format("exchange.banner.sharedBy", name))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(L10n.exchangeBannerPrompt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(event.hasSharedLocation ? L10n.commonView : L10n.commonShare, action: onShare)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
    }
}
