import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct AIAssistantView: View {
    @Bindable var aiService: AIAssistantService
    @Environment(AppState.self) private var appState
    @Query private var children: [Child]
    @Query private var events: [CalendarEvent]
    @Query private var threads: [MessageThread]

    @State private var query = ""
    @FocusState private var isFocused: Bool
    @State private var aiModeLabel = L10n.aiSearching

    private var usesOnDeviceAI: Bool {
        OnDeviceAIAvailability.isSupported
    }

    private var suggestions: [String] {
        [
            L10n.aiSuggestionDentist,
            L10n.aiSuggestionFootballExpense,
            L10n.aiSuggestionNextExchange,
            L10n.aiSuggestionUnpaidExpenses,
            L10n.aiSuggestionAllergies,
            L10n.aiSuggestionSchool,
        ]
    }

    public init(aiService: AIAssistantService) {
        self.aiService = aiService
    }

    private var selectedChild: Child? {
        if let id = appState.selectedChildId {
            return children.first { $0.id == id }
        }
        return children.first
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if aiService.conversationHistory.isEmpty {
                    suggestionsView
                } else {
                    conversationView
                }

                inputBar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.aiTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonDone) {
                        appState.isAIAssistantPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var suggestionsView: some View {
        ScrollView {
            VStack(spacing: CGSpacing.lg) {
                VStack(spacing: CGSpacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.accentColor)
                        .symbolEffect(.pulse)

                    Text(L10n.aiTagline)
                        .font(.title3.weight(.semibold))

                    Text(usesOnDeviceAI ? L10n.aiPoweredOnDevice : L10n.aiFallbackDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, CGSpacing.xl)

                VStack(spacing: CGSpacing.xs) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            Task { await submitQuery(suggestion) }
                        } label: {
                            HStack {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(CGSpacing.md)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CGRadius.md))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, CGSpacing.md)
            }
        }
    }

    private var conversationView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: CGSpacing.md) {
                ForEach(Array(aiService.conversationHistory.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: CGSpacing.sm) {
                        HStack {
                            Spacer()
                            Text(item.query)
                                .font(.subheadline)
                                .padding(CGSpacing.sm)
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: CGRadius.lg))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: CGSpacing.xs) {
                            Text(item.result.answer)
                                .font(.subheadline)

                            if !item.result.sources.isEmpty {
                                ForEach(item.result.sources) { source in
                                    HStack(spacing: CGSpacing.xs) {
                                        Image(systemName: "doc.text")
                                            .font(.caption2)
                                        Text(source.title)
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(CGSpacing.md)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CGRadius.lg))
                    }
                }

                if aiService.isProcessing {
                    HStack(spacing: CGSpacing.xs) {
                        ProgressView()
                        Text(usesOnDeviceAI ? L10n.aiThinkingOnDevice : aiModeLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(CGSpacing.md)
                }
            }
            .padding(CGSpacing.md)
        }
    }

    private var inputBar: some View {
        HStack(spacing: CGSpacing.sm) {
            TextField(L10n.aiPlaceholder, text: $query, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .padding(CGSpacing.sm)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: CGRadius.lg))

            Button {
                Task { await submitQuery(query) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(query.isEmpty || aiService.isProcessing ? .secondary : Color.accentColor)
            }
            .disabled(query.isEmpty || aiService.isProcessing)
        }
        .padding(CGSpacing.md)
        .background(.bar)
    }

    private func submitQuery(_ text: String) async {
        guard let child = selectedChild else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        query = ""
        isFocused = false

        let context = AIContextBuilder.build(from: child, allEvents: events, allThreads: threads)
        _ = await aiService.ask(trimmed, context: context)
    }
}
