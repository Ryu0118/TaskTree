import Foundation
import Dependencies
import DependenciesMacros
import SwiftDataUtils
import SwiftDataModel
import SharedModel
import SwiftData

@DependencyClient
public struct TodoClient {
    public var fetchRootTodo: @Sendable () throws -> SharedModel.Todo
    public var appendTodos: @Sendable (_ todo: SharedModel.Todo, _ parentTodo: SharedModel.Todo) throws -> Void
    public var deleteTodo: @Sendable (_ todo: SharedModel.Todo) throws -> Void
}

extension TodoClient: DependencyKey {
    public static let liveValue: TodoClient = .live()

    static func live(
        storageType: ModelContext.StorageType = .file,
        shouldDeleteOldFile: Bool = false
    ) -> Self {
        @Sendable func context() throws -> ModelContext {
            try ModelContext(
                for: SwiftDataModel.Todo.self,
                storageType: storageType,
                shouldDeleteOldFile: shouldDeleteOldFile
            )
        }
        return Self(
            fetchRootTodo: {
                let context = try context()
                let rootTodoID = rootTodo.id
                let convertedRootTodo = rootTodo.convert()

                let fetchedRootTodo = try context.fetch(
                    FetchDescriptor<SwiftDataModel.Todo>(
                        predicate: #Predicate {
                            $0.id == rootTodoID
                        }
                    )
                ).first

                if let fetchedRootTodo {
                    return fetchedRootTodo.convert()
                }
                else {
                    context.insert(rootTodo)
                    try context.save()
                    return convertedRootTodo
                }
            },
            appendTodos: { todo, parentTodo in
                let context = try context()
                let parentID = parentTodo.id
                let parentPersistentTodo = try context.fetch(
                    FetchDescriptor<SwiftDataModel.Todo>(
                        predicate: #Predicate {
                            $0.id == parentID
                        }
                    )
                ).first
                parentPersistentTodo?.children.append(todo.convert())
                try context.save()
            },
            deleteTodo: { todo in
                let context = try context()
                let id = todo.id
                try context.delete(
                    model: SwiftDataModel.Todo.self,
                    where: #Predicate {
                        $0.id == id
                    }
                )
            }
        )
    }
}

extension TodoClient: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue: Self = .live(storageType: .inMemory, shouldDeleteOldFile: true)
}

extension DependencyValues {
    public var todoClient: TodoClient {
        get { self[TodoClient.self] }
        set { self[TodoClient.self] = newValue }
    }
}
