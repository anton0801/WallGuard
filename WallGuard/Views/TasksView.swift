import SwiftUI

// MARK: - TasksView
struct TasksView: View {
    @EnvironmentObject var appState: AppState
    @State private var filter:        FilterMode = .all
    @State private var showAddTask  = false

    enum FilterMode: String, CaseIterable {
        case all = "All", today = "Today", overdue = "Overdue", done = "Done"
    }

    var filtered: [WGTask] {
        let cal = Calendar.current
        switch filter {
        case .all:     return appState.tasks.filter { !$0.isDone }
        case .today:   return appState.tasks.filter { !$0.isDone && cal.isDateInToday($0.dueDate) }
        case .overdue: return appState.tasks.filter { !$0.isDone && $0.dueDate < Date() }
        case .done:    return appState.tasks.filter {  $0.isDone }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("Tasks").font(.system(size: 28, weight: .bold)).foregroundColor(WGColor.textPrimary)
                        Spacer()
                        Button { showAddTask = true } label: {
                            Image(systemName: "plus.circle.fill").font(.system(size: 26)).foregroundColor(WGColor.yellow)
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 12)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(FilterMode.allCases, id: \.self) { mode in
                                FilterChip(
                                    label: mode.rawValue,
                                    color: mode == .overdue ? WGColor.danger : WGColor.yellow,
                                    isSelected: filter == mode
                                ) { withAnimation { filter = mode } }
                            }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 8)
                    }

                    if filtered.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle").font(.system(size: 48)).foregroundColor(WGColor.success)
                            Text(filter == .done ? "No completed tasks" : "No tasks here").foregroundColor(WGColor.textMuted)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { task in
                                    TaskRow(task: task)
                                        .contextMenu {
                                            Button("Delete", role: .destructive) { appState.deleteTask(task) }
                                        }
                                }
                            }
                            .padding(.horizontal, 18).padding(.bottom, 90)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTask) { AddTaskView() }
        }
    }
}

// MARK: - TaskRow
struct TaskRow: View {
    @EnvironmentObject var appState: AppState
    let task: WGTask
    var isOverdue: Bool { !task.isDone && task.dueDate < Date() }

    var body: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { appState.toggleTask(task) }
            } label: {
                ZStack {
                    Circle().stroke(task.isDone ? WGColor.success : Color(hex: task.priority.color), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if task.isDone {
                        Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundColor(WGColor.success)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(task.isDone ? WGColor.textMuted : WGColor.textPrimary)
                    .strikethrough(task.isDone, color: WGColor.textMuted).lineLimit(2)
                HStack(spacing: 8) {
                    Image(systemName: "calendar").font(.system(size: 11))
                        .foregroundColor(isOverdue ? WGColor.danger : WGColor.textMuted)
                    Text(task.dueDate.formatted(date: .abbreviated, time: .omitted)).font(.system(size: 12))
                        .foregroundColor(isOverdue ? WGColor.danger : WGColor.textMuted)
                }
            }
            Spacer()
            Circle().fill(Color(hex: task.priority.color)).frame(width: 8, height: 8)
        }
        .padding(14).background(WGColor.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(isOverdue ? WGColor.danger.opacity(0.3) : WGColor.divider, lineWidth: 1))
    }
}

// MARK: - AddTaskView
struct AddTaskView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    var defaultTitle: String = ""

    @State private var title    = ""
    @State private var notes    = ""
    @State private var dueDate  = Date().addingTimeInterval(86400)
    @State private var priority: WGTask.Priority = .medium
    @State private var saved    = false
    @State private var showVal  = false

    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        WGFormField(title: "Task Title", placeholder: "What needs to be done?", text: $title)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Due Date").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            DatePicker("", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(.compact).colorScheme(.dark)
                                .padding(12).background(WGColor.card).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            HStack(spacing: 10) {
                                ForEach(WGTask.Priority.allCases, id: \.self) { p in
                                    Button { withAnimation { priority = p } } label: {
                                        Text(p.rawValue).font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(priority == p ? WGColor.bg : WGColor.textSecondary)
                                            .frame(maxWidth: .infinity).frame(height: 40)
                                            .background(priority == p ? Color(hex: p.color) : WGColor.card).cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: p.color).opacity(0.4), lineWidth: 1))
                                    }
                                }
                            }
                        }

                        WGFormField(title: "Notes", placeholder: "Details...", text: $notes, isMultiline: true)

                        if showVal && !isValid {
                            Text("Task title is required").font(.system(size: 13)).foregroundColor(WGColor.danger)
                        }

                        Button {
                            guard isValid else { showVal = true; return }
                            let t = WGTask(title: title.trimmingCharacters(in: .whitespaces),
                                          notes: notes, dueDate: dueDate, priority: priority)
                            appState.addTask(t)
                            saved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss.wrappedValue.dismiss() }
                        } label: {
                            HStack {
                                Image(systemName: saved ? "checkmark.circle.fill" : "plus.circle.fill")
                                Text(saved ? "Added!" : "Add Task").font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(WGColor.bg).frame(maxWidth: .infinity).frame(height: 52)
                            .background(saved ? WGColor.success : WGColor.yellow).cornerRadius(14)
                        }
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 18).padding(.top, 8)
                }
            }
            .navigationTitle("New Task").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(WGColor.textMuted)
                }
            }
            .onAppear { if !defaultTitle.isEmpty { title = defaultTitle } }
        }
        .colorScheme(.dark)
    }
}
