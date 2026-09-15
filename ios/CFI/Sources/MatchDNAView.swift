import SwiftUI

struct MatchDNAView: View {
    let match = MockData.match
    let stats = MockData.dna

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    ScreenHeader(title: "CFI")

                    HStack {
                        teamHead(match.homeTeam)
                        Spacer()
                        Text("Match DNA").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.textSecondary)
                        Spacer()
                        teamHead(match.awayTeam)
                    }

                    CardContainer {
                        VStack(spacing: 14) {
                            ForEach(stats) { stat in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stat.label).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                                    HStack(spacing: 8) {
                                        barView(value: stat.homeValue, color: Theme.green, alignment: .trailing)
                                        Text("\(stat.homeValue)").font(.system(size: 11)).foregroundColor(Theme.textSecondary).frame(width: 24)
                                        Text("\(stat.awayValue)").font(.system(size: 11)).foregroundColor(Theme.textSecondary).frame(width: 24)
                                        barView(value: stat.awayValue, color: Theme.red, alignment: .leading)
                                    }
                                }
                            }
                        }
                    }

                    CardContainer {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Form (Last 5)").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                            HStack {
                                formBadges(["W","W","D","L","W"], color: Theme.green)
                                Spacer()
                                formBadges(["L","D","W","W","L"], color: Theme.red)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func teamHead(_ name: String) -> some View {
        VStack(spacing: 4) {
            Circle().fill(Theme.card).frame(width: 40, height: 40)
                .overlay(Image(systemName: "shield.fill").foregroundColor(Theme.textTertiary))
            Text(name).font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
        }
    }

    private func barView(value: Int, color: Color, alignment: Alignment) -> some View {
        GeometryReader { geo in
            ZStack(alignment: alignment) {
                Capsule().fill(Color.white.opacity(0.06))
                Capsule().fill(color)
                    .frame(width: geo.size.width * CGFloat(value) / 100)
            }
        }
        .frame(height: 8)
    }

    private func formBadges(_ results: [String], color: Color) -> some View {
        HStack(spacing: 4) {
            ForEach(results, id: \.self) { r in
                Text(r).font(.system(size: 11, weight: .bold)).foregroundColor(.black)
                    .frame(width: 22, height: 22)
                    .background(r == "W" ? Theme.green : (r == "D" ? Theme.amber : Theme.red))
                    .cornerRadius(6)
            }
        }
    }
}
