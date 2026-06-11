import SwiftUI

struct GameBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.96, blue: 0.92)
                .ignoresSafeArea()
            KolamBackground()
                .ignoresSafeArea()
            Color.black.opacity(0.05)
                .ignoresSafeArea()
        }
    }
}

struct SoftCreamBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.96, blue: 0.92)
                .ignoresSafeArea()
            KolamBackground()
                .ignoresSafeArea()
            Color.black.opacity(0.05)
                .ignoresSafeArea()
        }
    }
}

struct KolamBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let tile = max(220, size / 2.4)
            let cols = Int(ceil(proxy.size.width / tile)) + 1
            let rows = Int(ceil(proxy.size.height / tile)) + 1
            let totalWidth = CGFloat(cols) * tile
            let totalHeight = CGFloat(rows) * tile
            let startX = (proxy.size.width - totalWidth) / 2 + tile / 2
            let startY = (proxy.size.height - totalHeight) / 2 + tile / 2

            ZStack {
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<cols, id: \.self) { col in
                        Text("⌘")
                            .font(.system(size: tile * 0.65, weight: .light, design: .rounded))
                            .foregroundStyle(Color.brown.opacity(0.07))
                            .blur(radius: 2.2)
                            .position(
                                x: startX + CGFloat(col) * tile,
                                y: startY + CGFloat(row) * tile
                            )
                    }
                }
            }
        }
    }
}
