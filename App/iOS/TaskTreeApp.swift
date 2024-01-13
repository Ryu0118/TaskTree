import SwiftUI
import AppFeature

@main
struct TaskTreeApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TaskTreeView()
            }
        }
    }
}
