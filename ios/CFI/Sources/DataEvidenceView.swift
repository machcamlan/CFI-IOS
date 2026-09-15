import SwiftUI

struct DataEvidenceView: View {
    enum Tab: String, CaseIterable { case sources = "Data Sources", match = "Match Info" }
    @State private var tab: Tab = .sources
    let sources = MockData.evidenceSources

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    ScreenHeader(title: "CFI")

                    Picker("", selection: $tab) {
                        ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)

                    if tab == .sources {
                        CardContainer {
                            VStack(spacing: 0) {
                                ForEach(sources) { s in
                                    HStack {
                                        Circle().fill(s.connected ? Theme.green : Theme.red).frame(width: 8, height: 8)
                                        Text(s.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                        Spacer()
                                        Text("Last updated: \(s.lastUpdated)")
                                            .font(.system(size: 10)).foregroundColor(Theme.textTertiary)
                                    }
                                    .padding(.vertical, 10)
                                    if s.id != sources.last?.id { Divider().background(Theme.cardBorder) }
                                }
                            }
                        }
                    } else {
                        CardContainer {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Match Verification").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                                verifyRow("Canonical teams", true)
                                verifyRow("Kickoff time", true)
                                verifyRow("League & season", true)
                                verifyRow("No data leakage", true)
                            }
                        }
                        CardContainer {
                            HStack {
                                Text("Snapshot Hash").font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                                Spacer()
                                Text("a3f9d2e7…c1b4").font(.system(size: 12, design: .monospaced)).foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func verifyRow(_ label: String, _ passed: Bool) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(Theme.textSecondary)
            Spacer()
            Text(passed ? "Verified" : "Failed")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(passed ? Theme.green : Theme.red)
        }
    }
}
