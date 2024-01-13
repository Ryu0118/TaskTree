import Foundation

public struct Todo: Hashable, Identifiable {
    public let id: UUID
    public let children: [Todo]
    public let title: String
    public let createdAt: Date

    public init(id: UUID, children: [Todo], title: String, createdAt: Date) {
        self.id = id
        self.children = children
        self.title = title
        self.createdAt = createdAt
    }
}
