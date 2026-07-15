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
                Section(L10n.medicalSectionGrowth) {
                    GrowthChartView(child: child)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            if !child.medications.filter(\.isActive).isEmpty {
                Section(L10n.medicalActive) {
                    ForEach(child.medications.filter(\.isActive), id: \.id) { med in
                        MedicationRow(medication: med)
                            .swipeActions {
                                Button(L10n.medicalStop, role: .destructive) {
                                    try? MedicalSetupService.deactivateMedication(med, context: modelContext)
                                }
                            }
                    }
                }
            }

            Section(L10n.medicalSectionRecords) {
                if child.medicalRecords.isEmpty {
                    Text(L10n.medicalEmptyRecords)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(child.medicalRecords.sorted(by: { $0.date > $1.date }), id: \.id) { record in
                        MedicalRecordRow(record: record)
                    }
                }
            }

            if !child.allergies.isEmpty {
                Section(L10n.childrenAllergies) {
                    ForEach(child.allergies, id: \.self) { allergy in
                        Label(allergy, systemImage: "allergens")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .navigationTitle(L10n.childrenModuleMedical)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showAddMedication = true } label: {
                        Label(L10n.medicalAddMedication, systemImage: "pills")
                    }
                    Button { showAddRecord = true } label: {
                        Label(L10n.medicalAddRecord, systemImage: "cross.case")
                    }
                    NavigationLink {
                        HealthImportView()
                    } label: {
                        Label(L10n.healthImportFromHealth, systemImage: "heart.text.square")
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
                CGBadge(L10n.medicalActive, color: .green)
            }
            Text("\(medication.dosage) · \(medication.frequency)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let doctor = medication.prescribedBy {
                Text(L10n.format("medical.prescribedBy", doctor))
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
                Section(L10n.schoolSection) {
                    LabeledContent(L10n.schoolName, value: school.schoolName)
                    if let grade = school.grade {
                        LabeledContent(L10n.schoolGrade, value: grade)
                    }
                    if let classroom = school.classroom {
                        LabeledContent(L10n.schoolClassroom, value: classroom)
                    }
                    if let phone = school.schoolPhone {
                        LabeledContent(L10n.schoolPhone, value: phone)
                    }
                    if let address = school.schoolAddress {
                        LabeledContent(L10n.schoolAddress, value: address)
                    }
                }

                Section(L10n.schoolTeachersContacts) {
                    ForEach(school.teachers, id: \.id) { contact in
                        ContactRow(contact: contact)
                    }
                }

                Section {
                    NavigationLink {
                        SchoolPortalView(child: child)
                    } label: {
                        Label(L10n.moreSchoolPortal, systemImage: "building.columns.fill")
                    }

                    if !child.schoolAnnouncements.isEmpty {
                        LabeledContent(L10n.schoolAnnouncements, value: L10n.format("school.announcementsUnread", child.schoolAnnouncements.filter { !$0.isRead }.count))
                    }
                    if !child.schoolAssignments.isEmpty {
                        LabeledContent(L10n.schoolHomeworkDue, value: "\(child.schoolAssignments.filter { !$0.isCompleted }.count)")
                    }
                }

                Section {
                    Button(L10n.schoolEditInfo) {
                        showAddSchool = true
                    }
                }
            } else {
                CGEmptyState(
                    icon: "book.fill",
                    title: L10n.schoolEmptyTitle,
                    message: L10n.schoolEmptyMessage,
                    actionTitle: L10n.schoolAdd
                ) {
                    showAddSchool = true
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(L10n.childrenModuleSchool)
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
                            Text(L10n.expenseOutstandingBalance)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: totalOwed).doubleValue))")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.green)
                        }
                        Spacer()
                        Button(L10n.expenseSettleUp) {
                            showSettleConfirm = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }

            Section(L10n.expenseSectionAll) {
                ForEach(child.expenses.sorted(by: { $0.date > $1.date }), id: \.id) { expense in
                    ExpenseRow(expense: expense)
                        .swipeActions(edge: .leading) {
                            if expense.isReimbursed {
                                Button(L10n.expenseMarkUnpaid) {
                                    try? ExpenseService.unsettle(expense, context: modelContext)
                                }
                                .tint(.orange)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if !expense.isReimbursed {
                                Button(L10n.expenseSettle) {
                                    try? ExpenseService.markReimbursed(expense, context: modelContext)
                                }
                                .tint(.green)
                            }
                        }
                }
            }
        }
        .navigationTitle(L10n.childrenModuleExpenses)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddExpense = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(preselectedChild: child)
        }
        .confirmationDialog(
            L10n.format("expense.settleAllConfirm", unpaid.count),
            isPresented: $showSettleConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.expenseSettleAll) {
                try? ExpenseService.settleAll(unpaid: unpaid, context: modelContext)
            }
            Button(L10n.commonCancel, role: .cancel) {}
        } message: {
            Text(L10n.format("expense.settleAllMessage", String(format: "%.2f", NSDecimalNumber(decimal: totalOwed).doubleValue)))
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
                Text(L10n.format("expense.paidBy", expense.paidByName))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: expense.amount).doubleValue))")
                    .font(.subheadline.weight(.semibold))
                if expense.isReimbursed {
                    CGBadge(L10n.expenseSettled, color: .green)
                } else {
                    CGBadge(L10n.expensePending, color: .orange)
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
                Text(searchText.isEmpty ? L10n.documentsEmpty : L10n.documentsNoMatches)
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
                                Text(L10n.documentsFileAttached)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Spacer()

                        if doc.isExpiringSoon {
                            CGBadge(L10n.documentsExpiring, color: .orange)
                        }

                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .navigationTitle(L10n.childrenModuleDocuments)
        .searchable(text: $searchText, prompt: L10n.documentsSearchPrompt)
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
    @Environment(AppState.self) private var appState
    @Query private var families: [Family]
    @State private var showAddDailyUpdate = false

    private var currentMember: FamilyMember? {
        PermissionService.currentMember(in: families.first, memberId: appState.currentMemberId)
    }

    private var entries: [TimelineEntry] {
        child.timelineEntries.sorted { $0.date > $1.date }
    }

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        ScrollView {
            if entries.isEmpty {
                CGEmptyState(
                    icon: "sun.horizon.fill",
                    title: L10n.timelineEmptyTitle,
                    message: L10n.timelineEmptyMessage,
                    actionTitle: PermissionService.canPostDailyUpdate(currentMember) ? L10n.dailyTitle : nil
                ) {
                    showAddDailyUpdate = true
                }
                .padding(.top, CGSpacing.xxl)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(entries, id: \.id) { entry in
                        TimelineEntryView(entry: entry)
                    }
                }
                .padding(CGSpacing.md)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.childrenModuleTimeline)
        .toolbar {
            if PermissionService.canPostDailyUpdate(currentMember) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddDailyUpdate = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddDailyUpdate) {
            AddDailyUpdateView(child: child)
        }
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
                HStack {
                    Text(entry.date.formatted(date: .abbreviated, time: entry.category == .dailyUpdate ? .shortened : .omitted))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    if entry.category == .dailyUpdate {
                        Text(L10n.timelineDailyBadge)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                }

                Text(entry.title)
                    .font(.subheadline.weight(.semibold))

                if let author = entry.authorName, entry.category == .dailyUpdate {
                    Text(L10n.format("timeline.byAuthor", author))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

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
                Section(L10n.emergencySectionContacts) {
                    if let name = info.primaryContactName, let phone = info.primaryContactPhone {
                        LabeledContent(name, value: phone)
                    }
                    if let name = info.secondaryContactName, let phone = info.secondaryContactPhone {
                        LabeledContent(name, value: phone)
                    }
                }

                Section(L10n.childrenModuleMedical) {
                    if let doc = info.pediatricianName {
                        LabeledContent(L10n.emergencyPediatrician, value: doc)
                    }
                    if let phone = info.pediatricianPhone {
                        LabeledContent(L10n.schoolPhone, value: phone)
                    }
                    if let hospital = info.hospitalPreference {
                        LabeledContent(L10n.emergencyPreferredHospital, value: hospital)
                    }
                }

                Section(L10n.emergencySectionInsurance) {
                    if let provider = info.insuranceProvider {
                        LabeledContent(L10n.emergencyInsuranceProvider, value: provider)
                    }
                    if let policy = info.insurancePolicyNumber {
                        LabeledContent(L10n.emergencyPolicy, value: policy)
                    }
                }

                Section(L10n.emergencySectionPassport) {
                    if let country = info.passportCountry {
                        LabeledContent(L10n.emergencyCountry, value: country)
                    }
                    if let expiry = info.passportExpiry {
                        LabeledContent(L10n.emergencyExpires, value: expiry.formatted(date: .long, time: .omitted))
                    }
                }
            }
        }
        .navigationTitle(L10n.emergencyTitle)
    }
}
