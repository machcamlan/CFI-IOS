import SwiftUI

struct SettlementView: View {
    enum Tab: String, CaseIterable { case results = "Market Results", performance = "Performance" }
    @State private var tab: Tab = .results
    let match = MockData.match
    let rows = MockData.settlement

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    ScreenHeader(title: "CFI")

                    HStack {
                        Text(match.homeTeam).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                        Spacer()
                        Text("FT · 14 Sep 2026").font(.system(size: 11)).foregroundColor(Theme.textTertiary)
                        Spacer()
                        Text(match.awayTeam).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    }

                    Text("3 - 1").font(.system(size: 28, weight: .bold)).foregroundColor(.white)

                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.green)
                        Text("PREDICTION SETTLED").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.green)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Theme.green.opacity(0.12)).cornerRadius(12)

                    Picker("", selection: $tab) {
                        ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)

                    if tab == .results {
                        CardContainer {
                            VStack(spacing: 0) {
                                ForEach(rows) { r in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(r.market).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                            Text(r.prediction).font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                                        }
                                        Spacer()
                                        Text(r.result)
                                            .font(.system(size: 11, weight: .bold)).foregroundColor(.black)
                                            .padding(.horizontal, 10).padding(.vertical, 4)
                                            .background(r.result == "HIT" ? Theme.green : Theme.red)
                                            .cornerRadius(6)
                                    }
                                    .padding(.vertical, 8)
                                    if r.id != rows.last?.id { Divider().background(Theme.cardBorder) }
                                }
                            }
                        }
                    } else {
                        CardContainer {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("CFI Performance (Last 100 matches)").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                                perfRow("Hit Rate", "56.3%")
                                perfRow("Brier", "0.183")
                                perfRow("Log-loss", "0.612")
                                perfRow("ROI (sim)", "+8.7%")
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func perfRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
        }
    }
}
