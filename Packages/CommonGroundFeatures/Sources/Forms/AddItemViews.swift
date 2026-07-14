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
                Section("Name") {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last name", text: $lastName)
                        .textContentType(.familyName)
                }

                Section("Details") {
                    DatePicker("Date of birth", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                    TextField("Blood type (optional)", text: $bloodType)
                    TextField("Allergies, comma separated", text: $allergiesText)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
            errorMessage = "Create a family first."
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
            errorMessage = "Couldn't save. Please try again."
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
                Section("Event") {
                    TextField("Title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

                Section("When") {
                    Toggle("All day", isOn: $isAllDay)
                    DatePicker("Starts", selection: $startDate, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                    DatePicker("Ends", selection: $endDate, in: startDate..., displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                }

                Section("Details") {
                    if !children.isEmpty {
                        Picker("Child", selection: $selectedChildId) {
                            Text("All children").tag(UUID?.none)
                            ForEach(children, id: \.id) { child in
                                Text(child.fullName).tag(Optional(child.id))
                            }
                        }
                    }
                    TextField("Location (optional)", text: $location)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
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
            errorMessage = "Couldn't save event."
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
                Section("Expense") {
                    TextField("Description", text: $title)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Split") {
                    if !children.isEmpty {
                        Picker("Child", selection: $selectedChildId) {
                            Text("General").tag(UUID?.none)
                            ForEach(children, id: \.id) { child in
                                Text(child.firstName).tag(Optional(child.id))
                            }
                        }
                    }

                    if members.isEmpty {
                        Text("Add a family member to track who paid.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Paid by", selection: $selectedMemberId) {
                            ForEach(members, id: \.id) { member in
                                Text(member.displayName).tag(Optional(member.id))
                            }
                        }
                    }

                    Toggle("Split 50/50", isOn: $splitEvenly)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
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
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
            errorMessage = "Couldn't save expense."
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
