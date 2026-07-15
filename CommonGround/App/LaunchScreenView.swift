import SwiftUI
import CommonGroundDesign

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            CGGradient.brandSplash
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse)

                Text("Common Ground")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
