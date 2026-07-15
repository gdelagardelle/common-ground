import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct CustodyScheduleBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var families: [Family]

    let child: Child

    @State private var pattern: CustodyPattern = .weekOnWeekOff
    @State private var startDate = Date()
    @State private var parentAId: UUID?
    @State private var parentBId: UUID?
    @State private var exchangeLocation = ""
    @State private var exchangeTime = Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(child: Child) {
        self.child = child
    }

    private var members: [FamilyMember] {
        families.first?.members ?? []
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(L10n.custodySectionSchedule) {
                    Picker(L10n.custodyPattern, selection: $pattern) {
                        ForEach(CustodyPattern.allCases.filter { $0 != .custom }, id: \.self) { item in
                            VStack(alignment: .leading) {
                                Text(item.displayName)
                            }
                            .tag(item)
                        }
                    }

                    Text(pattern.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    DatePicker(L10n.calendarStart, selection: $startDate, displayedComponents: .date)
                }

                Section(L10n.custodySectionParents) {
                    if members.count < 2 {
                        Text(L10n.custodyNeedTwoParents)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker(L10n.custodyParentA, selection: $parentAId) {
                            ForEach(members, id: \.id) { member in
                                Text(member.displayName).tag(Optional(member.id))
                            }
                        }
                        Picker(L10n.custodyParentB, selection: $parentBId) {
                            ForEach(members, id: \.id) { member in
                                Text(member.displayName).tag(Optional(member.id))
                            }
                        }
                    }
                }

                Section(L10n.custodyExchange) {
                    TextField(L10n.formLocationOptional, text: $exchangeLocation)
                    DatePicker(L10n.custodyDefaultTime, selection: $exchangeTime, displayedComponents: .hourAndMinute)
                }

                Section {
                    Text(L10n.custodyGenerateHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(L10n.custodyScheduleTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonCreate) { createSchedule() }
                        .disabled(!canSave || isSaving)
                }
            }
            .onAppear {
                if parentAId == nil { parentAId = members.first?.id }
                if parentBId == nil { parentBId = members.dropFirst().first?.id }
            }
        }
    }

    private var canSave: Bool {
        guard let a = parentAId, let b = parentBId, a != b else { return false }
        return members.count >= 2
    }

    private func createSchedule() {
        guard let aId = parentAId, let bId = parentBId,
              let parentA = members.first(where: { $0.id == aId }),
              let parentB = members.first(where: { $0.id == bId }) else { return }

        isSaving = true
        errorMessage = nil

        do {
            let schedule = try CustodySetupService.createSchedule(
                context: modelContext,
                child: child,
                pattern: pattern,
                parentA: parentA,
                parentB: parentB,
                startDate: startDate,
                exchangeLocation: exchangeLocation,
                exchangeTime: exchangeTime
            )

            Task {
                let marker = "schedule:\(schedule.id.uuidString)"
                let events = child.events.filter { $0.category == .exchange && $0.recurrenceRule == marker }
                for event in events {
                    NotificationService.scheduleExchangeReminder(for: event, childName: child.firstName)
                }
                #if canImport(ActivityKit)
                if let nextExchange = events.sorted(by: { $0.startDate < $1.startDate }).first(where: { $0.startDate >= Date() }) {
                    await LiveActivityService.updateForUpcomingExchange(
                        childName: child.firstName,
                        event: nextExchange,
                        withParent: parentB.displayName
                    )
                }
                #endif
                if CalendarSyncPreferences.isAutoSyncEnabled {
                    _ = try? await CalendarSyncService.exportPendingEvents(context: modelContext)
                }
            }

            dismiss()
        } catch {
            errorMessage = L10n.custodyCreateError
            isSaving = false
        }
    }
}

public struct NewMessageThreadView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query private var families: [Family]

    @State private var subject = ""
    @State private var selectedMemberIds: Set<UUID> = []
    @State private var firstMessage = ""
    @State private var errorMessage: String?

    public init() {}

    private var members: [FamilyMember] {
        families.first?.members.filter { $0.id != appState.currentMemberId } ?? []
    }

    private var currentMember: FamilyMember? {
        families.first?.members.first { $0.id == appState.currentMemberId }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(L10n.messagesSectionSubject) {
                    TextField(L10n.messagesOptionalSubject, text: $subject)
                }

                Section(L10n.messagesSectionParticipants) {
                    if members.isEmpty {
                        Text(L10n.messagesInviteCoparent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(members, id: \.id) { member in
                            Toggle(isOn: binding(for: member.id)) {
                                Text(member.displayName)
                            }
                        }
                    }
                }

                Section(L10n.messagesSectionFirstMessage) {
                    TextField(L10n.messagesWritePlaceholder, text: $firstMessage, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(L10n.messagesNewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.messagesSend) { send() }
                        .disabled(!canSend)
                }
            }
            .onAppear {
                if selectedMemberIds.isEmpty, let first = members.first {
                    selectedMemberIds.insert(first.id)
                }
            }
        }
    }

    private var canSend: Bool {
        !firstMessage.trimmingCharacters(in: .whitespaces).isEmpty
        && !selectedMemberIds.isEmpty
        && currentMember != nil
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedMemberIds.contains(id) },
            set: { isSelected in
                if isSelected { selectedMemberIds.insert(id) }
                else { selectedMemberIds.remove(id) }
            }
        )
    }

    private func send() {
        guard let sender = currentMember else { return }
        let participants = members.filter { selectedMemberIds.contains($0.id) }
        guard !participants.isEmpty else { return }

        do {
            var allMembers = participants
            allMembers.append(sender)
            let thread = try MessagingService.createThread(
                context: modelContext,
                members: allMembers,
                subject: subject
            )
            _ = try MessagingService.sendMessage(
                context: modelContext,
                thread: thread,
                content: firstMessage,
                sender: sender
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
