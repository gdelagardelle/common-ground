import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct MemberPermissionsEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let member: FamilyMember

    @State private var permissions: MemberPermissions
    @State private var showSaved = false

    public init(member: FamilyMember) {
        self.member = member
        _permissions = State(initialValue: member.permissions)
    }

    public var body: some View {
        Form {
            Section {
                HStack(spacing: CGSpacing.md) {
                    Text(member.avatarEmoji)
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text(member.displayName)
                            .font(.headline)
                        Text(member.role.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("What they can see") {
                moduleToggle(.calendar, keyPath: \.canViewCalendar)
                moduleToggle(.expenses, keyPath: \.canViewExpenses)
                moduleToggle(.medical, keyPath: \.canViewMedical)
                moduleToggle(.messages, keyPath: \.canViewMessages)
                moduleToggle(.timeline, keyPath: \.canViewTimeline)
                moduleToggle(.school, keyPath: \.canViewSchool)
                moduleToggle(.documents, keyPath: \.canViewDocuments)
                moduleToggle(.emergency, keyPath: \.canViewEmergency)
            }

            Section("What they can change") {
                editToggle("Edit calendar", icon: "calendar.badge.plus", enabled: permissions.canViewCalendar, keyPath: \.canEditCalendar)
                editToggle("Add expenses", icon: "dollarsign.circle", enabled: permissions.canViewExpenses, keyPath: \.canEditExpenses)
                editToggle("Edit medical", icon: "cross.case", enabled: permissions.canViewMedical, keyPath: \.canEditMedical)
                editToggle("Send messages", icon: "bubble.left", enabled: permissions.canViewMessages, keyPath: \.canSendMessages)
                Toggle(isOn: $permissions.canExportRecords) {
                    Label("Court export", systemImage: "doc.richtext")
                }
            }

            Section {
                Button("Reset to \(member.role.displayName) defaults") {
                    permissions = MemberPermissions.default(for: member.role)
                    persist()
                }
            }

            Section {
                Text("Hide modules a grandparent or caregiver shouldn't see. View access must be on before edit access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Access")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: permissions) { old, new in
            guard old != new else { return }
            normalizeEditPermissions()
            persist()
            flashSaved()
        }
    }

    private func moduleToggle(_ module: PermissionModule, keyPath: WritableKeyPath<MemberPermissions, Bool>) -> some View {
        Toggle(isOn: binding(keyPath)) {
            Label(module.title, systemImage: module.icon)
        }
    }

    private func editToggle(
        _ title: String,
        icon: String,
        enabled: Bool,
        keyPath: WritableKeyPath<MemberPermissions, Bool>
    ) -> some View {
        Toggle(isOn: binding(keyPath)) {
            Label(title, systemImage: icon)
        }
        .disabled(!enabled)
    }

    private func binding(_ keyPath: WritableKeyPath<MemberPermissions, Bool>) -> Binding<Bool> {
        Binding(
            get: { permissions[keyPath: keyPath] },
            set: { permissions[keyPath: keyPath] = $0 }
        )
    }

    private func normalizeEditPermissions() {
        if !permissions.canViewCalendar { permissions.canEditCalendar = false }
        if !permissions.canViewExpenses { permissions.canEditExpenses = false }
        if !permissions.canViewMedical { permissions.canEditMedical = false }
        if !permissions.canViewMessages { permissions.canSendMessages = false }
    }

    private func persist() {
        member.permissions = permissions
        try? modelContext.save()
    }

    private func flashSaved() {
        showSaved = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            showSaved = false
        }
    }
}
