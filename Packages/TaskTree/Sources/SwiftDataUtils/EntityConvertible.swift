import Foundation

public protocol EntityConvertible {
    associatedtype Entity: SwiftDataConvertible
    func convert() -> Entity
}
