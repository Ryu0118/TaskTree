import SwiftUI
import SwiftUINavigation

public extension View {
    func alert<Value>(
        _ state: Binding<AlertState<Value>?>,
        action handler: @escaping (Value?) async -> Void = { (_: Never?) async in },
        content: () -> some View
    ) -> some View {
        self.alert(
            (state.wrappedValue?.title).map(Text.init) ?? Text(verbatim: ""),
            isPresented: state.isPresent(),
            presenting: state.wrappedValue,
            actions: {
                content()
                ForEach($0.buttons) {
                    Button($0, action: handler)
                }
            },
            message: { $0.message.map { Text($0) } }
        )
    }
}
