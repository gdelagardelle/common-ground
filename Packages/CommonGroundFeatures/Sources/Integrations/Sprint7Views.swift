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
                Text("Connect your school's portal to pull announcements and homework into Common Ground. API integrations coming soon — sync now loads sample data for your school profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Portal") {
                Picker("Service", selection: $selectedPortal) {
                    ForEach(SchoolPortalType.allCases, id: \.self) { portal in
                        Label(portal.displayName, systemImage: portal.icon).tag(portal)
                    }
                }

                Button("Connect") {
                    SchoolPortalService.connect(selectedPortal)
                }

                if SchoolPortalPreferences.connectedPortal != nil {
                    Button("Disconnect", role: .destructive) {
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
                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        }
                        Spacer()
                    }
                }
                .disabled(isSyncing)
            }

            if let syncResult {
                Section("Last Sync") {
                    LabeledContent("Announcements", value: "\(syncResult.announcementsImported)")
                    LabeledContent("Assignments", value: "\(syncResult.assignmentsImported)")
                    if let date = SchoolPortalPreferences.lastSyncDate {
                        LabeledContent("Time", value: date.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }

            if !child.schoolAnnouncements.isEmpty {
                Section("Announcements") {
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
                Section("Homework") {
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
                                Text("Due \(assignment.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            if !assignment.isCompleted {
                                Button("Done") {
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
        .navigationTitle("School Portal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func syncPortal() {
        isSyncing = true
        errorMessage = nil
        SchoolPortalService.connect(selectedPortal)

        do {
            syncResult = try SchoolPortalService.sync(context: modelContext, child: child, portal: selectedPortal)
        } catch {
            errorMessage = "Sync failed. Please try again."
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
                Section("School") {
                    TextField("School name", text: $schoolName)
                    TextField("Grade", text: $grade)
                    TextField("Classroom", text: $classroom)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(child.schoolInfo == nil ? "Add School" : "Edit School")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
            errorMessage = "Couldn't save school info."
        }
    }
}

// MARK: - Exchange Location

public struct ExchangeLocationShareView: View {
    let event: CalendarEvent

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var isSharing = false
    @State private var errorMessage: String?
    @State private var mapPosition: MapCameraPosition = .automatic

    public init(event: CalendarEvent) {
        self.event = event
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Share your current location with your co-parent for this custody exchange. Location is stored locally and visible in the app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Exchange") {
                    LabeledContent("When", value: event.startDate.formatted(date: .abbreviated, time: .shortened))
                    if let location = event.location {
                        LabeledContent("Meet at", value: location)
                    }
                }

                if event.hasSharedLocation, let latitude = event.latitude, let longitude = event.longitude {
                    Section("Shared Location") {
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
                            Text("Shared by \(name) · \(sharedAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let url = event.mapsURL {
                            Link(destination: url) {
                                Label("Open in Maps", systemImage: "map")
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
                                Label(event.hasSharedLocation ? "Update Location" : "Share My Location", systemImage: "location.fill")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSharing)
                }

                Section {
                    Toggle("Auto-share before exchanges", isOn: Binding(
                        get: { ExchangeLocationPreferences.autoShareEnabled },
                        set: { ExchangeLocationPreferences.autoShareEnabled = $0 }
                    ))
                } footer: {
                    Text("When enabled, you'll be prompted to share location when an exchange is within 4 hours.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Exchange Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func shareLocation() {
        isSharing = true
        errorMessage = nil
        let memberName = appState.currentMemberName ?? "Parent"

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
                    Text("Exchange in \(event.startDate.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline.weight(.semibold))
                    if event.hasSharedLocation, let name = event.sharedLocationMemberName {
                        Text("Location shared by \(name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Share your location with your co-parent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(event.hasSharedLocation ? "View" : "Share", action: onShare)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
    }
}
