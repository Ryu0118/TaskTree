import Observation
import Foundation
import TodoClient
import SharedModel
import Dependencies
import SwiftUINavigation
import Utils
import SwiftUI

@Observable
final class TaskTreeModel {
    enum AlertAction {
    }

    var selectedChildModel: TaskTreeModel?
    var parent: Todo
    var children: [TaskTreeModel] = []
    var alert: AlertState<AlertAction>?

    init(parent: Todo?) {
        if let parent {
            self.parent = parent
            self.children = parent.children
                .map { TaskTreeModel(parent: $0) }
                .sorted { $0.parent.createdAt > $1.parent.createdAt }
        } else {
            @Dependency(\.todoClient) var todoClient
            do {
                self.parent = try todoClient.fetchRootTodo()
                children = self.parent.children
                    .map { TaskTreeModel(parent: $0) }
                    .sorted { $0.parent.createdAt > $1.parent.createdAt }
            } catch {
                fatalError("")
            }
        }
    }

    @ObservationIgnored
    @Dependency(\.todoClient) private var todoClient

    func selectChildModel(_ child: TaskTreeModel) {
        selectedChildModel = child
    }

    func addTask(_ todo: Todo) {
        do {
            try todoClient.appendTodos(todo: todo, parentTodo: parent)
            children.insert(TaskTreeModel(parent: todo), at: 0)
        } catch {
            alert = .error(error)
        }
    }
}

public struct TaskTreeView: View {
    @Bindable var model: TaskTreeModel

    public init() {
        model = TaskTreeModel(parent: nil)
    }

    init(model: TaskTreeModel) {
        self.model = model
    }

    public var body: some View {
        //        NavigationSplitView {
        //            List(model.children, id: \.parent) { childModel in
        //                if let todo = childModel.parent {
        //                    Text(todo.title)
        //                        .onTapGesture {
        //                            model.selectChildModel(childModel)
        //                        }
        //                }
        //            }
        //        } detail: {
        //            if let selectedChildModel = model.selectedChildModel {
        //                TaskTreeView(model: selectedChildModel)
        //            }
        //        }
        List(model.children, id: \.parent) { childModel in
            Text(childModel.parent.title)
                .onTapGesture {
                    model.selectChildModel(childModel)
                }
        }
        .navigationDestination(unwrapping: $model.selectedChildModel) { $childModel in
            TaskTreeView(model: $childModel.wrappedValue)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.addTask(
                        .init(
                            id: UUID(),
                            children: [],
                            title: "こんにちは",
                            createdAt: Date()
                        )
                    )
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

#Preview {
    TaskTreeView()
}
