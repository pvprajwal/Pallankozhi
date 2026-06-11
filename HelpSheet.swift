import SwiftUI

struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onStartTutorial: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                SoftCreamBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        helpSection(title: "Objective") {
                            Text("Capture more seeds than your opponent. The game ends when one side is empty. The higher score wins.")
                        }

                        helpSection(title: "How to Play") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("• Tap a pit on your side to sow seeds counter-clockwise.")
                                Text("• If the next pit is empty, capture seeds from the following pit.")
                                Text("• If the next pit has seeds, continue sowing.")
                                Text("• If a pit on your side has exactly 4 seeds, you may capture +4.")
                            }
                        }

                        helpSection(title: "Quick Tips") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("• Think ahead to where your last seed lands.")
                                Text("• Watch for 4-seed bonus opportunities.")
                                Text("• Use the interactive tutorial to get started.")
                            }
                        }

                        Button("Start interactive tutorial") {
                            dismiss()
                            onStartTutorial()
                        }
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.90, green: 0.82, blue: 0.72))
                                .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
                        )
                        .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
                        .buttonStyle(.plain)
                        .padding(.top, 6)

                        Button("Close") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                        .frame(maxWidth: .infinity)

                    }
                    .frame(maxWidth: 520, alignment: .leading)
                    .padding(40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .scrollIndicators(.visible)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func helpSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))

            content()
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
        }
    }
}
