import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct MedicalView: View {
    let child: Child

    @Environment(\.modelContext) private var modelContext
    @State private var showAddMedication = false
    @State private var showAddRecord = false

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        List {
            if !child.growthMeasurements.isEmpty {
                Section("Growth") {
                    GrowthChartView(child: child)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            if !child.medications.filter(\.isActive).isEmpty {
                Section("Active Medications") {
                    ForEach(child.medications.filter(\.isActive), id: \.id) { med in
                        MedicationRow(medication: med)
                            .swipeActions {
                                Button("Stop", role: .destructive) {
                                    try? MedicalSetupService.deactivateMedication(med, context: modelContext)
                                }
                            }
                    }
                }
            }

            Section("Records") {
                if child.medicalRecords.isEmpty {
                    Text("No medical records yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(child.medicalRecords.sorted(by: { $0.date > $1.date }), id: \.id) { record in
                        MedicalRecordRow(record: record)
                    }
                }
            }

            if !child.allergies.isEmpty {
                Section("Allergies") {
                    ForEach(child.allergies, id: \.self) { allergy in
                        Label(allergy, systemImage: "allergens")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .navigationTitle("Medical")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showAddMedication = true } label: {
                        Label("Add Medication", systemImage: "pills")
                    }
                    Button { showAddRecord = true } label: {
                        Label("Add Record", systemImage: "cross.case")
                    }
                    NavigationLink {
                        HealthImportView()
                    } label: {
                        Label("Import from Health", systemImage: "heart.text.square")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddMedication) {
            AddMedicationView(child: child)
        }
        .sheet(isPresented: $showAddRecord) {
            AddMedicalRecordView(child: child)
        }
    }
}

struct MedicationRow: View {
    let medication: Medication

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(medication.name)
                    .font(.headline)
                Spacer()
                CGBadge("Active", color: .green)
            }
            Text("\(medication.dosage) · \(medication.frequency)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let doctor = medication.prescribedBy {
                Text("Prescribed by \(doctor)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct MedicalRecordRow: View {
    let record: MedicalRecord

    var body: some View {
        HStack(spacing: CGSpacing.sm) {
            Image(systemName: record.category.icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.subheadline.weight(.medium))
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let provider = record.provider {
                Text(provider)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }
}

public struct SchoolView: View {
    let child: Child

    @State private var showAddSchool = false

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        List {
            if let school = child.schoolInfo {
                Section("School") {
                    LabeledContent("Name", value: school.schoolName)
                    if let grade = school.grade {
                        LabeledContent("Grade", value: grade)
                    }
                    if let classroom = school.classroom {
                        LabeledContent("Classroom", value: classroom)
                    }
                    if let phone = school.schoolPhone {
                        LabeledContent("Phone", value: phone)
                    }
                    if let address = school.schoolAddress {
                        LabeledContent("Address", value: address)
                    }
                }

                Section("Teachers & Contacts") {
                    ForEach(school.teachers, id: \.id) { contact in
                        ContactRow(contact: contact)
                    }
                }

                Section {
                    NavigationLink {
                        SchoolPortalView(child: child)
                    } label: {
                        Label("School Portal", systemImage: "building.columns.fill")
                    }

                    if !child.schoolAnnouncements.isEmpty {
                        LabeledContent("Announcements", value: "\(child.schoolAnnouncements.filter { !$0.isRead }.count) unread")
                    }
                    if !child.schoolAssignments.isEmpty {
                        LabeledContent("Homework due", value: "\(child.schoolAssignments.filter { !$0.isCompleted }.count)")
                    }
                }

                Section {
                    Button("Edit School Info") {
                        showAddSchool = true
                    }
                }
            } else {
                CGEmptyState(
                    icon: "book.fill",
                    title: "No School Info",
                    message: "Add school details and connect your school portal.",
                    actionTitle: "Add School"
                ) {
                    showAddSchool = true
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("School")
        .sheet(isPresented: $showAddSchool) {
            AddSchoolInfoView(child: child)
        }
    }
}

struct ContactRow: View {
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(contact.name)
                .font(.subheadline.weight(.medium))
            if let role = contact.role {
                Text(role)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let phone = contact.phone {
                Text(phone)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

public struct ExpensesView: View {
    let child: Child

    @Environment(\.modelContext) private var modelContext
    @State private var showAddExpense = false
    @State private var showSettleConfirm = false

    private var unpaid: [Expense] {
        child.expenses.filter { !$0.isReimbursed }
    }

    private var totalOwed: Decimal {
        unpaid.reduce(Decimal.zero) { $0 + $1.owedAmount }
    }

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        List {
            if totalOwed > 0 {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Outstanding Balance")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: totalOwed).doubleValue))")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.green)
                        }
                        Spacer()
                        Button("Settle Up") {
                            showSettleConfirm = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }

            Section("All Expenses") {
                ForEach(child.expenses.sorted(by: { $0.date > $1.date }), id: \.id) { expense in
                    ExpenseRow(expense: expense)
                        .swipeActions(edge: .leading) {
                            if expense.isReimbursed {
                                Button("Mark Unpaid") {
                                    try? ExpenseService.unsettle(expense, context: modelContext)
                                }
                                .tint(.orange)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if !expense.isReimbursed {
                                Button("Settle") {
                                    try? ExpenseService.markReimbursed(expense, context: modelContext)
                                }
                                .tint(.green)
                            }
                        }
                }
            }
        }
        .navigationTitle("Expenses")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddExpense = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(preselectedChild: child)
        }
        .confirmationDialog(
            "Settle all \(unpaid.count) unpaid expenses?",
            isPresented: $showSettleConfirm,
            titleVisibility: .visible
        ) {
            Button("Settle All") {
                try? ExpenseService.settleAll(unpaid: unpaid, context: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This marks $\(String(format: "%.2f", NSDecimalNumber(decimal: totalOwed).doubleValue)) as reimbursed.")
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack {
            Image(systemName: expense.category.icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.subheadline.weight(.medium))
                Text("Paid by \(expense.paidByName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: expense.amount).doubleValue))")
                    .font(.subheadline.weight(.semibold))
                if expense.isReimbursed {
                    CGBadge("Settled", color: .green)
                } else {
                    CGBadge("Pending", color: .orange)
                }
            }
        }
    }
}

public struct DocumentsView: View {
    let child: Child

    @State private var showAddDocument = false
    @State private var searchText = ""

    public init(child: Child) {
        self.child = child
    }

    private var filteredDocuments: [Document] {
        guard !searchText.isEmpty else { return child.documents }
        return child.documents.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
            || $0.category.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        List {
            if filteredDocuments.isEmpty {
                Text(searchText.isEmpty ? "No documents yet" : "No matches")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredDocuments, id: \.id) { doc in
                    HStack(spacing: CGSpacing.sm) {
                        Image(systemName: doc.category.icon)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.title)
                                .font(.subheadline.weight(.medium))
                            Text(doc.category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if doc.fileData != nil {
                                Text("File attached")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Spacer()

                        if doc.isExpiringSoon {
                            CGBadge("Expiring", color: .orange)
                        }

                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .navigationTitle("Documents")
        .searchable(text: $searchText, prompt: "Search documents")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddDocument = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddDocument) {
            AddDocumentView(child: child)
        }
    }
}

public struct TimelineView: View {
    let child: Child

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(child.timelineEntries.sorted(by: { $0.date > $1.date }), id: \.id) { entry in
                    TimelineEntryView(entry: entry)
                }
            }
            .padding(CGSpacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Timeline")
    }
}

struct TimelineEntryView: View {
    let entry: TimelineEntry

    var body: some View {
        HStack(alignment: .top, spacing: CGSpacing.md) {
            VStack(spacing: 0) {
                Image(systemName: entry.category.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor, in: Circle())

                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 2)
            }

            VStack(alignment: .leading, spacing: CGSpacing.xxs) {
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(entry.title)
                    .font(.subheadline.weight(.semibold))

                if let detail = entry.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.bottom, CGSpacing.lg)
        }
    }
}

public struct EmergencyView: View {
    let child: Child

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        List {
            if let info = child.emergencyInfo {
                Section("Emergency Contacts") {
                    if let name = info.primaryContactName, let phone = info.primaryContactPhone {
                        LabeledContent(name, value: phone)
                    }
                    if let name = info.secondaryContactName, let phone = info.secondaryContactPhone {
                        LabeledContent(name, value: phone)
                    }
                }

                Section("Medical") {
                    if let doc = info.pediatricianName {
                        LabeledContent("Pediatrician", value: doc)
                    }
                    if let phone = info.pediatricianPhone {
                        LabeledContent("Phone", value: phone)
                    }
                    if let hospital = info.hospitalPreference {
                        LabeledContent("Preferred Hospital", value: hospital)
                    }
                }

                Section("Insurance") {
                    if let provider = info.insuranceProvider {
                        LabeledContent("Provider", value: provider)
                    }
                    if let policy = info.insurancePolicyNumber {
                        LabeledContent("Policy", value: policy)
                    }
                }

                Section("Passport") {
                    if let country = info.passportCountry {
                        LabeledContent("Country", value: country)
                    }
                    if let expiry = info.passportExpiry {
                        LabeledContent("Expires", value: expiry.formatted(date: .long, time: .omitted))
                    }
                }
            }
        }
        .navigationTitle("Emergency Info")
    }
}
