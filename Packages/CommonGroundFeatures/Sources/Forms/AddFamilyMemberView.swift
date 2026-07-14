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
                Section("Member") {
                    TextField("Name", text: $displayName)
                        .textContentType(.name)
                    TextField("Email (optional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    Picker("Role", selection: $role) {
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
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let family = families.first else {
            errorMessage = "No family found."
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
            errorMessage = "Couldn't save member."
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
