import SwiftUI

struct LiveCFIView: View {
    let match = MockData.match
    let liveMarkets = MockData.liveMarkets

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    ScreenHeader(title: "CFI")

                    CardContainer {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(match.homeTeam).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                HStack(spacing: 6) {
                                    Circle().fill(Theme.red).frame(width: 6, height: 6)
                                    Text("LIVE · 32'").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.red)
                                }
                            }
                            Spacer()
                            Text("1 - 0").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            Text(match.awayTeam).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        }
                    }

                    CardContainer {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("LIVE MOMENTUM", systemImage: "bolt.fill")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(Theme.green)
                            Text("↑↑↑ High attacking pressure")
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    CardContainer {
                        HStack {
                            statBlock("Shots", "9 - 3")
                            Spacer()
                            statBlock("Dangerous Attacks", "32 - 14")
                            Spacer()
                            statBlock("Possession", "62% - 38%")
                        }
                    }

                    CardContainer {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Live Market Update").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                            ForEach(liveMarkets) { row in
                                HStack {
                                    Text(row.market).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                                    Spacer()
                                    Text(row.liveProbability).font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                                    SignalPill(signal: row.signal)
                                }
                            }
                        }
                    }

                    CardContainer {
                        Label("Entry quality: MEDIUM — live evidence đang tích lũy, tiếp tục theo dõi.",
                              systemImage: "info.circle.fill")
                            .font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(16)
            }
        }
    }

    private func statBlock(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 10)).foregroundColor(Theme.textTertiary)
        }
    }
}
