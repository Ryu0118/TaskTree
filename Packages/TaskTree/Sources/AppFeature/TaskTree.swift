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
    var parentModel: TaskTreeModel?
    var parentTodo: Todo
    var children: [TaskTreeModel] {
        parentTodo.children
            .map { TaskTreeModel(parentTodo: $0, parentModel: self) }
            .sorted { $0.parentTodo.createdAt > $1.parentTodo.createdAt }
    }
    var alert: AlertState<AlertAction>?

    init(parentTodo: Todo?, parentModel: TaskTreeModel?) {
        self.parentModel = parentModel
        if let parentTodo {
            self.parentTodo = parentTodo
        } else {
            @Dependency(\.todoClient) var todoClient
            do {
                self.parentTodo = try todoClient.fetchRootTodo()
            } catch {
                fatalError("")
            }
        }
    }

    @ObservationIgnored
    @Dependency(\.todoClient) private var todoClient
    @ObservationIgnored
    @Dependency(\.continuousClock) private var clock

    func selectChildModel(_ child: TaskTreeModel) {
        selectedChildModel = child
    }

    func addTask(_ todo: Todo) {
        do {
            try todoClient.appendTodos(todo: todo, parentTodo: parentTodo)
            update()
        } catch {
            alert = .error(error)
        }
    }

    func update(wait duration: Duration = .seconds(0.1)) {
        Task { @MainActor in
            do {
                try await clock.sleep(for: duration)
                parentTodo = try todoClient.fetchTodo(todoID: parentTodo.id)
                parentModel?.update(wait: .zero)
            } catch {
                alert = .error(error)
            }
        }
    }

    func toggleIsCompleted(_ todo: Todo) {
        do {
            try todoClient.toggleIsComplete(todoID: todo.id)
            update()
        } catch {
            alert = .error(error)
        }
    }
}

public struct TaskTreeView: View {
    @Bindable var model: TaskTreeModel

    public init() {
        model = TaskTreeModel(parentTodo: nil, parentModel: nil)
    }

    init(model: TaskTreeModel) {
        self.model = model
    }

    public var body: some View {
        //        NavigationSplitView {
        //            List(model.children, id: \.parentTodo) { childModel in
        //                if let todo = childModel.parentTodo {
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
        List(model.children, id: \.parentTodo) { childModel in
            HStack {
                Image(systemName: childModel.parentTodo.isCompleted ? "checkmark.circle" : "circle")
                    .resizable()
                    .foregroundStyle(.primary)
                    .frame(width: 17, height: 17)
                    .onTapGesture {
                        model.toggleIsCompleted(childModel.parentTodo)
                    }
                HStack {
                    Text(childModel.parentTodo.title)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    model.selectChildModel(childModel)
                }
            }
        }
        .navigationTitle(model.parentTodo.isRoot ? String(localized: "Task", bundle: .module) : model.parentTodo.title)
        .overlay {
            if model.children.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Tasks", bundle: .module),
                    systemImage: "list.bullet.clipboard",
                    description: Text("Let's add a task!", bundle: .module)
                )
            }
        }
        .alert($model.alert) { _ in}
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
                            createdAt: Date(), 
                            isCompleted: false
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
    NavigationStack {
        TaskTreeView(
            model: withDependencies {
                $0.todoClient = .previewValue
            } operation: {
                TaskTreeModel(parentTodo: nil, parentModel: nil)
            }
        )
    }
}
