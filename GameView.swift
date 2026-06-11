import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var game: VamanaGuntaluGame
    @State private var celebrateWinner = false
    @State private var showBoardGlow = false

    // MARK: Difficulty
    init(mode: GameMode = .vsComputer, difficulty: AIDifficulty = .hard) {
        _game = StateObject(wrappedValue: VamanaGuntaluGame(mode: mode, difficulty: difficulty))
    }

    var body: some View {
        ZStack {
            GameBackground()

            VStack(spacing: 24) {
                if game.mode != .tutorial {
                    ScoreView(playerScore: game.playerScore, aiScore: game.aiScore, isTwoPlayer: game.mode == .twoPlayer, currentPlayer: game.currentPlayer, winnerIndex: winnerIndex, celebrateWinner: celebrateWinner)
                }

                Text(game.mode == .tutorial ? game.tutorialMessage : game.statusMessage)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(statusTextColor)
                    .frame(maxWidth: 420, alignment: .center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.98, green: 0.96, blue: 0.92))
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
                    )

                GeometryReader { proxy in
                    let safeWidth = max(320.0, proxy.size.width - 64)
                    let safeHeight = max(240.0, proxy.size.height - 24)
                    let boardWidth = min(safeWidth, 860)
                    let boardHeight = min(safeHeight, 380)
                    let pitSize = max(64.0, min(104.0, boardWidth / 8.2))

                    VStack(spacing: 18) {
                        pitsRow(indices: Array(7...13), pitSize: pitSize, isPlayerRow: false)
                        pitsRow(indices: Array(0...6), pitSize: pitSize, isPlayerRow: true)
                    }
                    .frame(width: boardWidth, height: boardHeight)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.72, green: 0.55, blue: 0.36),
                                        Color(red: 0.60, green: 0.44, blue: 0.30)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                boardTurnHighlight
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.yellow.opacity(0.18))
                            .blendMode(.overlay)
                            .opacity(showBoardGlow ? 1 : 0)
                            .animation(.easeInOut(duration: 0.8), value: showBoardGlow)
                    )
                    .animation(.easeInOut(duration: 0.9), value: game.currentPlayer)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minHeight: 280, idealHeight: 360)

                Spacer(minLength: 0)
            }
            .padding(32)

            if game.gameOver, game.mode != .tutorial {
                gameOverOverlay
            }

            if game.mode == .tutorial, game.tutorialStep == 4 {
                tutorialCompleteOverlay
            }
        }
        .onDisappear {
            game.stopGame()
        }
        .onChange(of: game.gameOver) { _ in
            guard game.gameOver else { return }
            guard let winnerIndex = winnerIndex else { return }
            let shouldCelebrate = game.mode == .twoPlayer || winnerIndex == 0
            guard shouldCelebrate else { return }

            celebrateWinner.toggle()
            withAnimation(.easeInOut(duration: 0.8)) {
                showBoardGlow = true
            }

            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeInOut(duration: 0.8)) {
                    showBoardGlow = false
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var winnerIndex: Int? {
        if game.playerScore > game.aiScore {
            return 0
        }
        if game.aiScore > game.playerScore {
            return 1
        }
        return nil
    }

    private var tutorialCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("You're Ready!")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))

                Text("Objective: maximize your score by capturing more seeds than your opponent.")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
                    .frame(maxWidth: 420)

                Button("Start Playing") {
                    dismiss()
                }
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .padding(.horizontal, 26)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.95, green: 0.91, blue: 0.86))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 6)
                )
                .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                .buttonStyle(.plain)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(red: 0.98, green: 0.96, blue: 0.92))
            )
        }
    }

    private func pitsRow(indices: [Int], pitSize: CGFloat, isPlayerRow: Bool) -> some View {
        HStack(spacing: 12) {
            ForEach(indices, id: \.self) { index in
                PitView(
                    count: game.pits[index],
                    isClickable: isPitTappable(index: index, isPlayerRow: isPlayerRow),
                    isDimmed: isPitDimmed(index: index, isPlayerRow: isPlayerRow),
                    isHighlighted: game.highlightedIndex == index,
                    highlightMode: game.highlightMode
                ) {
                    game.handlePlayerTap(at: index)
                }
                .frame(width: pitSize, height: pitSize)
            }
        }
    }

    private func isPitTappable(index: Int, isPlayerRow: Bool) -> Bool {
        guard !game.gameOver else { return false }
        if game.mode == .tutorial {
            if game.isSowing {
                return game.tutorialStep == 3 && index == game.tutorialExpectedIndex && game.pits[index] == 4
            }
            return index == game.tutorialExpectedIndex
        }
        if game.isSowing {
            return game.pits[index] == 4 && (game.mode == .twoPlayer ? true : isPlayerRow)
        }
        if game.mode == .twoPlayer {
            if game.currentPlayer == 0 {
                return isPlayerRow && game.pits[index] > 0
            }
            return !isPlayerRow && game.pits[index] > 0
        }
        return isPlayerRow && game.currentPlayer == 0 && game.pits[index] > 0
    }

    private func isPitDimmed(index: Int, isPlayerRow: Bool) -> Bool {
        guard !game.isSowing, !game.gameOver else { return false }
        if game.mode == .twoPlayer {
            if game.currentPlayer == 0 {
                return !isPlayerRow
            }
            return isPlayerRow
        }
        guard game.currentPlayer == 0 else { return false }
        if isPlayerRow {
            return !isPitTappable(index: index, isPlayerRow: isPlayerRow)
        }
        return true
    }

    private var boardTurnHighlight: some View {
        let highlightColor = Color.white.opacity(0.22)
        return AnyView(
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [highlightColor, Color.clear],
                            startPoint: .bottom,
                            endPoint: .center
                        )
                    )
                    .opacity(game.currentPlayer == 0 ? 1 : 0)
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [highlightColor, Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .opacity(game.currentPlayer == 1 ? 1 : 0)
            }
        )
    }

    private var statusTextColor: Color {
        let message = game.statusMessage.lowercased()
        if message.contains("bonus") || message.contains("captured") {
            return Color(red: 0.66, green: 0.16, blue: 0.16)
        }
        if game.currentPlayer == 1 || game.statusMessage.lowercased().contains("ai") {
            return Color(red: 0.16, green: 0.36, blue: 0.70)
        }
        return Color(red: 0.20, green: 0.45, blue: 0.26)
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(game.statusMessage)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))

                Button("Play Again") {
                    game.resetGame()
                }
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.95, green: 0.91, blue: 0.86))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 6)
                )
                .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
                .buttonStyle(.plain)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.98, green: 0.96, blue: 0.92))
            )
        }
    }
}
