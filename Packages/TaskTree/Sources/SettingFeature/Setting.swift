import Foundation
import Observation
import SwiftUI

@Observable
public final class SettingModel {
    public init() {}
}

public struct SettingView: View {
    let modal: SettingModel
    
    public init(modal: SettingModel) {
        self.modal = modal
    }

    public var body: some View {
        List {
            NavigationLink {
                LicensesView()
            } label: {
                Text("License", bundle: .module)
            }
            Link(
                String(localized: "Source Code", bundle: .module),
                destination: URL(string: "https://github.com/Ryu0118/TaskTree")!
            )
            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    SettingView(modal: .init())
}
