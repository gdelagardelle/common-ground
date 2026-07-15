import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct PersistenceRecoveryView: View {
    let error: Error
    let onRetry: () -> Void

    public init(error: Error, onRetry: @escaping () -> Void) {
        self.error = error
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: CGSpacing.lg) {
            Spacer()

            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            VStack(spacing: CGSpacing.sm) {
                Text(L10n.persistenceRecoveryTitle)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(L10n.persistenceRecoveryMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CGSpacing.lg)
            }

            Spacer()

            VStack(spacing: CGSpacing.sm) {
                Button(action: onRetry) {
                    Label(L10n.persistenceRecoveryRetry, systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text(error.localizedDescription)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CGSpacing.xl)
            }
            .padding(.horizontal, CGSpacing.xl)
            .padding(.bottom, CGSpacing.xxl)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
