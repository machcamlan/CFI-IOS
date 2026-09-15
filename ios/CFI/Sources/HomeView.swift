import SwiftUI

struct HomeView: View {
    let match = MockData.match
    @State private var goToPredict = false
    @State private var goToLive = false
    @State private var goToSettlement = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        ScreenHeader(title: "CFI")

                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(Theme.textTertiary)
                            Text("Search team, league or match…").foregroundColor(Theme.textTertiary)
                            Spacer()
                        }
                        .padding(14).background(Theme.card).cornerRadius(14)

                        CardContainer {
                            VStack(spacing: 14) {
                                HStack(spacing: 20) {
                                    teamBadge(match.homeTeam)
                                    Text("vs").foregroundColor(Theme.textSecondary)
                                    teamBadge(match.awayTeam)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Label(match.league, systemImage: "flag.fill")
                                    Label(match.kickoff, systemImage: "calendar")
                                    Label(match.venue, systemImage: "location.fill")
                                }
                                .font(.system(size: 13)).foregroundColor(Theme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        CardContainer {
                            VStack(spacing: 10) {
                                statusRow("Data Status", match.dataStatus, Theme.green, pill: true)
                                statusRow("Strict-Prior", match.strictPriorLocked ? "LOCKED" : "UNLOCKED", Theme.green, pill: true)
                                statusRow("Snapshot", match.snapshotTime, Theme.textSecondary, pill: false)
                            }
                        }

                        HStack(spacing: 10) {
                            NavigationLink(destination: PredictionOutputView()) {
                                actionLabel("PREDICT", "chart.bar.fill", Theme.blue, .black)
                            }
                            NavigationLink(destination: LiveCFIView()) {
                                actionLabel("LIVE", "play.fill", Theme.green, .black)
                            }
                            NavigationLink(destination: SettlementView()) {
                                actionLabel("SETTLEMENT", "doc.text.fill", Color.white.opacity(0.12), .white)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func teamBadge(_ name: String) -> some View {
        VStack(spacing: 8) {
            Circle().fill(Theme.card).frame(width: 56, height: 56)
                .overlay(Image(systemName: "shield.fill").foregroundColor(Theme.textTertiary))
            Text(name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                .multilineTextAlignment(.center).frame(width: 96)
        }
    }

    private func statusRow(_ label: String, _ value: String, _ color: Color, pill: Bool) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(Theme.textSecondary)
            Spacer()
            if pill {
                Text(value).font(.system(size: 12, weight: .bold)).foregroundColor(color)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(color.opacity(0.15)).cornerRadius(6)
            } else {
                Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(color)
            }
        }
    }

    private func actionLabel(_ title: String, _ icon: String, _ bg: Color, _ fg: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16, weight: .bold))
            Text(title).font(.system(size: 11, weight: .bold))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(bg).foregroundColor(fg).cornerRadius(12)
    }
}
