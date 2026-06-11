import SwiftUI
import Combine
import AudioToolbox
import UIKit

struct GameRules {
    static let totalPits = 14
    static let seedsPerPit = 6
    static let animationDelay: UInt64 = 500_000_000
    static let aiDelay: UInt64 = 600_000_000
    static let sowOrder = [0, 1, 2, 3, 4, 5, 6, 13, 12, 11, 10, 9, 8, 7]
    static let sowIndexMap = Dictionary(uniqueKeysWithValues: sowOrder.enumerated().map { ($0.element, $0.offset) })
}

enum PitHighlightMode {
    case sow
    case pickupSow
    case pickupScore
}

enum GameMode {
    case vsComputer
    case twoPlayer
    case tutorial
}

// MARK: Difficulty

enum AIDifficulty: String, CaseIterable {
    case easy = "Easy"
    case hard = "Hard"
}

@MainActor
class VamanaGuntaluGame: ObservableObject {

    @Published var pits: [Int]
    @Published var playerScore = 0
    @Published var aiScore = 0
    @Published var currentPlayer = 0
    @Published var statusMessage = "Your Turn"
    @Published var isSowing = false
    @Published var gameOver = false
    @Published var highlightedIndex: Int?
    @Published var highlightMode: PitHighlightMode = .sow
    @Published var tutorialStep: Int = 0
    @Published var tutorialMessage: String = ""
    let mode: GameMode
    // MARK: Difficulty
    let difficulty: AIDifficulty
    private var aiTask: Task<Void, Never>?
    private var sowTask: Task<Void, Never>?
    private var tutorialAutoSowTask: Task<Void, Never>?
    private var tutorialPausedHand: Int?
    private var tutorialPausedPtr: Int?
    private var tutorialAwaitingBonus = false

    init(mode: GameMode = .vsComputer, difficulty: AIDifficulty = .hard) {
        self.mode = mode
        self.difficulty = difficulty
        self.pits = Array(repeating: GameRules.seedsPerPit, count: GameRules.totalPits)
        if mode == .twoPlayer {
            statusMessage = "Player 1 Turn"
        }
        if mode == .tutorial {
            setupTutorialStep0()
        }
    }

    func resetGame() {
        aiTask?.cancel()
        aiTask = nil
        sowTask?.cancel()
        sowTask = nil
        tutorialAutoSowTask?.cancel()
        tutorialAutoSowTask = nil
        tutorialPausedHand = nil
        tutorialPausedPtr = nil
        pits = Array(repeating: GameRules.seedsPerPit, count: GameRules.totalPits)
        playerScore = 0
        aiScore = 0
        currentPlayer = 0
        statusMessage = mode == .twoPlayer ? "Player 1 Turn" : "Your Turn"
        gameOver = false
        isSowing = false
        highlightedIndex = nil
        if mode == .tutorial {
            setupTutorialStep0()
        }
    }

    func handlePlayerTap(at index: Int) {
        guard (0..<GameRules.totalPits).contains(index),
              pits[index] > 0 else { return }
        if mode == .vsComputer && index > 6 { return }
        if mode == .tutorial, index != tutorialExpectedIndex { return }

        if isSowing {
            if pits[index] == 4 && isBonusAllowed(index: index) {
                bonusCapture(at: index)
            }
            return
        }

        guard isIndexForCurrentPlayer(index) else { return }
        if mode == .tutorial, tutorialStep == 0 {
            tutorialStep = 1
            tutorialMessage = "Seeds move counter-clockwise, one by one."
        }
        makeMove(from: index)
    }

    private func makeMove(from index: Int) {
        startSowing(from: index)
    }

    private func startSowing(from index: Int) {
        isSowing = true
        if mode != .tutorial {
            if currentPlayer == 1 {
                statusMessage = mode == .twoPlayer ? "Player 2 Sowing..." : "Computer Sowing..."
            } else {
                statusMessage = mode == .twoPlayer ? "Player 1 Sowing..." : "Sowing..."
            }
        }

        sowTask?.cancel()
        sowTask = Task {
            await sow(from: index)
        }
    }

    private func sow(from index: Int) async {
        if Task.isCancelled { return }
        var hand = pits[index]
        highlightMode = .pickupSow
        highlightedIndex = index
        AudioServicesPlaySystemSound(1103)
        withAnimation(.easeInOut) {
            pits[index] = 0
        }
        try? await Task.sleep(nanoseconds: 500_000_000)
        if Task.isCancelled { return }
        if mode == .tutorial, tutorialStep == 3, tutorialPausedHand == nil {
            tutorialPausedHand = hand
            tutorialPausedPtr = index
            highlightMode = .sow
            highlightedIndex = tutorialExpectedIndex
            return
        }
        var ptr = index

        while hand > 0 {
            if Task.isCancelled { return }
            ptr = nextIndex(after: ptr)
            highlightMode = .sow
            highlightedIndex = ptr
            AudioServicesPlaySystemSound(1104)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                pits[ptr] += 1
            }
            try? await Task.sleep(nanoseconds: GameRules.animationDelay)
            if Task.isCancelled { return }
            hand -= 1
        }

        await handleLanding(at: ptr)
    }

    private func handleLanding(at lastIndex: Int) async {
        if Task.isCancelled { return }
        let landingNext = nextIndex(after: lastIndex)

        if pits[landingNext] > 0 {
            try? await Task.sleep(nanoseconds: GameRules.animationDelay)
            if Task.isCancelled { return }
            await sow(from: landingNext)
        } else {
            let captureIndex = nextIndex(after: landingNext)
            let captured = pits[captureIndex]
            highlightMode = .pickupScore
            highlightedIndex = captureIndex
            AudioServicesPlaySystemSound(1308)
            withAnimation(.easeInOut) {
                pits[captureIndex] = 0
            }

            addToScore(captured: captured)
            try? await Task.sleep(nanoseconds: 500_000_000)
            if mode == .tutorial {
                handleTutorialAfterSow(captureOccurred: true)
            } else {
                endTurn()
            }
        }
        if mode == .tutorial, tutorialStep == 1 {
            handleTutorialAfterSow(captureOccurred: false)
        }
    }

    private func addToScore(captured: Int) {
        guard captured > 0 else { return }
        if currentPlayer == 0 {
            playerScore += captured
        } else {
            aiScore += captured
        }
    }

    private func endTurn() {
        isSowing = false
        highlightedIndex = nil
        sowTask = nil

        if mode == .tutorial { return }
        if checkGameOver() { return }

        currentPlayer = currentPlayer == 0 ? 1 : 0

        if mode == .twoPlayer {
            statusMessage = currentPlayer == 0 ? "Player 1 Turn" : "Player 2 Turn"
        } else if currentPlayer == 1 {
            statusMessage = "Computer Thinking..."
            aiTask?.cancel()
            aiTask = Task {
                try? await Task.sleep(nanoseconds: GameRules.aiDelay)
                guard !Task.isCancelled else { return }
                guard currentPlayer == 1, !gameOver else { return }
                statusMessage = "Computer Sowing..."
                performComputerMove()
            }
        } else {
            statusMessage = "Your Turn"
        }
    }

    private func performComputerMove() {
        guard !gameOver else { return }

        if let index = chooseRandomMove() {
            makeMove(from: index)
        } else {
            endTurn()
        }
    }

    private func chooseRandomMove() -> Int? {
        let candidates = (7...13).filter { pits[$0] > 0 }
        guard !candidates.isEmpty else { return nil }

        // MARK: Difficulty
        switch difficulty {
        case .easy:
            return candidates.randomElement()
        case .hard:
            let bestCapture = candidates.map { index in
                (index: index, capture: simulateCapture(from: index))
            }
            .max { $0.capture < $1.capture }

            if let best = bestCapture, best.capture > 0 {
                return best.index
            }

            return candidates.randomElement()
        }
    }

    private func simulateCapture(from index: Int) -> Int {
        var simulated = pits

        var hand = simulated[index]
        simulated[index] = 0
        var ptr = index

        while hand > 0 {
            ptr = nextIndex(after: ptr)
            simulated[ptr] += 1
            hand -= 1
        }

        let landingNext = nextIndex(after: ptr)

        if simulated[landingNext] == 0 {
            let captureIndex = nextIndex(after: landingNext)
            return simulated[captureIndex]
        }

        return 0
    }

    private func nextIndex(after index: Int) -> Int {
        guard let position = GameRules.sowIndexMap[index] else {
            return (index + 1) % GameRules.totalPits
        }
        let nextPosition = (position + 1) % GameRules.totalPits
        return GameRules.sowOrder[nextPosition]
    }

    private func checkGameOver() -> Bool {
        if mode == .tutorial { return false }
        let playerSide = pits[0...6].reduce(0, +)
        let aiSide = pits[7...13].reduce(0, +)

        if playerSide == 0 || aiSide == 0 {
            playerScore += playerSide
            aiScore += aiSide
            pits = Array(repeating: 0, count: GameRules.totalPits)
            gameOver = true

            if playerScore > aiScore {
                statusMessage = mode == .twoPlayer ? "Player 1 Wins!" : "You Win!"
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                // MARK: High Score
                if mode == .vsComputer {
                    let margin = playerScore - aiScore
                    let bestScore = UserDefaults.standard.integer(forKey: "vg_bestScore")
                    let bestMargin = UserDefaults.standard.integer(forKey: "vg_bestMargin")
                    if playerScore > bestScore || (playerScore == bestScore && margin > bestMargin) {
                        UserDefaults.standard.set(playerScore, forKey: "vg_bestScore")
                        UserDefaults.standard.set(margin, forKey: "vg_bestMargin")
                    }
                }
            } else if aiScore > playerScore {
                statusMessage = mode == .twoPlayer ? "Player 2 Wins!" : "Computer Wins!"
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                statusMessage = "Draw!"
            }
            return true
        }
        return false
    }

    private func bonusCapture(at index: Int) {
        highlightMode = .pickupScore
        highlightedIndex = index
            AudioServicesPlaySystemSound(1308)
            withAnimation(.easeInOut) {
                pits[index] = 0
            }
        if index <= 6 {
            playerScore += 4
            statusMessage = mode == .twoPlayer ? "Player 1 Bonus +4" : "Player Bonus +4"
        } else {
            aiScore += 4
            statusMessage = mode == .twoPlayer ? "Player 2 Bonus +4" : "Computer Bonus +4"
        }
        Task {
            let delay: UInt64 = mode == .tutorial ? 800_000_000 : 2_000_000_000
            try? await Task.sleep(nanoseconds: delay)
            if highlightedIndex == index {
                highlightedIndex = nil
            }
            guard !gameOver else { return }
            if mode == .tutorial, tutorialStep == 3 {
                tutorialAwaitingBonus = false
                resumeTutorialSowIfNeeded()
                return
            }
            if isSowing {
                if currentPlayer == 1 {
                    statusMessage = mode == .twoPlayer ? "Player 2 Sowing..." : "Computer Sowing..."
                } else {
                    statusMessage = mode == .twoPlayer ? "Player 1 Sowing..." : "Sowing..."
                }
            }
        }
        if mode != .tutorial {
            _ = checkGameOver()
        }
    }

    private func isIndexForCurrentPlayer(_ index: Int) -> Bool {
        if mode == .twoPlayer {
            return (currentPlayer == 0 && index <= 6) || (currentPlayer == 1 && index >= 7)
        }
        return currentPlayer == 0 && index <= 6
    }

    private func isBonusAllowed(index: Int) -> Bool {
        if mode == .twoPlayer {
            return true
        }
        return index <= 6
    }

    func stopGame() {
        aiTask?.cancel()
        aiTask = nil
        sowTask?.cancel()
        sowTask = nil
        tutorialAutoSowTask?.cancel()
        tutorialAutoSowTask = nil
        tutorialPausedHand = nil
        tutorialPausedPtr = nil
        tutorialAwaitingBonus = false
        isSowing = false
        highlightedIndex = nil
    }

    var tutorialExpectedIndex: Int? {
        switch tutorialStep {
        case 0, 2:
            return 2
        case 3:
            return 1
        default:
            return nil
        }
    }

    private func setupTutorialStep0() {
        pits = [0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        playerScore = 0
        aiScore = 0
        currentPlayer = 0
        gameOver = false
        isSowing = false
        tutorialStep = 0
        tutorialMessage = "Tap the highlighted pit to begin sowing."
        highlightMode = .sow
        highlightedIndex = 2
        tutorialPausedHand = nil
        tutorialPausedPtr = nil
        tutorialAwaitingBonus = false
    }

    private func setupTutorialStep2() {
        pits = [0, 0, 1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0]
        playerScore = 0
        aiScore = 0
        currentPlayer = 0
        gameOver = false
        isSowing = false
        tutorialStep = 2
        tutorialMessage = "If the next pit is empty, you capture from the following pit."
        highlightMode = .sow
        highlightedIndex = 2
        tutorialPausedHand = nil
        tutorialPausedPtr = nil
        tutorialAwaitingBonus = false
    }

    private func setupTutorialStep3() {
        pits = [0, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        playerScore = 0
        aiScore = 0
        currentPlayer = 0
        gameOver = false
        isSowing = false
        tutorialStep = 3
        tutorialMessage = "If a pit on your side has exactly 4 seeds, tap during sowing to capture +4."
        highlightMode = .sow
        highlightedIndex = 1
        tutorialPausedHand = nil
        tutorialPausedPtr = nil
        tutorialAwaitingBonus = true
        tutorialAutoSowTask?.cancel()
        tutorialAutoSowTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            guard mode == .tutorial, tutorialStep == 3 else { return }
            startSowing(from: 2)
        }
    }

    private func handleTutorialAfterSow(captureOccurred: Bool) {
        isSowing = false
        highlightedIndex = nil
        sowTask = nil

        if tutorialStep == 1 {
            setupTutorialStep2()
            return
        }

        if tutorialStep == 2 {
            setupTutorialStep3()
            return
        }

        if tutorialStep == 3 {
            guard !tutorialAwaitingBonus else { return }
            tutorialStep = 4
            tutorialMessage = "You’re ready to play. Strategy is about patience and foresight."
            highlightedIndex = nil
        }
    }

    private func resumeTutorialSowIfNeeded() {
        guard let hand = tutorialPausedHand, let ptr = tutorialPausedPtr else { return }
        tutorialPausedHand = nil
        tutorialPausedPtr = nil
        sowTask?.cancel()
        sowTask = Task {
            await continueSow(hand: hand, from: ptr)
        }
    }

    private func continueSow(hand: Int, from index: Int) async {
        var hand = hand
        var ptr = index

        while hand > 0 {
            if Task.isCancelled { return }
            ptr = nextIndex(after: ptr)
            highlightMode = .sow
            highlightedIndex = ptr
            AudioServicesPlaySystemSound(1104)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                pits[ptr] += 1
            }
            try? await Task.sleep(nanoseconds: GameRules.animationDelay)
            if Task.isCancelled { return }
            hand -= 1
        }

        await handleLanding(at: ptr)
    }
}
