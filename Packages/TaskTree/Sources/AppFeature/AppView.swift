import SwiftUI
import TaskTreeFeature

public struct AppView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            TaskTreeView()
        }
    }
}
