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
                    CGAvatar(
                        name: member.displayName,
                        genmojiData: member.genmojiData,
                        emoji: member.avatarEmoji,
                        size: 52
                    )
                    VStack(alignment: .leading) {
                        Text(member.displayName)
                            .font(.headline)
                        Text(member.role.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    NavigationLink {
                        MemberAvatarEditorView(member: member)
                    } label: {
                        Text(L10n.permissionsGenmoji)
                            .font(.caption.weight(.medium))
                    }
                }
            }

            Section(L10n.permissionsWhatTheySee) {
                moduleToggle(.calendar, keyPath: \.canViewCalendar)
                moduleToggle(.expenses, keyPath: \.canViewExpenses)
                moduleToggle(.medical, keyPath: \.canViewMedical)
                moduleToggle(.messages, keyPath: \.canViewMessages)
                moduleToggle(.timeline, keyPath: \.canViewTimeline)
                moduleToggle(.school, keyPath: \.canViewSchool)
                moduleToggle(.documents, keyPath: \.canViewDocuments)
                moduleToggle(.emergency, keyPath: \.canViewEmergency)
            }

            Section(L10n.permissionsWhatTheyChange) {
                editToggle(L10n.permissionsEditCalendar, icon: "calendar.badge.plus", enabled: permissions.canViewCalendar, keyPath: \.canEditCalendar)
                editToggle(L10n.permissionsAddExpenses, icon: "dollarsign.circle", enabled: permissions.canViewExpenses, keyPath: \.canEditExpenses)
                editToggle(L10n.permissionsEditMedical, icon: "cross.case", enabled: permissions.canViewMedical, keyPath: \.canEditMedical)
                editToggle(L10n.permissionsSendMessages, icon: "bubble.left", enabled: permissions.canViewMessages, keyPath: \.canSendMessages)
                Toggle(isOn: $permissions.canExportRecords) {
                    Label(L10n.permissionsCourtExport, systemImage: "doc.richtext")
                }
            }

            Section {
                Button(L10n.format("permissions.resetDefaults", member.role.displayName)) {
                    permissions = MemberPermissions.default(for: member.role)
                    persist()
                }
            }

            Section {
                Text(L10n.permissionsFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.permissionsAccessTitle)
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
