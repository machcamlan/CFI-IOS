import Foundation

enum CFIError: LocalizedError {
    case badURL
    case timedOut
    case offline(String)
    case rejected(status: String?, http: Int)
    case emptyBody

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Địa chỉ Worker không hợp lệ. Sửa lại trong phần Cài đặt."
        case .timedOut:
            return "Máy chủ không trả lời trong 45 giây. Mạng yếu hoặc Worker đang khởi động lại."
        case let .offline(detail):
            return "Không gọi được máy chủ. \(detail)"
        case .emptyBody:
            return "Máy chủ trả về phản hồi rỗng."
        case let .rejected(status, http):
            switch status?.uppercased() {
            case "EVIDENCE_INSUFFICIENT":
                return "Cơ sở dữ liệu chưa có đủ trận trước ngày này để chạy strict-prior. Thử ngày muộn hơn hoặc đội có nhiều lịch sử hơn."
            case "NOT_FOUND":
                return "Không tìm thấy trận khớp với hai tên đội này. Kiểm tra lại chính tả."
            case "RUNTIME_CONTRACT_ERROR":
                return "Máy chủ từ chối vì hợp đồng runtime không đạt. Đây là lỗi phía máy chủ, không phải do nhập liệu."
            case "INVALID_REQUEST":
                return "Máy chủ không đọc được yêu cầu. Kiểm tra lại ngày thi đấu."
            default:
                if http == 422 {
                    return "Bằng chứng không đủ hoặc đầu vào bị từ chối. Kết quả không được dựng thay bằng số giả."
                }
                if http >= 500 {
                    return "Máy chủ gặp lỗi khi chạy dự đoán. Thử lại sau ít phút."
                }
                return "Máy chủ trả về trạng thái \(status ?? String(http))."
            }
        }
    }
}

struct CFIClient {
    static let defaultBase = "https://cfi-football-intelligence.baoanhrat112020.workers.dev"

    var base: String

    private var root: URL? {
        var trimmed = base.trimmingCharacters(in: .whitespaces)
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        return URL(string: trimmed)
    }

    private func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 45
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }

    // MARK: - Status

    func status() async throws -> String? {
        guard let url = root?.appendingPathComponent("api/status") else { throw CFIError.badURL }
        let (data, response) = try await session().data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw CFIError.rejected(status: nil, http: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let body = try JSONDecoder().decode(JSONValue.self, from: data)
        return body.path("engine")?.text ?? body.path("runtime", "engine")?.text
    }

    // MARK: - Predict

    func predict(home: String, away: String, date: String, language: String) async throws -> Prediction {
        guard let url = root?.appendingPathComponent("api/predict") else { throw CFIError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "home": home,
            "away": away,
            "target_date": date,
            "language": language,
            "input_mode": "SINGLE_MATCH",
            "response_mode": "compact",
        ])

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session().data(for: request)
        } catch let error as URLError {
            if error.code == .timedOut { throw CFIError.timedOut }
            throw CFIError.offline(error.localizedDescription)
        }

        guard !data.isEmpty else { throw CFIError.emptyBody }
        let body = try JSONDecoder().decode(JSONValue.self, from: data)
        let http = (response as? HTTPURLResponse)?.statusCode ?? 0
        let serverStatus = body.path("status")?.text

        let ok = (200..<300).contains(http)
        let hasMarkets = body.path("markets") != nil
        if !ok || (serverStatus != nil && serverStatus?.uppercased() != "OK" && !hasMarkets) {
            throw CFIError.rejected(status: serverStatus, http: http)
        }

        return Self.parse(body: body, home: home, away: away, date: date)
    }

    // MARK: - Parsing

    static func parse(body: JSONValue, home: String, away: String, date: String) -> Prediction {
        let output = body.path("practicalOutput") ?? body.path("outputV3") ?? body.path("outputV2")

        let markets = Market.allCases.map { market -> MarketReading in
            let row = body.path("markets", market.rawValue)
            return MarketReading(
                market: market,
                methodA: row?.path("methodA")?.double,
                methodB: row?.path("methodB")?.double,
                final: row?.path("final")?.double,
                confidence: row?.path("confidence")?.text ?? row?.path("predictiveConfidence")?.text,
                fairOdds: row?.path("fairOdds")?.double
            )
        }

        let scoreline = output?.path("scoreline") ?? body.path("scoreline")
        let ht = Self.scores(from: scoreline?.path("ht"))
        let ft = Self.scores(from: scoreline?.path("ft"))

        let expected = output?.path("expectedGoals") ?? scoreline?.path("expectedGoals")
        let egHT = (expected?.path("ht", "home")?.double, expected?.path("ht", "away")?.double)
        let egFT = (expected?.path("ft", "home")?.double, expected?.path("ft", "away")?.double)

        var path: String?
        if let node = scoreline?.path("mostLikelyPath") {
            if let asText = node.text {
                path = asText
            } else if let htStep = node.path("ht")?.text, let ftStep = node.path("ft")?.text {
                path = "\(htStep) → \(ftStep)"
            }
        }

        let call = output?.path("final")?.text
            ?? body.path("verdict")?.text
            ?? body.path("status")?.text
            ?? "NO_BET"
        let primary = output?.path("primary")

        var fixtureParts = ["\(body.path("target", "home")?.text ?? home) gặp \(body.path("target", "away")?.text ?? away)"]
        fixtureParts.append(body.path("target", "targetDate")?.text ?? date)

        return Prediction(
            verdict: Verdict(
                call: call,
                primaryMarket: primary?.path("market")?.text,
                primaryProbability: primary?.path("probability")?.double
            ),
            markets: markets,
            htScores: ht,
            ftScores: ft,
            expectedHT: egHT,
            expectedFT: egFT,
            mostLikelyPath: path,
            evidence: Self.evidence(from: body.path("evidence")),
            gates: Self.gates(from: output?.path("gates") ?? body.path("gates")),
            engine: body.path("engine")?.text ?? body.path("runtime", "engine")?.text,
            fixture: fixtureParts.joined(separator: " · "),
            raw: body
        )
    }

    private static func scores(from node: JSONValue?) -> [Scoreline] {
        let rows = (node?.path("final") ?? node?.path("top3") ?? node?.path("top"))?.list ?? []
        return rows.prefix(3).compactMap { row in
            let label: String
            if let direct = row.path("score")?.text {
                label = direct
            } else if let h = row.path("home")?.int, let a = row.path("away")?.int {
                label = "\(h)-\(a)"
            } else {
                return nil
            }
            return Scoreline(score: label, probability: row.path("probability")?.double ?? row.path("p")?.double)
        }
    }

    private static func evidence(from node: JSONValue?) -> [(String, String, Tone)] {
        guard let node else { return [("Bằng chứng", "Máy chủ không trả về phần này", .warn)] }
        var rows: [(String, String, Tone)] = []
        let counts = node.path("counts")

        let unique = counts?.path("uniqueCanonical")?.int
        for (label, key) in [("Trận sân nhà", "homeFixtures"),
                             ("Trận sân khách", "awayFixtures"),
                             ("Đối đầu trực tiếp", "h2hFixtures"),
                             ("Trận gốc không trùng", "uniqueCanonical")] {
            let value = counts?.path(key)?.int
            rows.append((label, value.map(String.init) ?? "—", .neutral))
        }

        for (label, key) in [("Đủ tỷ số hiệp một", "htCoverage"), ("Đủ tỷ số cả trận", "ftCoverage")] {
            guard let raw = node.path(key)?.double ?? counts?.path(key)?.double else {
                rows.append((label, "—", .neutral))
                continue
            }
            let ratio: Double
            let shown: String
            if let unique, unique > 0, raw > 1 {
                ratio = raw / Double(unique)
                shown = "\(Int(raw))/\(unique)"
            } else {
                ratio = raw
                shown = Format.percent(raw) ?? "—"
            }
            rows.append((label, shown, ratio >= 0.9 ? .good : ratio >= 0.6 ? .warn : .bad))
        }

        if let quality = node.path("quality")?.text {
            rows.append(("Chất lượng", quality, .neutral))
        }
        if let eligible = node.path("sufficiency", "decisionEligible")?.boolean {
            rows.append(("Đủ để ra quyết định", eligible ? "Có" : "Chưa", eligible ? .good : .warn))
        }
        return rows
    }

    private static func gates(from node: JSONValue?) -> [(String, String, Tone)] {
        guard let node else { return [] }
        let labels: [(String, String)] = [
            ("strictPrior", "Strict prior"),
            ("consistency", "Nhất quán nội bộ"),
            ("evidenceSufficient", "Đủ bằng chứng"),
            ("fixtureIdentityVerified", "Xác minh danh tính trận"),
            ("marketCoherence", "Gắn kết giữa các thị trường"),
            ("threePlusHtCalibration", "Hiệu chỉnh 3+ HT"),
            ("verifiedOdds", "Kèo đã xác minh"),
            ("freshOdds", "Kèo còn mới"),
        ]
        return labels.compactMap { key, label in
            guard let value = node.path(key) else { return nil }
            if let flag = value.boolean {
                return (label, flag ? "Đạt" : "Không đạt", flag ? Tone.good : Tone.bad)
            }
            guard let text = value.text else { return nil }
            let upper = text.uppercased()
            let tone: Tone = upper.contains("PASS") || upper.contains("OK") ? .good
                : upper.contains("FAIL") || upper.contains("BLOCK") ? .bad : .warn
            return (label, text, tone)
        }
    }
}

enum Format {
    /// Returns nil for a missing value so the UI can show a gap. Never renders 0.0%
    /// for absent evidence.
    static func percent(_ value: Double?) -> String? {
        guard let value, value.isFinite else { return nil }
        return String(format: "%.1f%%", value * 100)
    }

    static func decimal(_ value: Double?, places: Int = 2) -> String? {
        guard let value, value.isFinite else { return nil }
        return String(format: "%.\(places)f", value)
    }

    static func apiDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
