import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import CommonGroundCore
import CommonGroundDesign

public struct AddMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let child: Child

    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = MedicationFrequency.onceDaily.rawValue
    @State private var prescribedBy = ""
    @State private var reminderTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var errorMessage: String?

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(L10n.medFormSectionMedication) {
                    TextField(L10n.medFormName, text: $name)
                    TextField(L10n.medFormDosage, text: $dosage)
                    Picker(L10n.medFormFrequency, selection: $frequency) {
                        ForEach(MedicationFrequency.allCases, id: \.rawValue) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    TextField(L10n.medFormPrescribedBy, text: $prescribedBy)
                }

                Section(L10n.medFormSectionReminder) {
                    DatePicker(L10n.medFormDailyReminder, selection: $reminderTime, displayedComponents: .hourAndMinute)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(L10n.medFormAddMedication)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.commonCancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonSave) { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || dosage.isEmpty)
                }
            }
        }
    }

    private func save() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        do {
            _ = try MedicalSetupService.addMedication(
                context: modelContext,
                child: child,
                name: name.trimmingCharacters(in: .whitespaces),
                dosage: dosage.trimmingCharacters(in: .whitespaces),
                frequency: MedicationFrequency(rawValue: frequency)?.displayName ?? frequency,
                prescribedBy: prescribedBy.nilIfEmpty,
                reminderHour: components.hour ?? 8,
                reminderMinute: components.minute ?? 0
            )
            dismiss()
        } catch {
            errorMessage = L10n.medFormSaveMedicationError
        }
    }
}

public struct AddMedicalRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let child: Child

    @State private var title = ""
    @State private var category: MedicalCategory = .visit
    @State private var date = Date()
    @State private var provider = ""
    @State private var notes = ""
    @State private var errorMessage: String?

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(L10n.medFormSectionRecord) {
                    TextField(L10n.formTitle, text: $title)
                    Picker(L10n.formCategory, selection: $category) {
                        ForEach(MedicalCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    DatePicker(L10n.formDate, selection: $date, displayedComponents: .date)
                    TextField(L10n.medFormProvider, text: $provider)
                }
                Section(L10n.formSectionNotes) {
                    TextField(L10n.formSectionNotes, text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
                if let errorMessage {
                    Section { Text(errorMessage).font(.caption).foregroundStyle(.red) }
                }
            }
            .navigationTitle(L10n.medFormAddRecord)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.commonCancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonSave) { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        do {
            _ = try MedicalSetupService.addMedicalRecord(
                context: modelContext,
                child: child,
                title: title.trimmingCharacters(in: .whitespaces),
                category: category,
                date: date,
                provider: provider.nilIfEmpty,
                notes: notes.nilIfEmpty
            )
            dismiss()
        } catch {
            errorMessage = L10n.medFormSaveRecordError
        }
    }
}

public struct AddDocumentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let child: Child

    @State private var title = ""
    @State private var category: DocumentCategory = .other
    @State private var expiryDate = Date()
    @State private var hasExpiry = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var fileData: Data?
    @State private var fileName: String?
    @State private var showFilePicker = false
    @State private var errorMessage: String?

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(L10n.docFormSectionDocument) {
                    TextField(L10n.formTitle, text: $title)
                    Picker(L10n.formCategory, selection: $category) {
                        ForEach(DocumentCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    Toggle(L10n.docFormHasExpiry, isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker(L10n.docFormExpires, selection: $expiryDate, displayedComponents: .date)
                    }
                }

                Section(L10n.docFormSectionFile) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(L10n.docFormChoosePhoto, systemImage: "photo")
                    }
                    Button {
                        showFilePicker = true
                    } label: {
                        Label(L10n.docFormImportFile, systemImage: "doc")
                    }
                    if fileName != nil {
                        Label(fileName ?? L10n.docFormFileAttached, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                if let errorMessage {
                    Section { Text(errorMessage).font(.caption).foregroundStyle(.red) }
                }
            }
            .navigationTitle(L10n.docFormAddDocument)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.commonCancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonSave) { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        fileData = data
                        fileName = "photo.jpg"
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .image, .plainText, .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    fileData = try? Data(contentsOf: url)
                    fileName = url.lastPathComponent
                case .failure:
                    errorMessage = L10n.docFormImportError
                }
            }
        }
    }

    private func save() {
        do {
            _ = try DocumentSetupService.addDocument(
                context: modelContext,
                child: child,
                title: title.trimmingCharacters(in: .whitespaces),
                category: category,
                fileData: fileData,
                fileName: fileName,
                mimeType: fileName?.hasSuffix(".pdf") == true ? "application/pdf" : "image/jpeg",
                expiryDate: hasExpiry ? expiryDate : nil
            )
            dismiss()
        } catch {
            errorMessage = L10n.docFormSaveDocumentError
        }
    }
}

enum MedicationFrequency: String, CaseIterable {
    case onceDaily = "medForm.freq.onceDaily"
    case twiceDaily = "medForm.freq.twiceDaily"
    case every8Hours = "medForm.freq.every8Hours"
    case asNeeded = "medForm.freq.asNeeded"

    var displayName: String {
        switch self {
        case .onceDaily: L10n.medFormFreqOnceDaily
        case .twiceDaily: L10n.medFormFreqTwiceDaily
        case .every8Hours: L10n.medFormFreqEvery8Hours
        case .asNeeded: L10n.medFormFreqAsNeeded
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
