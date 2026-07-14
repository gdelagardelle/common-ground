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
    @State private var frequency = "Once daily"
    @State private var prescribedBy = ""
    @State private var reminderTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var errorMessage: String?

    private let frequencies = ["Once daily", "Twice daily", "Every 8 hours", "As needed"]

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name", text: $name)
                    TextField("Dosage", text: $dosage)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Prescribed by (optional)", text: $prescribedBy)
                }

                Section("Reminder") {
                    DatePicker("Daily reminder", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
                frequency: frequency,
                prescribedBy: prescribedBy.nilIfEmpty,
                reminderHour: components.hour ?? 8,
                reminderMinute: components.minute ?? 0
            )
            dismiss()
        } catch {
            errorMessage = "Couldn't save medication."
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
                Section("Record") {
                    TextField("Title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(MedicalCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Provider (optional)", text: $provider)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
                if let errorMessage {
                    Section { Text(errorMessage).font(.caption).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
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
            errorMessage = "Couldn't save record."
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
                Section("Document") {
                    TextField("Title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(DocumentCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    Toggle("Has expiry date", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Expires", selection: $expiryDate, displayedComponents: .date)
                    }
                }

                Section("File") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose Photo", systemImage: "photo")
                    }
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Import File", systemImage: "doc")
                    }
                    if fileName != nil {
                        Label(fileName ?? "File attached", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                if let errorMessage {
                    Section { Text(errorMessage).font(.caption).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
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
                    errorMessage = "Couldn't import file."
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
            errorMessage = "Couldn't save document."
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
