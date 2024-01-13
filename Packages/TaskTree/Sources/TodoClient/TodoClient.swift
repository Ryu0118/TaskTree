import Dependencies
import DependenciesMacros
import Foundation
import SwiftData
import SwiftDataModel
import SwiftDataUtils

@DependencyClient
public struct TodoClient {
    public var fetchRootTodo: @Sendable () throws -> Todo
    public var appendTodos: @Sendable (_ todo: Todo, _ parentTodo: Todo) throws -> Void
    public var deleteTodo: @Sendable (_ todo: Todo) throws -> Void
    public var fetchTodos: @Sendable (_ parentID: UUID) throws -> [Todo]
    public var toggleIsComplete: @Sendable (_ todo: Todo) throws -> Void
    public var fetchTodo: @Sendable (_ todoID: UUID) throws -> Todo
    public var remove: @Sendable (_ parentTodo: Todo, _ todos: [Todo]) throws -> Void
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

        @Sendable func fetchTodo(id: UUID) throws -> SwiftDataModel.Todo {
            let context = try context()
            guard let todo = try context.fetch(
                FetchDescriptor<SwiftDataModel.Todo>(
                    predicate: #Predicate {
                        $0.id == id
                    }
                )
            ).first
            else {
                throw TodoClientError.taskCannotBeFound
            }
            return todo
        }

        return Self(
            fetchRootTodo: {
                let context = try context()

                do {
                    return try fetchTodo(id: rootTodo.id)
                } catch let error as TodoClientError where error == .taskCannotBeFound {
                    context.insert(rootTodo)
                    try context.save()
                    return rootTodo
                } catch {
                    throw error
                }
            },
            appendTodos: { todo, parentTodo in
                let context = try context()
                parentTodo.children.append(todo)
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
            },
            fetchTodos: { id in
                let context = try context()
                return try context.fetch(
                    FetchDescriptor<SwiftDataModel.Todo>(
                        predicate: #Predicate {
                            $0.parent?.id == id
                        }
                    )
                )
            },
            toggleIsComplete: { todo in
                let context = try context()
                if todo.children.isEmpty {
                    if todo._isCompleted == nil {
                        todo._isCompleted = true
                    } else {
                        todo._isCompleted?.toggle()
                    }
                    try context.save()
                } else {
                    throw TodoClientError.taskCannotBeCompleted
                }
            },
            fetchTodo: { id in
                try fetchTodo(id: id)
            },
            remove: { parentTodo, todos in
                let context = try context()
                let todoIDs = todos.map(\.id)
                parentTodo.children.removeAll { todoIDs.contains($0.id) }
                try context.save()
            }
        )
    }
}

public enum TodoClientError: LocalizedError {
    case taskCannotBeCompleted
    case taskCannotBeFound

    public var errorDescription: String? {
        switch self {
        case .taskCannotBeCompleted:
            String(localized: "task-cannot-be-completed", bundle: .module)

        case .taskCannotBeFound:
            String(localized: "task-cannot-be-found", bundle: .module)
        }
    }
}

extension TodoClient: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue: Self = .live(storageType: .inMemory, shouldDeleteOldFile: true)
}

public extension DependencyValues {
    var todoClient: TodoClient {
        get { self[TodoClient.self] }
        set { self[TodoClient.self] = newValue }
    }
}
