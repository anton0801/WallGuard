import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddProject  = false
    @State private var showQuickCheck  = false
    @State private var showReport      = false
    @State private var appear          = false

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Wall Guard")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(WGColor.textPrimary)
                                Text(Date().formatted(date: .long, time: .omitted))
                                    .font(.system(size: 13))
                                    .foregroundColor(WGColor.textMuted)
                            }
                            Spacer()
                            ZStack {
                                Circle().fill(WGColor.card).frame(width: 44, height: 44)
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(appState.overdueTasks.isEmpty ? WGColor.textMuted : WGColor.orange)
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.horizontal, 18).padding(.top, 8)

                        // Stats row
                        HStack(spacing: 12) {
                            DashStatCard(value: "\(appState.activeProjectsCount)", label: "Projects",  icon: "building.2.fill",               color: WGColor.blue)
                            DashStatCard(value: "\(appState.openDefectsCount)",    label: "Defects",   icon: "exclamationmark.triangle.fill",  color: WGColor.danger)
                            DashStatCard(value: "\(appState.pendingTasksCount)",   label: "Tasks",     icon: "checkmark.circle.fill",          color: WGColor.orange)
                        }
                        .padding(.horizontal, 18)
                        .cardAppear(appear, delay: 0.1)

                        // Active Project
                        ActiveProjectCard()
                            .padding(.horizontal, 18)
                            .cardAppear(appear, delay: 0.2)

                        // Warnings
                        if !appState.overdueTasks.isEmpty {
                            WarningsCard(tasks: appState.overdueTasks)
                                .padding(.horizontal, 18)
                                .cardAppear(appear, delay: 0.25)
                        }

                        // Today actions
                        TodayActionsCard()
                            .padding(.horizontal, 18)
                            .cardAppear(appear, delay: 0.3)

                        // Quick action buttons
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                WGButton(title: "Add Project",  icon: "plus",              style: .primary)   { showAddProject = true }
                                WGButton(title: "Quick Check",  icon: "camera.viewfinder", style: .secondary) { showQuickCheck = true }
                            }
                            WGButton(title: "Open Report", icon: "chart.bar.fill", style: .outline) { showReport = true }
                        }
                        .padding(.horizontal, 18)
                        .cardAppear(appear, delay: 0.35)

                        // Recent defects
                        if !appState.defects.isEmpty {
                            RecentDefectsSection()
                        }

                        Spacer().frame(height: 90)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddProject) { AddProjectView() }
            .sheet(isPresented: $showQuickCheck) { WallScanView() }
            .sheet(isPresented: $showReport)     { ReportsView() }
            .onAppear  { appear = true }
            .onDisappear { appear = false }
        }
    }
}

// MARK: - DashStatCard
struct DashStatCard: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            Text(value).font(.system(size: 24, weight: .bold)).foregroundColor(WGColor.textPrimary)
            Text(label).font(.system(size: 11)).foregroundColor(WGColor.textMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(WGColor.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - ActiveProjectCard
struct ActiveProjectCard: View {
    @EnvironmentObject var appState: AppState
    var active: WGProject? { appState.projects.filter { !$0.isArchived }.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active Project", systemImage: "folder.fill")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(WGColor.textMuted)
                Spacer()
                Text("VIEW ALL").font(.system(size: 11, weight: .bold)).foregroundColor(WGColor.yellow)
            }
            if let p = active {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(WGColor.yellow.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: "building.2.fill").foregroundColor(WGColor.yellow)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(p.name).font(.system(size: 16, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                        Text(p.objectType).font(.system(size: 13)).foregroundColor(WGColor.textMuted)
                    }
                    Spacer()
                    StatusBadge(text: "Active", color: WGColor.success)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Rooms inspected").font(.system(size: 12)).foregroundColor(WGColor.textMuted)
                        Spacer()
                        Text("\(appState.rooms(for: p.id).count) rooms")
                            .font(.system(size: 12, weight: .medium)).foregroundColor(WGColor.yellow)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(WGColor.divider).frame(height: 6)
                            let pct = min(CGFloat(appState.rooms(for: p.id).count) / 10.0, 1.0)
                            Capsule().fill(WGColor.yellow).frame(width: geo.size.width * pct, height: 6)
                        }
                    }.frame(height: 6)
                }
            } else {
                HStack {
                    Image(systemName: "plus.circle.fill").foregroundColor(WGColor.textMuted)
                    Text("No active projects. Create one to start.")
                        .font(.system(size: 14)).foregroundColor(WGColor.textMuted)
                }
            }
        }
        .padding(16).background(WGColor.card).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WGColor.divider, lineWidth: 1))
    }
}

// MARK: - WarningsCard
struct WarningsCard: View {
    let tasks: [WGTask]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Warnings", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(WGColor.orange)
            ForEach(tasks.prefix(3)) { task in
                HStack(spacing: 10) {
                    Circle().fill(WGColor.danger).frame(width: 8, height: 8)
                    Text(task.title).font(.system(size: 14)).foregroundColor(WGColor.textPrimary).lineLimit(1)
                    Spacer()
                    Text("Overdue").font(.system(size: 11, weight: .medium)).foregroundColor(WGColor.danger)
                }
            }
            if tasks.count > 3 {
                Text("+\(tasks.count - 3) more overdue").font(.system(size: 12)).foregroundColor(WGColor.textMuted)
            }
        }
        .padding(16)
        .background(WGColor.danger.opacity(0.08)).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WGColor.danger.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - TodayActionsCard
struct TodayActionsCard: View {
    @EnvironmentObject var appState: AppState
    var todayTasks: [WGTask] {
        appState.tasks.filter { !$0.isDone && Calendar.current.isDateInToday($0.dueDate) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Actions", systemImage: "calendar.badge.clock")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(WGColor.textMuted)
            if todayTasks.isEmpty {
                Text("No tasks due today. All clear!")
                    .font(.system(size: 14)).foregroundColor(WGColor.textMuted)
            } else {
                ForEach(todayTasks.prefix(4)) { task in TodayTaskRow(task: task) }
            }
        }
        .padding(16).background(WGColor.card).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WGColor.divider, lineWidth: 1))
    }
}

// MARK: - TodayTaskRow
struct TodayTaskRow: View {
    @EnvironmentObject var appState: AppState
    let task: WGTask
    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { appState.toggleTask(task) }
            } label: {
                ZStack {
                    Circle().stroke(task.isDone ? WGColor.success : WGColor.divider, lineWidth: 2).frame(width: 24, height: 24)
                    if task.isDone { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(WGColor.success) }
                }
            }
            Text(task.title).font(.system(size: 14)).foregroundColor(task.isDone ? WGColor.textMuted : WGColor.textPrimary)
                .strikethrough(task.isDone, color: WGColor.textMuted).lineLimit(1)
            Spacer()
            Circle().fill(Color(hex: task.priority.color)).frame(width: 8, height: 8)
        }
    }
}

// MARK: - RecentDefectsSection
struct RecentDefectsSection: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Defects")
                .font(.system(size: 16, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                .padding(.horizontal, 18)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(appState.defects.prefix(6)) { d in DefectMiniCard(defect: d) }
                }
                .padding(.horizontal, 18)
            }
        }
    }
}

// MARK: - DefectMiniCard
struct DefectMiniCard: View {
    let defect: WGDefect
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: defect.category.icon)
                    .foregroundColor(Color(hex: defect.riskLevel.color)).font(.system(size: 16))
                Spacer()
                Circle().fill(Color(hex: defect.riskLevel.color)).frame(width: 8, height: 8)
            }
            Text(defect.title).font(.system(size: 13, weight: .semibold))
                .foregroundColor(WGColor.textPrimary).lineLimit(2)
            HStack(spacing: 4) {
                Image(systemName: "ruler").font(.system(size: 10)).foregroundColor(WGColor.textMuted)
                Text("\(defect.widthMm, specifier: "%.1f") × \(defect.lengthMm, specifier: "%.1f") mm")
                    .font(.system(size: 11)).foregroundColor(WGColor.textMuted)
            }
            Text(defect.riskLevel.rawValue)
                .font(.system(size: 11, weight: .medium)).foregroundColor(Color(hex: defect.riskLevel.color))
        }
        .frame(width: 150).padding(12).background(WGColor.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: defect.riskLevel.color).opacity(0.25), lineWidth: 1))
    }
}

// MARK: - View Modifier helper
extension View {
    func cardAppear(_ appear: Bool, delay: Double) -> some View {
        self
            .offset(y: appear ? 0 : 30)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: appear)
    }
}
