import SwiftUI

@main
struct MyApp: App {
    @StateObject var store = DiaryStore.preview()

    var body: some Scene {
    WindowGroup {
        ContentView().environmentObject(store) }
  }
}
