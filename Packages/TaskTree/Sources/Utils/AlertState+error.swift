import Foundation
import SwiftUINavigation

public extension AlertState {
    static func error<E: Error>(_ error: E) -> Self {
        AlertState {
            TextState("エラーが発生しました")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK")
            }
        } message: {
            TextState(error.localizedDescription)
        }
    }
}
