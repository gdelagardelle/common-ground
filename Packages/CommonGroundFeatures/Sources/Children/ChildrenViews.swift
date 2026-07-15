import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct ChildrenListView: View {
    @Query(sort: \Child.firstName) private var children: [Child]
    @Environment(AppState.self) private var appState
    @State private var showAddChild = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if children.isEmpty {
                    CGEmptyState(
                        icon: "figure.2.and.child.holdinghands",
                        title: L10n.childrenAddFirstTitle,
                        message: L10n.childrenAddFirstMessage,
                        actionTitle: L10n.childrenAddChild
                    ) {
                        showAddChild = true
                    }
                } else {
                    List(children, id: \.id) { child in
                        NavigationLink {
                            ChildDetailView(child: child)
                        } label: {
                            ChildRow(child: child)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(L10n.childrenTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddChild = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(L10n.childrenAddChild)
                }
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
        }
    }
}

struct ChildRow: View {
    let child: Child

    var body: some View {
        HStack(spacing: CGSpacing.md) {
            CGAvatar(
                name: child.firstName,
                imageData: child.photoData,
                genmojiData: child.genmojiData,
                emoji: child.avatarEmoji,
                size: 48
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(child.fullName)
                    .font(.headline)

                Text(L10n.format("common.age", child.age))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let school = child.schoolInfo {
                    Text(school.schoolName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, CGSpacing.xxs)
    }
}

public struct ChildDetailView: View {
    let child: Child
    @Environment(AppState.self) private var appState
    @Query private var families: [Family]

    private var currentMember: FamilyMember? {
        PermissionService.currentMember(in: families.first, memberId: appState.currentMemberId)
    }

    @State private var showAvatarEditor = false

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: CGSpacing.lg) {
                profileHeader

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: CGSpacing.sm) {
                    if PermissionService.canViewMedical(currentMember) {
                        ProfileModuleLink(icon: "cross.case.fill", title: L10n.childrenModuleMedical, accent: .medical, count: child.medicalRecords.count) {
                            MedicalView(child: child)
                        }
                    }
                    if PermissionService.canViewSchool(currentMember) {
                        ProfileModuleLink(icon: "book.fill", title: L10n.childrenModuleSchool, accent: .school, count: child.schoolInfo != nil ? 1 : 0) {
                            SchoolView(child: child)
                        }
                    }
                    if PermissionService.canViewExpenses(currentMember) {
                        ProfileModuleLink(icon: "dollarsign.circle.fill", title: L10n.childrenModuleExpenses, accent: .expenses, count: child.expenses.count) {
                            ExpensesView(child: child)
                        }
                    }
                    if PermissionService.canViewDocuments(currentMember) {
                        ProfileModuleLink(icon: "doc.fill", title: L10n.childrenModuleDocuments, accent: .documents, count: child.documents.count) {
                            DocumentsView(child: child)
                        }
                    }
                    if PermissionService.canViewTimeline(currentMember) {
                        ProfileModuleLink(icon: "clock.arrow.circlepath", title: L10n.childrenModuleTimeline, accent: .timeline, count: child.timelineEntries.count) {
                            TimelineView(child: child)
                        }
                    }
                    if PermissionService.canViewEmergency(currentMember) {
                        ProfileModuleLink(icon: "exclamationmark.shield.fill", title: L10n.childrenModuleEmergency, accent: .emergency, count: child.emergencyInfo != nil ? 1 : 0) {
                            EmergencyView(child: child)
                        }
                    }
                }
                .padding(.horizontal, CGSpacing.md)

                if PermissionService.canViewMedical(currentMember), !child.allergies.isEmpty || child.bloodType != nil {
                    vitalsCard
                }
            }
            .padding(.bottom, CGSpacing.xl)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(child.firstName)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            appState.selectedChildId = child.id
        }
        .sheet(isPresented: $showAvatarEditor) {
            AvatarEditorView(child: child)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: CGSpacing.md) {
            Button {
                showAvatarEditor = true
            } label: {
                VStack(spacing: CGSpacing.sm) {
                    CGAvatar(
                        name: child.firstName,
                        imageData: child.photoData,
                        genmojiData: child.genmojiData,
                        emoji: child.avatarEmoji,
                        size: 104
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "face.smiling.inverse")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(CGGradient.sunset, in: Circle())
                            .offset(x: 4, y: 4)
                    }

                    VStack(spacing: CGSpacing.xxs) {
                        Text(child.fullName)
                            .font(CGTypography.title)
                            .foregroundStyle(.primary)

                        Text(L10n.format("children.born", child.dateOfBirth.formatted(date: .long, time: .omitted)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(L10n.childrenTapGenmoji)
                            .font(.caption)
                            .foregroundStyle(CGColor.primary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CGSpacing.lg)
        .background(CGGradient.hero)
    }

    private var vitalsCard: some View {
        CGCard {
            VStack(alignment: .leading, spacing: CGSpacing.sm) {
                Text(L10n.childrenVitals)
                    .font(.headline)

                if let bloodType = child.bloodType {
                    LabeledContent(L10n.childrenBloodType, value: bloodType)
                }
                if !child.allergies.isEmpty {
                    LabeledContent(L10n.childrenAllergies, value: child.allergies.joined(separator: ", "))
                }
                if let clothing = child.clothingSize {
                    LabeledContent(L10n.childrenClothing, value: clothing)
                }
                if let shoes = child.shoeSize {
                    LabeledContent(L10n.childrenShoes, value: shoes)
                }
            }
        }
        .padding(.horizontal, CGSpacing.md)
    }
}

struct ProfileModuleLink<Destination: View>: View {
    let icon: String
    let title: String
    let accent: CGModuleAccent
    let count: Int
    let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            CGCard(padding: CGSpacing.sm, style: .aurora) {
                VStack(alignment: .leading, spacing: CGSpacing.xs) {
                    HStack {
                        Image(systemName: icon)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(CGColor.moduleGradient(accent), in: RoundedRectangle(cornerRadius: CGRadius.sm, style: .continuous))
                        Spacer()
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(CGColor.primary.opacity(0.08), in: Capsule())
                        }
                    }

                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}
