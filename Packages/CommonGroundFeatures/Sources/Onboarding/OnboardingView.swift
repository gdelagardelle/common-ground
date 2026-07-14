import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var step = 0
    @State private var parentName = ""
    @State private var coParentName = ""
    @State private var familyName = ""
    @State private var childFirstName = ""
    @State private var childLastName = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -8, to: Date()) ?? Date()
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showInvite = false
    @State private var showJoinFamily = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressIndicator
                    .padding(.top, CGSpacing.md)

                TabView(selection: $step) {
                    welcomeStep.tag(0)
                    parentStep.tag(1)
                    childStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(CGAnimation.smooth, value: step)

                bottomBar
                    .opacity(step == 0 ? 0 : 1)
                    .allowsHitTesting(step != 0)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showInvite) {
                InviteCoParentView()
            }
            .sheet(isPresented: $showJoinFamily) {
                JoinFamilyView()
            }
        }
    }

    private var progressIndicator: some View {
        HStack(spacing: CGSpacing.xs) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, CGSpacing.xl)
    }

    private var welcomeStep: some View {
        VStack(spacing: CGSpacing.lg) {
            Spacer()

            Image(systemName: "figure.2.and.child.holdinghands")
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce, value: step)

            VStack(spacing: CGSpacing.sm) {
                Text("Welcome to\nCommon Ground")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("The shared home for raising your children across households.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CGSpacing.lg)
            }

            VStack(spacing: CGSpacing.sm) {
                Button {
                    withAnimation(CGAnimation.quick) { step = 1 }
                } label: {
                    Label("Create a Family", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    showJoinFamily = true
                } label: {
                    Label("Join with Family Code", systemImage: "person.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, CGSpacing.xl)

            Spacer()
        }
    }

    private var parentStep: some View {
        Form {
            Section {
                TextField("Your name", text: $parentName)
                    .textContentType(.name)
                    .autocorrectionDisabled()
            } header: {
                Text("About You")
            } footer: {
                Text("This is how you'll appear to your co-parent and family.")
            }

            Section("Family") {
                TextField("Family name (optional)", text: $familyName)
                    .autocorrectionDisabled()
                TextField("Co-parent name (optional)", text: $coParentName)
                    .textContentType(.name)
            }
        }
    }

    private var childStep: some View {
        Form {
            Section("Child") {
                TextField("First name", text: $childFirstName)
                    .textContentType(.givenName)
                TextField("Last name", text: $childLastName)
                    .textContentType(.familyName)
                DatePicker("Date of birth", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: CGSpacing.sm) {
            Button {
                advance()
            } label: {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(step == 2 ? "Get Started" : "Continue")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canContinue || isSaving)

            if step > 0 {
                Button("Back") {
                    withAnimation(CGAnimation.quick) { step -= 1 }
                }
                .font(.subheadline)
            }

            #if DEBUG
            Button("Explore with demo data") {
                loadDemoData()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            #endif
        }
        .padding(CGSpacing.md)
        .background(.bar)
    }

    private var canContinue: Bool {
        switch step {
        case 0: true
        case 1: !parentName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2:
            !childFirstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !childLastName.trimmingCharacters(in: .whitespaces).isEmpty
        default: false
        }
    }

    private func advance() {
        if step < 2 {
            withAnimation(CGAnimation.quick) { step += 1 }
            return
        }
        finishOnboarding()
    }

    private func finishOnboarding() {
        isSaving = true
        errorMessage = nil

        let resolvedFamilyName = familyName.trimmingCharacters(in: .whitespaces).nilIfEmpty
            ?? "\(childLastName.trimmingCharacters(in: .whitespaces)) Family"

        do {
            let (_, parent, child) = try FamilySetupService.createFamilyWithFirstChild(
                context: modelContext,
                familyName: resolvedFamilyName,
                parentName: parentName.trimmingCharacters(in: .whitespaces),
                childFirstName: childFirstName.trimmingCharacters(in: .whitespaces),
                childLastName: childLastName.trimmingCharacters(in: .whitespaces),
                childDateOfBirth: dateOfBirth,
                coParentName: coParentName.trimmingCharacters(in: .whitespaces).nilIfEmpty
            )
            appState.currentMemberId = parent.id
            appState.currentMemberName = parent.displayName
            appState.selectedChildId = child.id
            appState.isOnboardingComplete = true
            isSaving = false
            if coParentName.trimmingCharacters(in: .whitespaces).isEmpty {
                showInvite = true
            }
        } catch {
            errorMessage = "Couldn't save your family. Please try again."
            isSaving = false
        }
    }

    private func loadDemoData() {
        SampleDataService.seedIfNeeded(context: modelContext)
        guard let family = (try? modelContext.fetch(FetchDescriptor<Family>()))?.first,
              let parent = family.members.first,
              let child = family.children.first else { return }
        appState.currentMemberId = parent.id
        appState.currentMemberName = parent.displayName
        appState.selectedChildId = child.id
        appState.isOnboardingComplete = true
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
