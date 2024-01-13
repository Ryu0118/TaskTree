import Observation
import Foundation
import TodoClient
import Dependencies
import SwiftUINavigation
import SwiftDataModel
import Utils
import SwiftUI

@Observable
final class TaskTreeModel {
    enum AlertAction: Equatable {
        case addTask
    }
    var selectedChildModel: TaskTreeModel?
    var parentTodo: Todo
    var children: [TaskTreeModel] {
        parentTodo.children
            .map { TaskTreeModel(parentTodo: $0) }
            .sorted { $0.parentTodo.createdAt > $1.parentTodo.createdAt }
    }
    var alert: AlertState<Never>?
    var addTaskAlert: AlertState<AlertAction>?
    var taskTitle: String = ""

    init(parentTodo: Todo?) {
        if let parentTodo {
            self.parentTodo = parentTodo
        } else {
            @Dependency(\.todoClient) var todoClient
            do {
                self.parentTodo = try todoClient.fetchRootTodo()
            } catch {
                fatalError("Failed to retrieve root todo")
            }
        }
    }

    @ObservationIgnored
    @Dependency(\.todoClient) private var todoClient
    @ObservationIgnored
    @Dependency(\.continuousClock) private var clock

    func delete(_ indexSet: IndexSet) {
        do {
            let todos = indexSet.map { children[$0].parentTodo }
            try todoClient.remove(parentTodo: parentTodo, todos: todos)
        } catch {
            alert = .error(error)
        }
    }

    func selectChildModel(_ child: TaskTreeModel) {
        selectedChildModel = child
    }

    func addTask(_ todo: Todo) {
        do {
            try todoClient.appendTodos(todo: todo, parentTodo: parentTodo)
            taskTitle = ""
        } catch {
            alert = .error(error)
        }
    }

    func toggleIsCompleted(_ todo: Todo) {
        do {
            try todoClient.toggleIsComplete(todo: todo)
        } catch {
            alert = .error(error)
        }
    }

    func presentAddTaskAlert() {
        addTaskAlert = AlertState {
            TextState("Add a task", bundle: .module)
        } actions: {
            ButtonState(action: .addTask) {
                TextState("Add", bundle: .module)
            }

            ButtonState(role: .cancel) {
                TextState("Cancel", bundle: .module)
            }
        }
    }
}

public struct TaskTreeView: View {
    @Bindable var model: TaskTreeModel

    public init() {
        model = TaskTreeModel(parentTodo: nil)
    }

    init(model: TaskTreeModel) {
        self.model = model
    }

    public var body: some View {
        List {
            ForEach(model.children, id: \.parentTodo) { childModel in
                HStack {
                    Image(systemName: childModel.parentTodo.isCompleted ? "checkmark.circle" : "circle")
                        .resizable()
                        .foregroundStyle(.primary)
                        .frame(width: 18, height: 18)
                        .onTapGesture {
                            model.toggleIsCompleted(childModel.parentTodo)
                        }
                    HStack {
                        Text(childModel.parentTodo.title)
                            .overlay {
                                if childModel.parentTodo.isCompleted {
                                    Rectangle()
                                        .fill(.primary)
                                        .frame(height: 1)
                                }
                            }
                        Spacer()
                        HStack(spacing: 0) {
                            Text("\(childModel.parentTodo.childrenCount)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            NavigationLink<EmptyView, EmptyView>.empty
                                .frame(width: 10)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.selectChildModel(childModel)
                    }
                }
            }
            .onDelete { indexSet in
                model.delete(indexSet)
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
        .alert($model.alert) 
        .alert($model.addTaskAlert) { action in
            switch action {
            case .addTask:
                model.addTask(
                    Todo(
                        id: UUID(),
                        children: [],
                        title: model.taskTitle,
                        createdAt: .now
                    )
                )
            case .none:
                break
            }
        } content: {
            TextField(String(localized: "Enter a task name", bundle: .module), text: $model.taskTitle)
        }
        .navigationDestination(unwrapping: $model.selectedChildModel) { $childModel in
            TaskTreeView(model: $childModel.wrappedValue)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.presentAddTaskAlert()
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
                TaskTreeModel(parentTodo: nil)
            }
        )
    }
}
