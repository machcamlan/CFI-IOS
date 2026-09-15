import SwiftUI

struct PredictionOutputView: View {
    enum Tab: String, CaseIterable { case markets = "Markets", fusion = "Fusion", insights = "Insights" }
    @State private var tab: Tab = .markets
    let match = MockData.match
    let markets = MockData.markets

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    ScreenHeader(title: "CFI")

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(match.homeTeam) vs \(match.awayTeam)")
                            .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                        Text("\(match.league) · \(match.kickoff)")
                            .font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    CardContainer {
                        VStack(spacing: 12) {
                            Text("CFI FUSION SCORE").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.textSecondary)
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.08), lineWidth: 10)
                                Circle().trim(from: 0, to: 0.78)
                                    .stroke(Theme.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                Text("78%").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                            }
                            .frame(width: 110, height: 110)

                            HStack {
                                metaItem("Data Quality", "92/100")
                                Spacer()
                                metaItem("Model Agreement", "HIGH")
                                Spacer()
                                metaItem("Prediction Grade", "A-")
                            }
                        }
                    }

                    Picker("", selection: $tab) {
                        ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)

                    if tab == .markets {
                        CardContainer {
                            VStack(spacing: 0) {
                                ForEach(markets) { row in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(row.market).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                            Text("\(row.prediction) · \(row.probability)% · \(row.edge)")
                                                .font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                                        }
                                        Spacer()
                                        SignalPill(signal: row.signal)
                                    }
                                    .padding(.vertical, 10)
                                    if row.id != markets.last?.id {
                                        Divider().background(Theme.cardBorder)
                                    }
                                }
                            }
                        }
                    } else if tab == .fusion {
                        VStack(spacing: 12) {
                            ForEach(MockData.fusions) { f in
                                CardContainer {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(f.title).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                                            Spacer()
                                            SignalPill(signal: f.signal)
                                        }
                                        Text("Fusion Probability: \(f.probability)%")
                                            .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.green)
                                        ForEach(f.checks, id: \.self) { c in
                                            Label(c, systemImage: "checkmark.circle.fill")
                                                .font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        CardContainer {
                            Text("Insights coming soon — model rationale, historical calibration, and edge sources will appear here.")
                                .font(.system(size: 13)).foregroundColor(Theme.textSecondary)
                        }
                    }

                    Text("Chỉ mang tính tham khảo. Quản lý vốn và cược có trách nhiệm.")
                        .font(.system(size: 10)).foregroundColor(Theme.textTertiary)
                }
                .padding(16)
            }
        }
    }

    private func metaItem(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 10)).foregroundColor(Theme.textTertiary)
        }
    }
}
