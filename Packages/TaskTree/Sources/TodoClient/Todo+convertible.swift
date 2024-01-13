import Foundation
import SwiftDataUtils
import SwiftDataModel
import SharedModel

extension SharedModel.Todo: SwiftDataConvertible {
    public func convert() -> SwiftDataModel.Todo {
        SwiftDataModel.Todo(
            id: id,
            children: children.map { $0.convert() },
            title: title,
            createdAt: createdAt
        )
    }
}

extension SwiftDataModel.Todo {
    public func convert() -> SharedModel.Todo {
        SharedModel.Todo(
            id: id,
            children: children.map { $0.convert() },
            title: title,
            createdAt: createdAt,
            isCompleted: isCompleted
        )
    }
}

extension SharedModel.Todo {
    public var isRoot: Bool {
        rootTodo.id == id
    }
}
