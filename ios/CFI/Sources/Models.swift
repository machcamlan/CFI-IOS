import Foundation

/// The CFI prediction payload is deliberately loose: fields appear, disappear and
/// change shape between engine versions. Decoding it into fixed structs would make
/// the app fail on a payload the Worker considers perfectly valid, so it is decoded
/// as a tree and read by key instead.
enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .null
        }
    }

    subscript(key: String) -> JSONValue? {
        if case let .object(dict) = self { return dict[key] }
        return nil
    }

    /// Reads a nested path, returning nil the moment any step is missing.
    func path(_ keys: String...) -> JSONValue? {
        var node: JSONValue? = self
        for key in keys {
            node = node?[key]
            if node == nil { return nil }
        }
        if case .some(.null) = node { return nil }
        return node
    }

    /// A finite number, or nil. A missing probability must never become zero.
    var double: Double? {
        switch self {
        case let .number(value): return value.isFinite ? value : nil
        case let .string(value):
            guard let parsed = Double(value), parsed.isFinite else { return nil }
            return parsed
        default: return nil
        }
    }

    var int: Int? {
        guard let value = double else { return nil }
        return Int(value)
    }

    var text: String? {
        switch self {
        case let .string(value): return value.isEmpty ? nil : value
        case let .number(value): return String(value)
        case let .bool(value): return value ? "true" : "false"
        default: return nil
        }
    }

    var boolean: Bool? {
        if case let .bool(value) = self { return value }
        return nil
    }

    var list: [JSONValue] {
        if case let .array(items) = self { return items }
        return []
    }

    var prettyPrinted: String {
        guard let data = try? JSONSerialization.data(withJSONObject: raw, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else { return "—" }
        return string
    }

    private var raw: Any {
        switch self {
        case let .string(value): return value
        case let .number(value): return value
        case let .bool(value): return value
        case let .object(dict): return dict.mapValues { $0.raw }
        case let .array(items): return items.map { $0.raw }
        case .null: return NSNull()
        }
    }
}

// MARK: - Domain

/// The four frozen markets. This list is a contract, not a preference.
enum Market: String, CaseIterable, Identifiable {
    case threePlusHT = "3+ HT"
    case sevenPlusFT = "7+ FT"
    case otherHT = "Other HT"
    case otherFT = "Other FT"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .threePlusHT: return "Hiệp một từ 3 bàn"
        case .sevenPlusFT: return "Cả trận từ 7 bàn"
        case .otherHT: return "Một đội ghi 4+ hiệp một"
        case .otherFT: return "Một đội ghi 5+ cả trận"
        }
    }

    var definition: String {
        switch self {
        case .threePlusHT: return "Tổng bàn hiệp một ≥ 3"
        case .sevenPlusFT: return "Tổng bàn cả trận ≥ 7"
        case .otherHT: return "Một đội ghi ≥ 4 trong hiệp một"
        case .otherFT: return "Một đội ghi ≥ 5 cả trận"
        }
    }
}

struct MarketReading: Identifiable {
    let market: Market
    let methodA: Double?
    let methodB: Double?
    let final: Double?
    let confidence: String?
    let fairOdds: Double?

    var id: String { market.rawValue }
    var hasAnySignal: Bool { methodA != nil || methodB != nil || final != nil }

    /// How far the two methods disagree, in probability points. The whole point of
    /// showing A and B separately is to make this visible.
    var spread: Double? {
        guard let a = methodA, let b = methodB else { return nil }
        return abs(a - b)
    }
}

struct Scoreline: Identifiable {
    let score: String
    let probability: Double?
    var id: String { score }
}

struct Verdict {
    let call: String
    let primaryMarket: String?
    let primaryProbability: Double?

    var phrase: String {
        switch call.uppercased() {
        case "BET": return "Đủ điều kiện vào kèo"
        case "LEAN": return "Nghiêng về một hướng"
        case "WATCH": return "Theo dõi thêm"
        case "NO_BET": return "Không vào kèo"
        case "BLOCKED": return "Bị chặn bởi cổng kiểm soát"
        default: return call
        }
    }
}

struct Prediction {
    let verdict: Verdict
    let markets: [MarketReading]
    let htScores: [Scoreline]
    let ftScores: [Scoreline]
    let expectedHT: (home: Double?, away: Double?)
    let expectedFT: (home: Double?, away: Double?)
    let mostLikelyPath: String?
    let evidence: [(String, String, Tone)]
    let gates: [(String, String, Tone)]
    let engine: String?
    let fixture: String
    let raw: JSONValue
}

enum Tone {
    case neutral, good, warn, bad
}
