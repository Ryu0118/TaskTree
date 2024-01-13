import SwiftUI
import Generated

public struct LicensesView: View {
    public var body: some View {
        List {
            ForEach(Licenses.all) { license in
                NavigationLink {
                    ScrollView {
                        Text(license.license)
                    }
                } label: {
                    Text(license.id)
                }
            }
        }
        .navigationTitle(String(localized: "License", bundle: .module))
    }
}
