import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            DiscoverPlaceholder()
                .tabItem { Label("Discover", systemImage: "safari.fill") }

            LiveCFIView()
                .tabItem { Label("Live", systemImage: "play.fill") }

            HistoryPlaceholder()
                .tabItem { Label("History", systemImage: "clock.fill") }

            CFILabPlaceholder()
                .tabItem { Label("CFI Lab", systemImage: "flask.fill") }
        }
        .tint(Theme.green)
        .preferredColorScheme(.dark)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.card)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Placeholder tabs (build out later)

struct DiscoverPlaceholder: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                ScreenHeader(title: "Discover")
                Spacer()
                Text("Danh sách trận sắp diễn ra sẽ hiển thị ở đây.")
                    .foregroundColor(Theme.textSecondary).font(.system(size: 13))
                Spacer()
            }.padding(16)
        }
    }
}

struct HistoryPlaceholder: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                ScreenHeader(title: "History")
                Spacer()
                Text("Lịch sử dự đoán & settlement sẽ hiển thị ở đây.")
                    .foregroundColor(Theme.textSecondary).font(.system(size: 13))
                Spacer()
            }.padding(16)
        }
    }
}

struct CFILabPlaceholder: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                ScreenHeader(title: "CFI Lab")
                Spacer()
                Text("Model version, calibration, source health, strict-prior audit.")
                    .foregroundColor(Theme.textSecondary).font(.system(size: 13))
                Spacer()
            }.padding(16)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
