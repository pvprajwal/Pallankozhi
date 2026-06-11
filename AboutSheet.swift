import SwiftUI

struct AboutSheet: View {
    var body: some View {
        ZStack {
            SoftCreamBackground()

            VStack(spacing: 16) {
                Text("About Vamana Guntalu")
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))

                Text("In many South Indian households, Vamana Guntalu has been played on quiet afternoons, seeds moving rhythmically across carved wooden boards.\nA timeless duel of patience and foresight, passed softly from one generation to the next.")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
                    .frame(maxWidth: 520)

                Text("Player sits at the bottom row. Computer plays from the top.")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
            }
            .padding(40)
        }
        .presentationDetents([.medium])
    }
}
