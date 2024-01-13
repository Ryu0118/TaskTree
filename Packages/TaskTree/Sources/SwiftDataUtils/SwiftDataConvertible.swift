import Foundation
import SwiftData

public protocol SwiftDataConvertible {
    associatedtype Model: PersistentModel
    func convert() -> Model
}
