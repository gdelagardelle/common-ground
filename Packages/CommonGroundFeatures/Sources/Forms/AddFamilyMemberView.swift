import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct AddFamilyMemberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var families: [Family]

    @State private var displayName = ""
    @State private var email = ""
    @State private var role: MemberRole = .parent
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section(L10n.memberSection) {
                    TextField(L10n.formName, text: $displayName)
                        .textContentType(.name)
                    TextField(L10n.formEmailOptional, text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    Picker(L10n.formRole, selection: $role) {
                        ForEach(MemberRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(L10n.memberAddTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonSave) { save() }
                        .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let family = families.first else {
            errorMessage = L10n.memberNoFamilyError
            return
        }

        let member = FamilyMember(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            role: role,
            email: email.nilIfEmpty
        )
        member.family = family
        family.members.append(member)
        contextInsert(member)
        dismiss()
    }

    private func contextInsert(_ member: FamilyMember) {
        modelContext.insert(member)
        do {
            try modelContext.save()
        } catch {
            errorMessage = L10n.memberSaveError
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
