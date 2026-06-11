import SwiftUI

struct ScoreView: View {
    let playerScore: Int
    let aiScore: Int
    let isTwoPlayer: Bool
    let currentPlayer: Int
    let winnerIndex: Int?
    let celebrateWinner: Bool
    @State private var isActiveGlow = false
    @State private var isWinnerPulse = false

    var body: some View {
        let playerGlow = Color.green.opacity(0.35)
        let computerGlow = Color.blue.opacity(0.35)
        let winnerGlow = Color.yellow.opacity(0.35)

        HStack(spacing: 24) {
            scoreBlock(
                title: isTwoPlayer ? "Player 1" : "Player",
                value: playerScore,
                isActive: currentPlayer == 0,
                glowColor: playerGlow,
                isWinner: winnerIndex == 0
            )
            scoreBlock(
                title: isTwoPlayer ? "Player 2" : "Computer",
                value: aiScore,
                isActive: currentPlayer == 1,
                glowColor: computerGlow,
                isWinner: winnerIndex == 1
            )
        }
        .onChange(of: currentPlayer) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                isActiveGlow = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    isActiveGlow = false
                }
            }
        }
        .onChange(of: celebrateWinner) { _ in
            guard winnerIndex != nil else { return }
            Task {
                for _ in 0..<2 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isWinnerPulse = true
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isWinnerPulse = false
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
            }
        }
    }

    private func scoreBlock(title: String, value: Int, isActive: Bool, glowColor: Color, isWinner: Bool) -> some View {
        let showWinnerPulse = isWinner && isWinnerPulse
        return VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 32, weight: .medium, design: .serif))
                .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
            Text("\(value)")
                .font(.system(size: 68, weight: .semibold, design: .serif))
                .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
        }
        .frame(width: 160)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.95, green: 0.91, blue: 0.86))
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
        )
        .scaleEffect(showWinnerPulse ? 1.08 : (isActive && isActiveGlow ? 1.05 : 1.0))
        .shadow(color: showWinnerPulse ? Color.yellow.opacity(0.35) : (isActive && isActiveGlow ? glowColor : Color.clear), radius: showWinnerPulse ? 14 : 12, x: 0, y: 0)
    }
}
