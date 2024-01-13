import Foundation
import SwiftData

@Model
public final class Todo {
    @Attribute(.unique)
    public var id: UUID

    @Relationship(deleteRule: .cascade, inverse: \Todo.parent)
    public var children: [Todo] = []
    public var parent: Todo?
    public var title: String
    public var createdAt: Date

    @Transient
    public var isCompleted: Bool {
        get {
            if children.isEmpty {
                _isCompleted ?? false
            } else {
                children.allSatisfy(\.isCompleted)
            }
        }
        set {
            if children.isEmpty {
                _isCompleted = newValue
            }
        }
    }

    public var _isCompleted: Bool?

    public init(
        id: UUID,
        children: [Todo],
        title: String,
        createdAt: Date
    ) {
        self.id = id
        self.children = children
        self.title = title
        self.createdAt = createdAt
    }
}

public let rootTodo = Todo(
    id: UUID(uuidString: "4C0D55DC-95BD-405C-BC78-F09331422E57")!,
    children: [],
    title: "Root",
    createdAt: Date()
)

extension Todo {
    public var isRoot: Bool {
        rootTodo.id == id
    }
}
