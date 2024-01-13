import Foundation
import SwiftUINavigation

public extension AlertState {
    static func error<E: Error>(_ error: E) -> Self {
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
