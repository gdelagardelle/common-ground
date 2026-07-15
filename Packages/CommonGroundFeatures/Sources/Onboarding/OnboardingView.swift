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
                    .fill(index <= step ? CGColor.primary : Color.secondary.opacity(0.2))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, CGSpacing.xl)
    }

    private var welcomeStep: some View {
        VStack(spacing: CGSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(CGGradient.aurora.opacity(0.28))
                    .frame(width: 150, height: 150)
                Circle()
                    .fill(CGGradient.sunset.opacity(0.18))
                    .frame(width: 120, height: 120)
                    .blur(radius: 8)

                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(CGColor.primary)
                    .symbolEffect(.bounce, value: step)
            }

            VStack(spacing: CGSpacing.sm) {
                Text(L10n.onboardingWelcome)
                    .font(CGTypography.display)
                    .multilineTextAlignment(.center)

                Text(L10n.onboardingSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CGSpacing.lg)
            }

            VStack(spacing: CGSpacing.sm) {
                CGTrustBadge(
                    icon: "lock.shield.fill",
                    title: L10n.onboardingTrustPrivateTitle,
                    detail: L10n.onboardingTrustPrivateDetail
                )
                CGTrustBadge(
                    icon: "heart.text.square.fill",
                    title: L10n.onboardingTrustCoparentTitle,
                    detail: L10n.onboardingTrustCoparentDetail
                )
            }
            .padding(.horizontal, CGSpacing.xl)

            VStack(spacing: CGSpacing.sm) {
                Button {
                    withAnimation(CGAnimation.quick) { step = 1 }
                } label: {
                    Label(L10n.onboardingCreateFamily, systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CGColor.primary)
                .controlSize(.large)

                Button {
                    showJoinFamily = true
                } label: {
                    Label(L10n.onboardingJoinFamily, systemImage: "person.2.fill")
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
                TextField(L10n.onboardingYourName, text: $parentName)
                    .textContentType(.name)
                    .autocorrectionDisabled()
            } header: {
                Text(L10n.onboardingAboutYou)
            } footer: {
                Text(L10n.onboardingAboutYouFooter)
            }

            Section(L10n.onboardingFamily) {
                TextField(L10n.onboardingFamilyName, text: $familyName)
                    .autocorrectionDisabled()
                TextField(L10n.onboardingCoParentName, text: $coParentName)
                    .textContentType(.name)
            }
        }
    }

    private var childStep: some View {
        Form {
            Section(L10n.onboardingChild) {
                TextField(L10n.onboardingFirstName, text: $childFirstName)
                    .textContentType(.givenName)
                TextField(L10n.onboardingLastName, text: $childLastName)
                    .textContentType(.familyName)
                DatePicker(L10n.onboardingDateOfBirth, selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
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
                        Text(step == 2 ? L10n.commonGetStarted : L10n.commonContinue)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canContinue || isSaving)

            if step > 0 {
                Button(L10n.commonBack) {
                    withAnimation(CGAnimation.quick) { step -= 1 }
                }
                .font(.subheadline)
            }

            #if DEBUG
            Button(L10n.onboardingExploreDemo) {
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
            ?? L10n.format("onboarding.defaultFamilyName", childLastName.trimmingCharacters(in: .whitespaces))

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
            errorMessage = L10n.onboardingSaveError
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
