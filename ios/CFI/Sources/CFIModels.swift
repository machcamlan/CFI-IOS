import Foundation

struct MatchInfo: Identifiable {
    let id = UUID()
    var homeTeam: String
    var awayTeam: String
    var league: String
    var kickoff: String
    var venue: String
    var dataStatus: String       // READY / PARTIAL / BLOCKED
    var strictPriorLocked: Bool
    var snapshotTime: String
}

struct MarketRow: Identifiable {
    let id = UUID()
    var market: String
    var prediction: String
    var probability: Int
    var edge: String
    var signal: Signal
}

struct FusionCard: Identifiable {
    let id = UUID()
    var title: String
    var probability: Int
    var signal: Signal
    var checks: [String]
}

struct DNAStat: Identifiable {
    let id = UUID()
    var label: String
    var homeValue: Int
    var awayValue: Int
}

struct LiveMarketRow: Identifiable {
    let id = UUID()
    var market: String
    var liveProbability: String
    var signal: Signal
}

struct EvidenceSource: Identifiable {
    let id = UUID()
    var name: String
    var connected: Bool
    var lastUpdated: String
}

struct SettlementRow: Identifiable {
    let id = UUID()
    var market: String
    var prediction: String
    var result: String // HIT / MISS
}

// MARK: - Mock data (replace with CFIClient API calls)

enum MockData {
    static let match = MatchInfo(
        homeTeam: "Plymouth Argyle", awayTeam: "Exeter City",
        league: "League One (England)",
        kickoff: "Sat, 14 Sep 2026 · 19:45 (GMT+7)",
        venue: "Home Park · 15°C, Clear",
        dataStatus: "READY", strictPriorLocked: true,
        snapshotTime: "14/09/2026 18:12"
    )

    static let markets: [MarketRow] = [
        .init(market: "FT Over 2.5", prediction: "Over", probability: 71, edge: "+8.2%", signal: .strong),
        .init(market: "FT BTTS", prediction: "Yes", probability: 65, edge: "+5.1%", signal: .strong),
        .init(market: "FT 1X2", prediction: "Home", probability: 54, edge: "+4.4%", signal: .watch),
        .init(market: "AH -0.5", prediction: "Home", probability: 57, edge: "+3.6%", signal: .watch),
        .init(market: "HT Over 1.5", prediction: "Over", probability: 46, edge: "+6.0%", signal: .watch),
        .init(market: "3+ HT", prediction: "Yes", probability: 21, edge: "+3.1%", signal: .pass),
        .init(market: "7+ FT", prediction: "Yes", probability: 8, edge: "+1.2%", signal: .pass),
    ]

    static let fusions: [FusionCard] = [
        .init(title: "Over 2.5 FT + BTTS Yes", probability: 61, signal: .strong,
              checks: ["Cross-market consistency", "Model agreement", "Data quality"]),
        .init(title: "Home +0.0 AH + Over 1.5 FT", probability: 69, signal: .watch,
              checks: ["Cross-market consistency", "Model agreement", "Data quality"]),
        .init(title: "Home Win + Over 2.5 FT", probability: 56, signal: .watch,
              checks: ["Cross-market consistency", "Model agreement"]),
    ]

    static let dna: [DNAStat] = [
        .init(label: "Attack", homeValue: 82, awayValue: 64),
        .init(label: "Defence", homeValue: 73, awayValue: 48),
        .init(label: "Form (Last 5)", homeValue: 60, awayValue: 52),
        .init(label: "Goal Scoring", homeValue: 71, awayValue: 58),
        .init(label: "HT Scoring", homeValue: 68, awayValue: 49),
        .init(label: "Clean Sheet", homeValue: 52, awayValue: 41),
        .init(label: "Tempo", homeValue: 76, awayValue: 55),
    ]

    static let liveMarkets: [LiveMarketRow] = [
        .init(market: "3+ HT", liveProbability: "34% ↑", signal: .watch),
        .init(market: "Over 1.5 HT", liveProbability: "62% ↑", signal: .strong),
        .init(market: "BTTS FT", liveProbability: "58% ↑", signal: .watch),
        .init(market: "7+ FT", liveProbability: "12% ↑", signal: .pass),
    ]

    static let evidenceSources: [EvidenceSource] = [
        .init(name: "AiScore", connected: true, lastUpdated: "14/09 18:10"),
        .init(name: "Sofascore", connected: true, lastUpdated: "14/09 18:09"),
        .init(name: "Football-Data", connected: true, lastUpdated: "14/09 18:05"),
        .init(name: "Bookmaker (Bet365)", connected: true, lastUpdated: "14/09 18:12"),
        .init(name: "CFI Historical DB", connected: true, lastUpdated: "14/09 18:11"),
    ]

    static let settlement: [SettlementRow] = [
        .init(market: "FT Over 2.5", prediction: "Over", result: "HIT"),
        .init(market: "FT BTTS", prediction: "Yes", result: "HIT"),
        .init(market: "FT 1X2", prediction: "Home", result: "HIT"),
        .init(market: "AH -0.5", prediction: "Home", result: "HIT"),
        .init(market: "HT Over 1.5", prediction: "Over", result: "MISS"),
        .init(market: "3+ HT", prediction: "Yes", result: "MISS"),
        .init(market: "7+ FT", prediction: "Yes", result: "MISS"),
    ]
}
