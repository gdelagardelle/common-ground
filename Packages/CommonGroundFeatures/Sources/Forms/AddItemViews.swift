import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct AddChildView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var families: [Family]

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -8, to: Date()) ?? Date()
    @State private var bloodType = ""
    @State private var allergiesText = ""
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section(L10n.formSectionName) {
                    TextField(L10n.onboardingFirstName, text: $firstName)
                        .textContentType(.givenName)
                    TextField(L10n.onboardingLastName, text: $lastName)
                        .textContentType(.familyName)
                }

                Section(L10n.formSectionDetails) {
                    DatePicker(L10n.onboardingDateOfBirth, selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                    TextField(L10n.formBloodTypeOptional, text: $bloodType)
                    TextField(L10n.formAllergiesCommaSeparated, text: $allergiesText)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(L10n.childrenAddChild)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonSave) { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        guard let family = families.first else {
            errorMessage = L10n.formCreateFamilyFirst
            return
        }

        let allergies = allergiesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        do {
            _ = try FamilySetupService.addChild(
                context: modelContext,
                family: family,
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                dateOfBirth: dateOfBirth,
                bloodType: bloodType.nilIfEmpty,
                allergies: allergies
            )
            dismiss()
        } catch {
            errorMessage = L10n.formSaveError
        }
    }
}

public struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Child.firstName) private var children: [Child]

    var preselectedDate: Date

    @State private var title = ""
    @State private var category: EventCategory = .appointment
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isAllDay = false
    @State private var location = ""
    @State private var selectedChildId: UUID?
    @State private var errorMessage: String?

    public init(preselectedDate: Date = Date()) {
        self.preselectedDate = preselectedDate
        _startDate = State(initialValue: preselectedDate)
        _endDate = State(initialValue: Calendar.current.date(byAdding: .hour, value: 1, to: preselectedDate) ?? preselectedDate)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(L10n.formSectionEvent) {
                    TextField(L10n.formTitle, text: $title)
                    Picker(L10n.formCategory, selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

                Section(L10n.formSectionWhen) {
                    Toggle(L10n.calendarAllDay, isOn: $isAllDay)
                    DatePicker(L10n.calendarStart, selection: $startDate, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                    DatePicker(L10n.calendarEnd, selection: $endDate, in: startDate..., displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                }

                Section(L10n.calendarDetails) {
                    if !children.isEmpty {
                        Picker(L10n.commonChild, selection: $selectedChildId) {
                            Text(L10n.formAllChildren).tag(UUID?.none)
                            ForEach(children, id: \.id) { child in
                                Text(child.fullName).tag(Optional(child.id))
                            }
                        }
                    }
                    TextField(L10n.formLocationOptional, text: $location)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(L10n.formNewEvent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonAdd) { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: isAllDay) { _, allDay in
                if allDay {
                    startDate = Calendar.current.startOfDay(for: startDate)
                    endDate = Calendar.current.startOfDay(for: endDate)
                }
            }
        }
    }

    private func save() {
        let child = children.first { $0.id == selectedChildId }
        let resolvedEnd = max(endDate, startDate)

        do {
            _ = try FamilySetupService.addEvent(
                context: modelContext,
                child: child,
                title: title.trimmingCharacters(in: .whitespaces),
                category: category,
                startDate: startDate,
                endDate: resolvedEnd,
                isAllDay: isAllDay,
                location: location
            )
            dismiss()
        } catch {
            errorMessage = L10n.formEventSaveError
        }
    }
}

public struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Child.firstName) private var children: [Child]
    @Query private var families: [Family]

    var preselectedChild: Child?

    @State private var title = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .other
    @State private var selectedChildId: UUID?
    @State private var selectedMemberId: UUID?
    @State private var splitEvenly = true
    @State private var date = Date()
    @State private var notes = ""
    @State private var errorMessage: String?

    public init(preselectedChild: Child? = nil) {
        self.preselectedChild = preselectedChild
        _selectedChildId = State(initialValue: preselectedChild?.id)
    }

    private var members: [FamilyMember] {
        families.first?.members ?? []
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(L10n.formSectionExpense) {
                    TextField(L10n.formDescription, text: $title)
                    TextField(L10n.formAmount, text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker(L10n.formCategory, selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    DatePicker(L10n.formDate, selection: $date, displayedComponents: .date)
                }

                Section(L10n.formSectionSplit) {
                    if !children.isEmpty {
                        Picker(L10n.commonChild, selection: $selectedChildId) {
                            Text(L10n.formGeneral).tag(UUID?.none)
                            ForEach(children, id: \.id) { child in
                                Text(child.firstName).tag(Optional(child.id))
                            }
                        }
                    }

                    if members.isEmpty {
                        Text(L10n.formAddMemberToTrackPaid)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker(L10n.formPaidBy, selection: $selectedMemberId) {
                            ForEach(members, id: \.id) { member in
                                Text(member.displayName).tag(Optional(member.id))
                            }
                        }
                    }

                    Toggle(L10n.formSplit5050, isOn: $splitEvenly)
                }

                Section(L10n.formSectionNotes) {
                    TextField(L10n.formOptionalNotes, text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(L10n.formNewExpense)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonSave) { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if selectedMemberId == nil {
                    selectedMemberId = members.first?.id
                }
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
        && parsedAmount != nil
        && selectedMemberId != nil
    }

    private var parsedAmount: Decimal? {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value > 0 else { return nil }
        return Decimal(value)
    }

    private func save() {
        guard let amount = parsedAmount,
              let memberId = selectedMemberId,
              let member = members.first(where: { $0.id == memberId }) else { return }

        let child = children.first { $0.id == selectedChildId }

        do {
            _ = try FamilySetupService.addExpense(
                context: modelContext,
                child: child,
                title: title.trimmingCharacters(in: .whitespaces),
                amount: amount,
                category: category,
                paidBy: member,
                splitRatio: splitEvenly ? 0.5 : 0.5,
                date: date,
                notes: notes
            )
            dismiss()
        } catch {
            errorMessage = L10n.formExpenseSaveError
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
