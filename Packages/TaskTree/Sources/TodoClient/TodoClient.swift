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
    public var fetchTodos: @Sendable (_ parentID: UUID) throws -> [SharedModel.Todo]
    public var toggleIsComplete: @Sendable (_ todoID: UUID) throws -> Void
    public var fetchTodo: @Sendable (_ todoID: UUID) throws -> SharedModel.Todo
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
                    return try fetchTodo(id: rootTodo.id).convert()
                } catch let error as TodoClientError {
                    if error == .taskCannotBeFound {
                        context.insert(rootTodo)
                        try context.save()
                        return rootTodo.convert()
                    } else {
                        throw error
                    }
                }
            },
            appendTodos: { todo, parentTodo in
                let context = try context()
                let parentPersistentTodo = try fetchTodo(id: parentTodo.id)
                parentPersistentTodo.children.append(todo.convert())
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
                .map { $0.convert() }
            },
            toggleIsComplete: { id in
                let context = try context()
                let todo = try fetchTodo(id: id)
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
                let todo = try fetchTodo(id: id)
                return todo.convert()
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

extension DependencyValues {
    public var todoClient: TodoClient {
        get { self[TodoClient.self] }
        set { self[TodoClient.self] = newValue }
    }
}
