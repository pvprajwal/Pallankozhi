import SwiftUI

struct PitView: View {
    let count: Int
    let isClickable: Bool
    let isDimmed: Bool
    let isHighlighted: Bool
    let highlightMode: PitHighlightMode
    let action: () -> Void

    private struct SeedLayout {
        let position: CGPoint
        let rotation: Angle
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.88, green: 0.80, blue: 0.70))
                    .overlay(
                        Circle()
                            .fill(highlightFill)
                    )
                    .overlay(
                        Circle()
                            .fill(isDimmed ? Color.white.opacity(0.45) : Color.clear)
                    )
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 5)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)

                VStack(spacing: 6) {
                    seedGrid

                    Text("\(count)")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(Color(red: 0.32, green: 0.22, blue: 0.16))
                }
                .padding(10)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isClickable)
        .accessibilityLabel("Pit")
        .accessibilityValue("\(count) seeds")
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(isClickable ? .isButton : .isStaticText)
        .animation(.easeInOut, value: count)
        .animation(.easeInOut, value: isHighlighted)
        .animation(.easeInOut, value: isDimmed)
    }

    private var accessibilityHintText: String {
        if isClickable {
            if isHighlighted {
                return "Highlighted. Double tap to sow." 
            }
            return "Double tap to sow this pit."
        }
        if isHighlighted {
            return "Highlighted, but not available."
        }
        return "Not available right now."
    }

    private var highlightFill: Color {
        guard isHighlighted else { return Color.clear }
        switch highlightMode {
        case .sow:
            return Color.green.opacity(0.22)
        case .pickupSow:
            return Color(red: 0.88, green: 0.12, blue: 0.14).opacity(0.35)
        case .pickupScore:
            return Color.blue.opacity(0.22)
        }
    }

    private var borderColor: Color {
        if isHighlighted {
            switch highlightMode {
            case .sow:
                return Color.green.opacity(0.75)
            case .pickupSow:
                return Color(red: 0.88, green: 0.12, blue: 0.14).opacity(0.95)
            case .pickupScore:
                return Color.blue.opacity(0.75)
            }
        }
        return isClickable ? Color.green.opacity(0.5) : Color.clear
    }

    private var seedGrid: some View {
        GeometryReader { proxy in
            let displayCount = min(count, 18)
            let size = min(proxy.size.width, proxy.size.height)
            let seedSize = min(25.0, max(12.0, size * 0.35))
            let layout = seedLayout(for: displayCount, in: size, seedSize: seedSize)

            ZStack {
                ForEach(0..<layout.count, id: \.self) { index in
                    let item = layout[index]
                    Image("seed")
                        .resizable()
                        .scaledToFit()
                        .frame(width: seedSize, height: seedSize)
                        .rotationEffect(item.rotation)
                        .position(x: item.position.x, y: item.position.y)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func rotationForSeed(at index: Int) -> Angle {
        let base = (index + 1) * 37 + count * 13
        let value = (base * 1103515245 &+ 12345) >> 16
        let degrees = Double(value % 50) - 25
        return .degrees(degrees)
    }

    private func seedLayout(for count: Int, in size: CGFloat, seedSize: CGFloat) -> [SeedLayout] {
        guard count > 0 else { return [] }
        let center = CGPoint(x: size / 2, y: size / 2)
        let maxRadius = max(0, (size / 1.114) - (seedSize / 1.314) - 2)
        let ringCounts = ringCounts(for: count)
        let ringRadii = ringRadii(for: ringCounts.count, maxRadius: maxRadius, count: count)
        var layouts: [SeedLayout] = []
        var globalIndex = 0

        for (ringIndex, ringCount) in ringCounts.enumerated() {
            guard ringCount > 0 else { continue }
            let radius = ringRadii[ringIndex]
            let angleStep = (2 * Double.pi) / Double(ringCount)
            let ringOffset = Double(ringIndex) * (angleStep / 2)

            for i in 0..<ringCount {
                let angle = (angleStep * Double(i)) + ringOffset + angleJitter(for: globalIndex)
                let jitteredRadius = radius + radiusJitter(for: globalIndex, baseRadius: radius)
                let x = center.x + CGFloat(cos(angle)) * jitteredRadius
                let y = center.y + CGFloat(sin(angle)) * jitteredRadius
                layouts.append(
                    SeedLayout(
                        position: CGPoint(x: x, y: y),
                        rotation: rotationForSeed(at: globalIndex)
                    )
                )
                globalIndex += 1
            }
        }

        return layouts
    }

    private func ringCounts(for count: Int) -> [Int] {
        if count <= 6 {
            return [count]
        }
        if count <= 12 {
            return [6, count - 6]
        }
        return [6, 6, count - 12]
    }

    private func ringRadii(for rings: Int, maxRadius: CGFloat, count: Int) -> [CGFloat] {
        if count == 1 {
            return [0]
        }
        switch rings {
        case 1:
            return [maxRadius * 0.55]
        case 2:
            return [maxRadius * 0.68, maxRadius * 0.38]
        default:
            return [maxRadius * 0.72, maxRadius * 0.48, maxRadius * 0.24]
        }
    }

    private func radiusJitter(for index: Int, baseRadius: CGFloat) -> CGFloat {
        let amount = max(2, baseRadius * 0.04)
        let value = pseudoRandomUnit(for: index + 7)
        return (value - 0.5) * 2 * amount
    }

    private func angleJitter(for index: Int) -> Double {
        let value = pseudoRandomUnit(for: index + 19)
        return (Double(value) - 0.5) * 0.48
    }

    private func pseudoRandomUnit(for seed: Int) -> CGFloat {
        var value = seed * 1103515245 &+ 12345
        value = (value >> 16) & 0x7fff
        return CGFloat(value % 1000) / 1000
    }
}
