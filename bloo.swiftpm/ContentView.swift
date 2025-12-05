import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 탭 1: 기록
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "drop") }

            // 탭 2: 보고서
            NavigationStack { InsightView() }
                .tabItem { Label("Insights", systemImage: "chart.bar") }

            // 탭 3: 내보내기
            NavigationStack { ExportView() }
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }

            // 탭 4: 설정
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DiaryStore.preview())
    }
}
#endif
