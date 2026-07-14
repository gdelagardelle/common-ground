import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

#if canImport(CloudKit)
import CloudKit
#endif

// MARK: - Custody Agreements

public struct CustodyAgreementsListView: View {
    @Query private var families: [Family]
    @State private var showCreate = false

    public init() {}

    private var agreements: [CustodyAgreement] {
        families.first?.custodyAgreements.sorted(by: { $0.createdAt > $1.createdAt }) ?? []
    }

    public var body: some View {
        List {
            if agreements.isEmpty {
                ContentUnavailableView(
                    "No Agreements",
                    systemImage: "signature",
                    description: Text("Create a digital custody agreement for both parents to sign.")
                )
            } else {
                ForEach(agreements, id: \.id) { agreement in
                    NavigationLink {
                        CustodyAgreementDetailView(agreement: agreement)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(agreement.title)
                                .font(.headline)
                            Text(agreement.status.displayName)
                                .font(.caption)
                                .foregroundStyle(statusColor(agreement.status))
                            if let effective = agreement.effectiveDate {
                                Text("Effective \(effective.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Custody Agreements")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateCustodyAgreementView()
        }
    }

    private func statusColor(_ status: AgreementStatus) -> Color {
        switch status {
        case .fullySigned: .green
        case .pendingSignatures: .orange
        case .draft: .secondary
        case .archived: Color.secondary.opacity(0.7)
        }
    }
}

public struct CreateCustodyAgreementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var families: [Family]

    @State private var title = "Custody & Parenting Agreement"
    @State private var bodyText = CustodyAgreementService.defaultTemplate
    @State private var effectiveDate = Date()
    @State private var useEffectiveDate = false
    @State private var parentAId: UUID?
    @State private var parentBId: UUID?
    @State private var errorMessage: String?

    public init() {}

    private var members: [FamilyMember] {
        families.first?.members.filter { $0.role != .professional } ?? []
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Agreement") {
                    TextField("Title", text: $title)
                    Toggle("Effective date", isOn: $useEffectiveDate)
                    if useEffectiveDate {
                        DatePicker("Date", selection: $effectiveDate, displayedComponents: .date)
                    }
                }

                Section("Signing Parties") {
                    if members.count < 2 {
                        Text("Add a co-parent before creating a two-party agreement.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Parent A", selection: $parentAId) {
                            ForEach(members, id: \.id) { member in
                                Text(member.displayName).tag(Optional(member.id))
                            }
                        }
                        Picker("Parent B", selection: $parentBId) {
                            ForEach(members, id: \.id) { member in
                                Text(member.displayName).tag(Optional(member.id))
                            }
                        }
                    }
                }

                Section("Terms") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 200)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Agreement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(!canCreate)
                }
            }
            .onAppear {
                if parentAId == nil { parentAId = members.first?.id }
                if parentBId == nil { parentBId = members.dropFirst().first?.id }
            }
        }
    }

    private var canCreate: Bool {
        guard let a = parentAId, let b = parentBId, a != b else { return false }
        return !title.trimmingCharacters(in: .whitespaces).isEmpty && members.count >= 2
    }

    private func create() {
        guard let family = families.first,
              let aId = parentAId, let bId = parentBId,
              let parentA = members.first(where: { $0.id == aId }),
              let parentB = members.first(where: { $0.id == bId }) else { return }

        do {
            _ = try CustodyAgreementService.createAgreement(
                context: modelContext,
                family: family,
                child: family.children.first,
                title: title.trimmingCharacters(in: .whitespaces),
                bodyText: bodyText,
                effectiveDate: useEffectiveDate ? effectiveDate : nil,
                parentA: parentA,
                parentB: parentB
            )
            dismiss()
        } catch {
            errorMessage = "Couldn't create agreement."
        }
    }
}

public struct CustodyAgreementDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var families: [Family]

    let agreement: CustodyAgreement

    @State private var showSign = false
    @State private var showSharePDF = false
    @State private var pdfURL: URL?

    public init(agreement: CustodyAgreement) {
        self.agreement = agreement
    }

    private var currentMember: FamilyMember? {
        PermissionService.currentMember(in: families.first, memberId: appState.currentMemberId)
    }

    private var canSign: Bool {
        guard let member = currentMember else { return false }
        return agreement.pendingSignerId(currentMemberId: member.id)
    }

    public var body: some View {
        List {
            Section {
                LabeledContent("Status", value: agreement.status.displayName)
                if let effective = agreement.effectiveDate {
                    LabeledContent("Effective", value: effective.formatted(date: .long, time: .omitted))
                }
                if let hash = agreement.documentHash {
                    LabeledContent("Integrity", value: String(hash.prefix(16)) + "…")
                }
            }

            Section("Terms") {
                Text(agreement.bodyText)
                    .font(.subheadline)
            }

            Section("Signatures") {
                signatureRow(
                    name: agreement.parentAName ?? "Parent A",
                    signedAt: agreement.parentASignedAt,
                    hasSigned: agreement.parentASignatureData != nil
                )
                signatureRow(
                    name: agreement.parentBName ?? "Parent B",
                    signedAt: agreement.parentBSignedAt,
                    hasSigned: agreement.parentBSignatureData != nil
                )
            }

            if canSign {
                Section {
                    Button {
                        showSign = true
                    } label: {
                        Label("Sign Agreement", systemImage: "signature")
                    }
                }
            }

            if agreement.status == .fullySigned {
                Section {
                    Button {
                        exportPDF()
                    } label: {
                        Label("Export Signed PDF", systemImage: "doc.richtext")
                    }
                }
            }
        }
        .navigationTitle(agreement.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSign) {
            SignCustodyAgreementView(agreement: agreement)
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showSharePDF) {
            if let pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
        #endif
    }

    private func signatureRow(name: String, signedAt: Date?, hasSigned: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                if let signedAt {
                    Text("Signed \(signedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Awaiting signature")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Image(systemName: hasSigned ? "checkmark.seal.fill" : "clock")
                .foregroundStyle(hasSigned ? .green : .orange)
        }
    }

    private func exportPDF() {
        #if canImport(UIKit)
        pdfURL = try? CustodyAgreementService.generateSignedPDF(agreement)
        showSharePDF = pdfURL != nil
        #endif
    }
}

public struct SignCustodyAgreementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query private var families: [Family]

    let agreement: CustodyAgreement

    @State private var signatureData: Data?
    @State private var errorMessage: String?

    public init(agreement: CustodyAgreement) {
        self.agreement = agreement
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("By signing, you agree to the terms of \"\(agreement.title)\". Your signature is stored securely on device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                #if canImport(PencilKit)
                Section("Your Signature") {
                    SignaturePadView(signatureData: $signatureData)
                }
                #else
                Section {
                    Text("Signature capture requires iOS.")
                        .foregroundStyle(.secondary)
                }
                #endif

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Sign Agreement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sign") { sign() }
                        .disabled(signatureData == nil)
                }
            }
        }
    }

    private func sign() {
        guard let member = PermissionService.currentMember(in: families.first, memberId: appState.currentMemberId),
              let data = signatureData else { return }
        do {
            try CustodyAgreementService.signAgreement(agreement, member: member, signatureData: data, context: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Professional Portal

public struct ProfessionalPortalView: View {
    @Environment(AppState.self) private var appState
    @Query private var families: [Family]
    @Query(sort: \CalendarEvent.startDate) private var events: [CalendarEvent]
    @Query private var threads: [MessageThread]

    public init() {}

    private var family: Family? { families.first }

    private var currentMember: FamilyMember? {
        PermissionService.currentMember(in: family, memberId: appState.currentMemberId)
    }

    private var summary: ProfessionalFamilySummary? {
        family.map { PermissionService.professionalSummary(for: $0) }
    }

    public var body: some View {
        List {
            Section {
                Label("Read-only professional access", systemImage: "eye.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let summary {
                Section("Family Overview") {
                    LabeledContent("Family", value: summary.familyName)
                    LabeledContent("Members", value: "\(summary.memberCount)")
                    LabeledContent("Active schedules", value: "\(summary.activeSchedules)")
                }

                Section("Children") {
                    ForEach(summary.children, id: \.name) { child in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(child.name)
                                .font(.subheadline.weight(.medium))
                            Text("Age \(child.age) · \(child.upcomingEvents) upcoming events · \(child.documentCount) documents")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Upcoming Custody & Exchanges") {
                let upcoming = events.filter { $0.startDate >= Date() && ($0.category == .custody || $0.category == .exchange) }.prefix(8)
                if upcoming.isEmpty {
                    Text("No upcoming events")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(upcoming), id: \.id) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.subheadline.weight(.medium))
                            Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if PermissionService.canExportRecords(currentMember) {
                Section("Records") {
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Court Export", systemImage: "doc.text.magnifyingglass")
                    }
                }
            }

            Section("Messages (read-only)") {
                if threads.isEmpty {
                    Text("No message threads")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(threads.prefix(5), id: \.id) { thread in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(thread.subject?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Conversation")
                                .font(.subheadline.weight(.medium))
                            if let last = thread.messages.sorted(by: { $0.sentAt > $1.sentAt }).first {
                                Text("\(last.senderName): \(last.content)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Professional Portal")
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - CloudKit Sharing

#if canImport(CloudKit) && canImport(UIKit)
import UIKit

public struct CloudSharingView: UIViewControllerRepresentable {
    let family: Family
    let modelContext: ModelContext
    @Binding var isPresented: Bool

    public init(family: Family, modelContext: ModelContext, isPresented: Binding<Bool>) {
        self.family = family
        self.modelContext = modelContext
        _isPresented = isPresented
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.backgroundColor = .clear
        return host
    }

    public func updateUIViewController(_ host: UIViewController, context: Context) {
        guard isPresented, host.presentedViewController == nil else { return }

        Task { @MainActor in
            do {
                let (share, ckContainer) = try await CloudKitShareService.shareFamily(
                    family,
                    context: modelContext
                )
                let controller = UICloudSharingController(share: share, container: ckContainer)
                controller.delegate = context.coordinator
                controller.modalPresentationStyle = .formSheet
                host.present(controller, animated: true)
            } catch {
                isPresented = false
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    public final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        public func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            isPresented = false
        }

        public func itemTitle(for csc: UICloudSharingController) -> String? {
            "Common Ground Family"
        }

        public func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {}

        public func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            isPresented = false
        }
    }
}
#endif
