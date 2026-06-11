import SwiftUI

#Preview {
    ContentView()
}

#Preview {
    GameView()
}

#Preview {
    HomeView()
}

#Preview {
    ZStack {
        Color(red: 0.98, green: 0.96, blue: 0.92)
        KolamBackground()
    }
}

#Preview {
    PitView(count: 6, isClickable: true, isDimmed: false, isHighlighted: true, highlightMode: .sow) {}
        .frame(width: 120, height: 120)
}

#Preview {
    ScoreView(playerScore: 24, aiScore: 18, isTwoPlayer: true, currentPlayer: 0, winnerIndex: 0, celebrateWinner: false)
}
