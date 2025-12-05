import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 탭 1: 기록
            HomeView()
                .tabItem { Label("Home", systemImage: "drop") }
                
            // 탭 2: 보고서
            Color.clear
                .tabItem { Label("Insights", systemImage: "chart.bar") }

            // 탭 3: 내보내기
            Color.clear
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
            
            // 탭 4: 설정
            SettingsView()
                .tabItem { Label("Setting", systemImage: "gearshape") }
        }
    }
}
