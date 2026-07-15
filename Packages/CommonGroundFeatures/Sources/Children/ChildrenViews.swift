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
                        title: "Add Your First Child",
                        message: "Create a profile to track health, school, expenses, and milestones.",
                        actionTitle: "Add Child"
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
            .navigationTitle("Children")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddChild = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add child")
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
            CGAvatar(name: child.firstName, imageData: child.photoData, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(child.fullName)
                    .font(.headline)

                Text("Age \(child.age)")
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

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: CGSpacing.lg) {
                profileHeader

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: CGSpacing.sm) {
                    if PermissionService.canViewMedical(currentMember) {
                        ProfileModuleLink(icon: "cross.case.fill", title: "Medical", color: .red, count: child.medicalRecords.count) {
                            MedicalView(child: child)
                        }
                    }
                    if PermissionService.canViewSchool(currentMember) {
                        ProfileModuleLink(icon: "book.fill", title: "School", color: .green, count: child.schoolInfo != nil ? 1 : 0) {
                            SchoolView(child: child)
                        }
                    }
                    if PermissionService.canViewExpenses(currentMember) {
                        ProfileModuleLink(icon: "dollarsign.circle.fill", title: "Expenses", color: .mint, count: child.expenses.count) {
                            ExpensesView(child: child)
                        }
                    }
                    if PermissionService.canViewDocuments(currentMember) {
                        ProfileModuleLink(icon: "doc.fill", title: "Documents", color: .blue, count: child.documents.count) {
                            DocumentsView(child: child)
                        }
                    }
                    if PermissionService.canViewTimeline(currentMember) {
                        ProfileModuleLink(icon: "clock.arrow.circlepath", title: "Timeline", color: .purple, count: child.timelineEntries.count) {
                            TimelineView(child: child)
                        }
                    }
                    if PermissionService.canViewEmergency(currentMember) {
                        ProfileModuleLink(icon: "exclamationmark.shield.fill", title: "Emergency", color: .orange, count: child.emergencyInfo != nil ? 1 : 0) {
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
    }

    private var profileHeader: some View {
        VStack(spacing: CGSpacing.md) {
            CGAvatar(name: child.firstName, imageData: child.photoData, size: 96)

            VStack(spacing: CGSpacing.xxs) {
                Text(child.fullName)
                    .font(.title2.weight(.bold))

                Text("Born \(child.dateOfBirth.formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CGSpacing.lg)
        .background(CGGradient.hero)
    }

    private var vitalsCard: some View {
        CGCard {
            VStack(alignment: .leading, spacing: CGSpacing.sm) {
                Text("Vitals")
                    .font(.headline)

                if let bloodType = child.bloodType {
                    LabeledContent("Blood Type", value: bloodType)
                }
                if !child.allergies.isEmpty {
                    LabeledContent("Allergies", value: child.allergies.joined(separator: ", "))
                }
                if let clothing = child.clothingSize {
                    LabeledContent("Clothing", value: clothing)
                }
                if let shoes = child.shoeSize {
                    LabeledContent("Shoes", value: shoes)
                }
            }
        }
        .padding(.horizontal, CGSpacing.md)
    }
}

struct ProfileModuleLink<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    let count: Int
    let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            CGCard(padding: CGSpacing.sm) {
                VStack(alignment: .leading, spacing: CGSpacing.xs) {
                    HStack {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color)
                        Spacer()
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
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
