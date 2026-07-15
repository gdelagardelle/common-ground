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
                    Text(L10n.dailyIntro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section(L10n.dailyTemplates) {
                    Picker(L10n.dailyTemplate, selection: $selectedPreset) {
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

                Section(L10n.dailyUpdate) {
                    TextField(L10n.dailyHeadline, text: $title)
                    TextField(L10n.dailyDetails, text: $detail, axis: .vertical)
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
            .navigationTitle(L10n.dailyTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonPost) { save() }
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
            errorMessage = L10n.dailySaveError
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
        case .general: L10n.dailyPresetGeneral
        case .schoolDay: L10n.dailyPresetSchool
        case .activity: L10n.dailyPresetActivity
        case .absence: L10n.dailyPresetAbsence
        case .handoff: L10n.dailyPresetHandoff
        }
    }

    func suggestedTitle(childName: String) -> String {
        switch self {
        case .general: L10n.format("daily.preset.general.suggested", childName)
        case .schoolDay: L10n.format("daily.preset.school.suggested", childName)
        case .activity: L10n.format("daily.preset.activity.suggested", childName)
        case .absence: L10n.format("daily.preset.absence.suggested")
        case .handoff: L10n.format("daily.preset.handoff.suggested", childName)
        }
    }
}

public struct DailyUpdateCard: View {
    let entry: TimelineEntry

    public init(entry: TimelineEntry) {
        self.entry = entry
    }

    public var body: some View {
        CGCard(padding: CGSpacing.sm, style: .warm) {
            VStack(alignment: .leading, spacing: CGSpacing.xs) {
                HStack {
                    Image(systemName: "sun.horizon.fill")
                        .foregroundStyle(CGColor.warmAmber)
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let author = entry.authorName {
                        Text(author)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(CGColor.primary.opacity(0.7))
                            .padding(.horizontal, CGSpacing.xs)
                            .padding(.vertical, 2)
                            .background(CGColor.primary.opacity(0.08), in: Capsule())
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
