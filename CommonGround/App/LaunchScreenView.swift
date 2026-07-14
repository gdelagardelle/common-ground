import SwiftUI
import CommonGroundDesign

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BrandPrimary", bundle: .main), Color("BrandSecondary", bundle: .main)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse)

                Text("Common Ground")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
