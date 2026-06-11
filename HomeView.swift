import SwiftUI

struct HomeView: View {
    @State private var showAbout = false
    @State private var showHelp = false
    @State private var startTutorial = false
    @State private var gameMode: GameMode = .vsComputer
    @State private var difficulty: AIDifficulty = .hard
    @State private var bestScore: Int = 0
    @State private var bestMargin: Int = 0
    @State private var animateIntro = false

    var body: some View {
        NavigationStack {
            ZStack {
                SoftCreamBackground()

                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Text("Vamana Guntalu")
                            .font(.system(size: 46, weight: .semibold, design: .serif))
                            .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                            .offset(y: animateIntro ? 0 : 20)
                        Text("A South Indian Strategy Classic")
                            .font(.system(size: 18, weight: .medium, design: .serif))
                            .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
                    }

                    Text("Sow with care, capture with grace. A calm, thoughtful duel of seeds.")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
                        .frame(maxWidth: 460)

                    Picker("Mode", selection: $gameMode) {
                        Text("Vs Computer").tag(GameMode.vsComputer)
                        Text("Two Player").tag(GameMode.twoPlayer)
                    }
                    .environment(\.colorScheme, .light)
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 360)

                    if gameMode == .vsComputer {
                        // MARK: Difficulty
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(AIDifficulty.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .environment(\.colorScheme, .light)
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 360)

                        // MARK: High Score
                        if bestScore > 0 {
                            Text("Best: \(bestScore) (by \(bestMargin))")
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
                        }
                    }

                    NavigationLink {
                        GameView(mode: gameMode, difficulty: difficulty)
                    } label: {
                        Text("Play")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .padding(.horizontal, 36)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.90, green: 0.82, blue: 0.72))
                                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
                            )
                            .foregroundStyle(Color(red: 0.45, green: 0.36, blue: 0.28))
                    }
                    .buttonStyle(.plain)

                    NavigationLink(isActive: $startTutorial) {
                        GameView(mode: .tutorial)
                    } label: {
                        EmptyView()
                    }

                    HStack(spacing: 18) {
                        Button("Help") {
                            showHelp = true
                        }
                        Button("About") {
                            showAbout = true
                        }
                    }
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                }
                .padding(40)
                .opacity(animateIntro ? 1 : 0)
            }
            .sheet(isPresented: $showAbout) {
                AboutSheet()
            }
            .sheet(isPresented: $showHelp) {
                HelpSheet {
                    showHelp = false
                    startTutorial = true
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateIntro = true
                }
                // MARK: High Score
                bestScore = UserDefaults.standard.integer(forKey: "vg_bestScore")
                bestMargin = UserDefaults.standard.integer(forKey: "vg_bestMargin")
            }
        }
    }
}
