import SwiftUI

enum Theme {
    static let background = Color(hex: "0B1210")
    static let card = Color(hex: "14201C")
    static let cardBorder = Color.white.opacity(0.06)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.4)

    static let green = Color(hex: "22C55E")
    static let red = Color(hex: "EF4444")
    static let amber = Color(hex: "F59E0B")
    static let blue = Color(hex: "3B82F6")

    static func signalColor(_ signal: Signal) -> Color {
        switch signal {
        case .strong: return green
        case .watch: return amber
        case .pass: return .white.opacity(0.3)
        }
    }
}

enum Signal: String {
    case strong = "STRONG"
    case watch = "WATCH"
    case pass = "PASS"
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

// MARK: - Reusable pieces

struct SignalPill: View {
    let signal: Signal
    var body: some View {
        Text(signal.rawValue)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(signal == .pass ? .white.opacity(0.6) : .black)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Theme.signalColor(signal))
            .cornerRadius(6)
    }
}

struct CardContainer<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder, lineWidth: 1))
            .cornerRadius(16)
    }
}

struct ScreenHeader: View {
    let title: String
    var body: some View {
        HStack {
            Circle().fill(Theme.green.opacity(0.15)).frame(width: 32, height: 32)
                .overlay(Circle().fill(Theme.green).frame(width: 7, height: 7))
            Spacer()
            Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Spacer()
            Image(systemName: "gearshape.fill").foregroundColor(.white.opacity(0.7))
        }
    }
}
