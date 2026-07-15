import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct AddDailyUpdateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    let child: Child

    @State private var title = ""
    @State private var detail = ""
    @State private var selectedPreset: DailyUpdatePreset = .general
    @State private var errorMessage: String?

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Share what happened today so your co-parent stays informed — without a long chat.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Quick templates") {
                    Picker("Template", selection: $selectedPreset) {
                        ForEach(DailyUpdatePreset.allCases, id: \.self) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    .onChange(of: selectedPreset) { _, preset in
                        if title.trimmingCharacters(in: .whitespaces).isEmpty {
                            title = preset.suggestedTitle(childName: child.firstName)
                        }
                    }
                }

                Section("Update") {
                    TextField("Headline", text: $title)
                    TextField("Details (optional)", text: $detail, axis: .vertical)
                        .lineLimit(4...8)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Daily Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if title.isEmpty {
                    title = selectedPreset.suggestedTitle(childName: child.firstName)
                }
            }
        }
    }

    private func save() {
        do {
            try DailyUpdateService.create(
                context: modelContext,
                child: child,
                title: title.trimmingCharacters(in: .whitespaces),
                detail: detail.nilIfEmpty,
                authorMemberId: appState.currentMemberId,
                authorName: appState.currentMemberName
            )
            dismiss()
        } catch {
            errorMessage = "Couldn't save update. Please try again."
        }
    }
}

enum DailyUpdatePreset: String, CaseIterable {
    case general
    case schoolDay
    case activity
    case absence
    case handoff

    var title: String {
        switch self {
        case .general: "General update"
        case .schoolDay: "School day"
        case .activity: "Activity / sport"
        case .absence: "Couldn't attend"
        case .handoff: "Handoff note"
        }
    }

    func suggestedTitle(childName: String) -> String {
        switch self {
        case .general: "\(childName)'s day"
        case .schoolDay: "School update for \(childName)"
        case .activity: "\(childName)'s activity"
        case .absence: "Update — I wasn't there"
        case .handoff: "Handoff for \(childName)"
        }
    }
}

public struct DailyUpdateCard: View {
    let entry: TimelineEntry

    public init(entry: TimelineEntry) {
        self.entry = entry
    }

    public var body: some View {
        CGCard(padding: CGSpacing.sm) {
            VStack(alignment: .leading, spacing: CGSpacing.xs) {
                HStack {
                    Image(systemName: "sun.horizon.fill")
                        .foregroundStyle(.orange)
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let author = entry.authorName {
                        Text(author)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(entry.title)
                    .font(.subheadline.weight(.semibold))

                if let detail = entry.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
