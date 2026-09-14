import SwiftUI

@main
struct CFIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

enum Health {
    case unknown, checking, up(String?), down
}

@MainActor
final class PredictionStore: ObservableObject {
    @Published var home = ""
    @Published var away = ""
    @Published var date = Date()
    @Published var language = "vi"

    @Published var isRunning = false
    @Published var prediction: Prediction?
    @Published var failure: String?
    @Published var health: Health = .unknown

    @Published var apiBase: String = UserDefaults.standard.string(forKey: "cfi.api") ?? CFIClient.defaultBase {
        didSet { UserDefaults.standard.set(apiBase, forKey: "cfi.api") }
    }

    private var client: CFIClient { CFIClient(base: apiBase) }

    func checkHealth() async {
        health = .checking
        do {
            let engine = try await client.status()
            health = .up(engine)
        } catch {
            health = .down
        }
    }

    func run() async {
        let homeName = home.trimmingCharacters(in: .whitespaces)
        let awayName = away.trimmingCharacters(in: .whitespaces)

        guard !homeName.isEmpty, !awayName.isEmpty else {
            failure = "Nhập cả đội nhà và đội khách rồi chạy lại."
            prediction = nil
            return
        }

        isRunning = true
        failure = nil
        prediction = nil

        do {
            prediction = try await client.predict(
                home: homeName,
                away: awayName,
                date: Format.apiDate(date),
                language: language
            )
        } catch {
            failure = error.localizedDescription
        }

        isRunning = false
    }
}

struct ContentView: View {
    @StateObject private var store = PredictionStore()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    FixtureEntry(store: store)

                    if store.isRunning {
                        StatusPanel(title: "Đang phân tích", message: fixtureSummary, isError: false, busy: true)
                    } else if let failure = store.failure {
                        StatusPanel(title: "Không dựng được dự đoán", message: failure, isError: true, busy: false)
                    }

                    if let prediction = store.prediction {
                        ResultView(prediction: prediction)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
            .background(Palette.ink.ignoresSafeArea())
            .navigationTitle("CFI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { HealthBadge(health: store.health) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(Palette.mist)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(store: store)
            }
        }
        .task { await store.checkHealth() }
    }

    private var fixtureSummary: String {
        "\(store.home) gặp \(store.away) · \(Format.apiDate(store.date))"
    }
}

// MARK: - Entry

struct FixtureEntry: View {
    @ObservedObject var store: PredictionStore

    private let languages: [(String, String)] = [
        ("vi", "Tiếng Việt"), ("en", "English"), ("zh", "中文"), ("th", "ไทย"), ("id", "Indonesia"),
    ]

    var body: some View {
        VStack(spacing: 10) {
            field("Đội nhà", text: $store.home)

            HStack(spacing: 12) {
                Rectangle().fill(Palette.line).frame(height: 1)
                Text("gặp").font(.system(size: 13)).foregroundColor(Palette.mist)
                Rectangle().fill(Palette.line).frame(height: 1)
            }

            field("Đội khách", text: $store.away)

            HStack(spacing: 10) {
                DatePicker("", selection: $store.date, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Palette.sodium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.turf))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.line))

                Picker("", selection: $store.language) {
                    ForEach(languages, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }
                .pickerStyle(.menu)
                .tint(Palette.chalk)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.turf))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.line))
            }

            Button {
                Task { await store.run() }
            } label: {
                Text(store.isRunning ? "Đang chạy" : "Phân tích trận này")
                    .font(.system(size: 17, weight: .heavy))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
            }
            .background(store.isRunning ? Palette.turfHigh : Palette.sodium)
            .foregroundColor(store.isRunning ? Palette.mist : Color(red: 0.13, green: 0.08, blue: 0.01))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(store.isRunning)
            .padding(.top, 4)
        }
        .padding(.top, 14)
    }

    private func field(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Palette.mist)
            TextField("", text: text)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Palette.chalk)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.turf))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.line))
    }
}

// MARK: - Chrome

struct HealthBadge: View {
    let health: Health

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(caption).font(.system(size: 13)).foregroundColor(Palette.mist)
        }
    }

    private var color: Color {
        switch health {
        case .unknown: return Palette.mist
        case .checking: return Palette.sodium
        case .up: return Palette.signal
        case .down: return Palette.flag
        }
    }

    private var caption: String {
        switch health {
        case .unknown: return "Máy chủ"
        case .checking: return "Đang kiểm tra"
        case let .up(engine): return engine ?? "Sẵn sàng"
        case .down: return "Không kết nối được"
        }
    }
}

struct StatusPanel: View {
    let title: String
    let message: String
    let isError: Bool
    let busy: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(isError ? Palette.flag : Palette.chalk)
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(Palette.mist)
                .fixedSize(horizontal: false, vertical: true)
            if busy {
                ProgressView()
                    .tint(Palette.sodium)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.turf))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isError ? Palette.flag.opacity(0.5) : Palette.line))
        .padding(.top, 20)
    }
}

// MARK: - Result

struct ResultView: View {
    let prediction: Prediction
    @State private var showRaw = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            verdictCard.padding(.top, 24)

            Text("Bốn thị trường cố định").sectionHeading().padding(.top, 28).padding(.bottom, 6)
            VStack(spacing: 0) {
                ForEach(prediction.markets) { reading in
                    Divider1()
                    MarketMeasure(reading: reading)
                }
                Divider1()
            }
            Text("Vạch trắng là Method A (thống kê lịch sử), vạch xanh là Method B (Match DNA). Thanh liền là xác suất Final sau hiệu chỉnh.")
                .font(.system(size: 13))
                .foregroundColor(Palette.mist)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)

            if !prediction.htScores.isEmpty || !prediction.ftScores.isEmpty {
                Text("Tỷ số khả dĩ").sectionHeading().padding(.top, 28).padding(.bottom, 12)
                HStack(alignment: .top, spacing: 12) {
                    period("Hiệp một", scores: prediction.htScores, expected: prediction.expectedHT)
                    period("Cả trận", scores: prediction.ftScores, expected: prediction.expectedFT)
                }
                if let path = prediction.mostLikelyPath {
                    HStack(spacing: 5) {
                        Text("Đường đi khả dĩ nhất").font(.system(size: 14)).foregroundColor(Palette.mist)
                        Text(path).font(.system(size: 14, weight: .semibold)).foregroundColor(Palette.chalk)
                    }
                    .padding(.top, 12)
                }
            }

            Text("Bằng chứng và chất lượng dữ liệu").sectionHeading().padding(.top, 28).padding(.bottom, 4)
            VStack(spacing: 0) {
                ForEach(Array(prediction.evidence.enumerated()), id: \.offset) { index, row in
                    if index > 0 { Divider1() }
                    ReadoutRow(label: row.0, value: row.1, tone: row.2)
                }
            }

            if !prediction.gates.isEmpty {
                Text("Cổng kiểm soát").sectionHeading().padding(.top, 28).padding(.bottom, 4)
                VStack(spacing: 0) {
                    ForEach(Array(prediction.gates.enumerated()), id: \.offset) { index, row in
                        if index > 0 { Divider1() }
                        ReadoutRow(label: row.0, value: row.1, tone: row.2)
                    }
                }
            }

            DisclosureGroup(isExpanded: $showRaw) {
                ScrollView(.horizontal) {
                    Text(prediction.raw.prettyPrinted)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Palette.mist)
                        .textSelection(.enabled)
                        .padding(12)
                }
                .frame(maxHeight: 320)
                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.turf))
            } label: {
                Text("Xem dữ liệu thô từ máy chủ")
                    .font(.system(size: 14))
                    .foregroundColor(Palette.mist)
            }
            .tint(Palette.mist)
            .padding(.top, 26)

            Text("Xác suất là phân phối của mô hình, không phải kịch bản chắc chắn của trận đấu.")
                .font(.system(size: 12))
                .foregroundColor(Palette.mist)
                .padding(.top, 30)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var verdictCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(prediction.verdict.phrase)
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(callColor)
                .fixedSize(horizontal: false, vertical: true)

            if let market = prediction.verdict.primaryMarket {
                HStack(spacing: 5) {
                    Text("Thị trường dẫn đầu").font(.system(size: 15)).foregroundColor(Palette.mist)
                    Text(Format.percent(prediction.verdict.primaryProbability).map { "\(market) \($0)" } ?? market)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Palette.chalk)
                }
            } else {
                Text("Chưa có thị trường nào vượt ngưỡng quyết định.")
                    .font(.system(size: 15))
                    .foregroundColor(Palette.mist)
            }

            Divider1().padding(.vertical, 6)

            Text([prediction.fixture, prediction.engine].compactMap { $0 }.joined(separator: " · "))
                .font(.system(size: 13))
                .foregroundColor(Palette.mist)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.turfHigh))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.line))
    }

    private var callColor: Color {
        switch prediction.verdict.call.uppercased() {
        case "BET": return Palette.signal
        case "LEAN": return Palette.sodium
        case "WATCH": return Palette.sky
        default: return Palette.mist
        }
    }

    private func period(_ title: String, scores: [Scoreline], expected: (home: Double?, away: Double?)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(Palette.chalk)
            Text("Bàn kỳ vọng \(Format.decimal(expected.home) ?? "—") / \(Format.decimal(expected.away) ?? "—")")
                .font(.system(size: 12))
                .foregroundColor(Palette.mist)

            if scores.isEmpty {
                Text("Không có").font(.system(size: 14)).foregroundColor(Palette.mist)
            } else {
                ForEach(scores) { row in
                    HStack {
                        Text(row.score).font(.system(size: 15)).foregroundColor(Palette.chalk)
                        Spacer()
                        Text(Format.percent(row.probability) ?? "—")
                            .font(.system(size: 15, weight: .semibold))
                            .monospacedDigit()
                            .foregroundColor(Palette.signal)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.turf))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.line))
    }
}

// MARK: - Settings

struct SettingsView: View {
    @ObservedObject var store: PredictionStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Địa chỉ Worker").font(.system(size: 13)).foregroundColor(Palette.mist)
                    TextField("", text: $draft)
                        .font(.system(size: 15))
                        .foregroundColor(Palette.chalk)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.turf))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.line))

                    HStack(spacing: 10) {
                        Button("Lưu") {
                            store.apiBase = draft.isEmpty ? CFIClient.defaultBase : draft
                            Task { await store.checkHealth() }
                            dismiss()
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Palette.sodium)
                        .foregroundColor(Color(red: 0.13, green: 0.08, blue: 0.01))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button("Về mặc định") {
                            draft = CFIClient.defaultBase
                            store.apiBase = CFIClient.defaultBase
                            Task { await store.checkHealth() }
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Palette.turfHigh)
                        .foregroundColor(Palette.chalk)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text("Ứng dụng chỉ đọc. Nó gửi tên đội và ngày thi đấu tới Worker, không lưu khoá bí mật nào trên máy và không gọi tới bất kỳ endpoint ghi dữ liệu nào.")
                        .font(.system(size: 13))
                        .foregroundColor(Palette.mist)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                }
                .padding(18)
            }
            .background(Palette.ink.ignoresSafeArea())
            .navigationTitle("Cài đặt máy chủ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }.tint(Palette.mist)
                }
            }
        }
        .onAppear { draft = store.apiBase }
    }
}
