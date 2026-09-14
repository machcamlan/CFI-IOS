import SwiftUI

// Floodlit pitch at night: deep green-black ground, sodium-lamp amber, pitch-line chalk.
enum Palette {
    static let ink = Color(red: 0.043, green: 0.078, blue: 0.071)
    static let turf = Color(red: 0.063, green: 0.118, blue: 0.102)
    static let turfHigh = Color(red: 0.086, green: 0.161, blue: 0.137)
    static let line = Color(red: 0.129, green: 0.212, blue: 0.184)
    static let chalk = Color(red: 0.906, green: 0.933, blue: 0.914)
    static let mist = Color(red: 0.549, green: 0.639, blue: 0.608)
    static let sodium = Color(red: 0.941, green: 0.643, blue: 0.180)
    static let signal = Color(red: 0.333, green: 0.839, blue: 0.627)
    static let flag = Color(red: 0.886, green: 0.341, blue: 0.298)
    static let sky = Color(red: 0.435, green: 0.718, blue: 0.847)

    static func tone(_ tone: Tone) -> Color {
        switch tone {
        case .neutral: return chalk
        case .good: return signal
        case .warn: return sodium
        case .bad: return flag
        }
    }
}

extension Text {
    func sectionHeading() -> some View {
        self.font(.system(size: 13, weight: .bold))
            .foregroundColor(Palette.sodium)
    }
}

/// The centrepiece: one axis per market carrying Method A, Method B and the
/// calibrated Final. Averaging them into a single number in the presentation layer
/// would hide exactly the disagreement the analyst needs to see.
struct MarketMeasure: View {
    let reading: MarketReading

    private let barHeight: CGFloat = 5
    private let tickHeight: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reading.market.label)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Palette.chalk)
                    Text(reading.market.definition)
                        .font(.system(size: 12))
                        .foregroundColor(Palette.mist)
                }
                Spacer(minLength: 10)
                if let final = Format.percent(reading.final) {
                    Text(final)
                        .font(.system(size: 27, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(Palette.signal)
                } else {
                    Text("chưa đủ dữ liệu")
                        .font(.system(size: 14))
                        .foregroundColor(Palette.mist)
                }
            }

            if reading.hasAnySignal {
                GeometryReader { geo in
                    let width = geo.size.width
                    ZStack(alignment: .topLeading) {
                        Capsule()
                            .fill(Palette.turfHigh)
                            .frame(height: barHeight)
                            .offset(y: (tickHeight - barHeight) / 2)

                        if let final = reading.final {
                            Capsule()
                                .fill(Palette.signal)
                                .frame(width: max(2, width * clamp(final)), height: barHeight)
                                .offset(y: (tickHeight - barHeight) / 2)
                        }

                        tick(at: reading.methodA, width: width, color: Palette.chalk, label: "A")
                        tick(at: reading.methodB, width: width, color: Palette.sky, label: "B")
                    }
                }
                .frame(height: tickHeight + 14)
            }

            FlowFooter(items: footerItems)
        }
        .padding(.vertical, 15)
    }

    @ViewBuilder
    private func tick(at value: Double?, width: CGFloat, color: Color, label: String) -> some View {
        if let value {
            let x = width * clamp(value)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: 3, height: tickHeight)
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Palette.mist)
                    .offset(x: 6, y: tickHeight - 2)
            }
            .offset(x: x - 1.5)
        }
    }

    private var footerItems: [(String, String)] {
        var items: [(String, String)] = []
        if let a = Format.percent(reading.methodA) { items.append(("Method A", a)) }
        if let b = Format.percent(reading.methodB) { items.append(("Method B", b)) }
        if let spread = Format.percent(reading.spread) { items.append(("Chênh lệch", spread)) }
        if let confidence = reading.confidence { items.append(("Độ tin cậy", confidence)) }
        if let odds = Format.decimal(reading.fairOdds) { items.append(("Fair odds", odds)) }
        if items.isEmpty { items.append(("Trạng thái", "máy chủ không trả về hai phương án")) }
        return items
    }

    private func clamp(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, 0), 1))
    }
}

/// Wraps label/value pairs across lines without relying on iOS 16+ Layout APIs.
struct FlowFooter: View {
    let items: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { index in
                HStack(spacing: 16) {
                    pair(items[index])
                    if index + 1 < items.count {
                        pair(items[index + 1])
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func pair(_ item: (String, String)) -> some View {
        HStack(spacing: 5) {
            Text(item.0)
                .font(.system(size: 13))
                .foregroundColor(Palette.mist)
            Text(item.1)
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(Palette.chalk)
        }
    }
}

struct ReadoutRow: View {
    let label: String
    let value: String
    var tone: Tone = .neutral

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Palette.mist)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .foregroundColor(Palette.tone(tone))
        }
        .padding(.vertical, 10)
    }
}

struct Divider1: View {
    var body: some View {
        Rectangle()
            .fill(Palette.line)
            .frame(height: 1)
    }
}
