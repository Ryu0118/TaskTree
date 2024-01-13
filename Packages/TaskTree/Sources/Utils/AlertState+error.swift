import Foundation
import SwiftUINavigation

public extension AlertState {
    static func error(_ error: some Error) -> Self {
        AlertState {
            TextState("An error has occurred", bundle: .module)
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK")
            }
        } message: {
            TextState(error.localizedDescription)
        }
    }
}
