import SwiftUI
import UserNotifications

// MARK: - HistoryView
struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var filter:     HistoryFilter = .all
    @State private var searchText  = ""

    enum HistoryFilter: String, CaseIterable {
        case all = "All", created = "Created", completed = "Completed"
    }

    struct Entry: Identifiable {
        let id:       UUID
        let title:    String
        let subtitle: String
        let date:     Date
        let typeStr:  String
        let icon:     String
        let color:    Color
    }

    var entries: [Entry] {
        var result: [Entry] = []
        for d in appState.defects {
            result.append(Entry(id: d.id, title: d.title, subtitle: d.category.rawValue,
                                date: d.createdAt, typeStr: "Created",
                                icon: "plus.circle.fill", color: WGColor.success))
            if d.isResolved {
                result.append(Entry(id: UUID(), title: "Resolved: \(d.title)", subtitle: d.category.rawValue,
                                    date: d.updatedAt, typeStr: "Completed",
                                    icon: "checkmark.circle.fill", color: WGColor.blue))
            }
        }
        for r in appState.records {
            result.append(Entry(id: r.id, title: r.title, subtitle: r.category.rawValue,
                                date: r.createdAt, typeStr: "Created",
                                icon: "doc.text.fill", color: WGColor.orange))
        }
        for t in appState.tasks.filter({ $0.isDone }) {
            result.append(Entry(id: t.id, title: t.title, subtitle: "Task completed",
                                date: t.dueDate, typeStr: "Completed",
                                icon: "checkmark.seal.fill", color: WGColor.success))
        }
        return result
            .filter { filter == .all || $0.typeStr == filter.rawValue }
            .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("History").font(.system(size: 28, weight: .bold)).foregroundColor(WGColor.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 8)

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(WGColor.textMuted)
                        TextField("Search history...", text: $searchText).foregroundColor(WGColor.textPrimary)
                    }
                    .padding(12).background(WGColor.card).cornerRadius(12)
                    .padding(.horizontal, 18).padding(.bottom, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(HistoryFilter.allCases, id: \.self) { f in
                                FilterChip(label: f.rawValue, isSelected: filter == f) { withAnimation { filter = f } }
                            }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 8)
                    }

                    if entries.isEmpty {
                        Spacer()
                        Text("No history entries").font(.system(size: 15)).foregroundColor(WGColor.textMuted)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                ForEach(entries) { e in
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle().fill(e.color.opacity(0.15)).frame(width: 40, height: 40)
                                            Image(systemName: e.icon).foregroundColor(e.color).font(.system(size: 16))
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(e.title).font(.system(size: 14, weight: .medium))
                                                .foregroundColor(WGColor.textPrimary).lineLimit(1)
                                            Text(e.subtitle).font(.system(size: 12)).foregroundColor(WGColor.textMuted)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(e.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.system(size: 11)).foregroundColor(WGColor.textMuted)
                                            Text(e.typeStr).font(.system(size: 10, weight: .medium)).foregroundColor(e.color)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    Divider().background(WGColor.divider).padding(.leading, 54)
                                }
                            }
                            .padding(.horizontal, 18).padding(.bottom, 90)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - CalendarView
struct CalendarView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedDate = Date()
    @State private var showAddTask  = false

    var tasksForDate: [WGTask] {
        appState.tasks.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("Calendar").font(.system(size: 28, weight: .bold)).foregroundColor(WGColor.textPrimary)
                        Spacer()
                        Button {
                            withAnimation { selectedDate = Date() }
                        } label: {
                            Text("Today")
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(WGColor.yellow)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(WGColor.yellow.opacity(0.1)).cornerRadius(10)
                        }
                        Button { showAddTask = true } label: {
                            Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(WGColor.yellow)
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 12)

                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical).colorScheme(.dark).accentColor(WGColor.yellow)
                        .padding(.horizontal, 18).background(WGColor.card).cornerRadius(16).padding(.horizontal, 18)

                    Spacer().frame(height: 12)

                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.system(size: 14, weight: .medium)).foregroundColor(WGColor.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 18)

                    Spacer().frame(height: 8)

                    if tasksForDate.isEmpty {
                        Text("No events on this day").font(.system(size: 14)).foregroundColor(WGColor.textMuted)
                            .padding(.horizontal, 18).padding(.top, 12)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                ForEach(tasksForDate) { task in TaskRow(task: task) }
                            }
                            .padding(.horizontal, 18).padding(.bottom, 90)
                        }
                    }
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTask) { AddTaskView() }
        }
    }
}

struct WallGuardShowpiece: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                ShowpieceContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: .pushArrow)) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: BastionDictKey.pushURL)
        let stored = UserDefaults.standard.string(forKey: BastionDictKey.routeURL) ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: BastionDictKey.pushURL) }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: BastionDictKey.pushURL), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: BastionDictKey.pushURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

// MARK: - NotificationsView
struct NotificationsView: View {
    @AppStorage("notif_deadline") private var notifDeadline = true
    @AppStorage("notif_warning")  private var notifWarning  = true
    @AppStorage("notif_weekly")   private var notifWeekly   = false
    @State private var permissionGranted = false
    @State private var saved             = false

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Permission status
                        HStack(spacing: 12) {
                            Image(systemName: permissionGranted ? "bell.badge.fill" : "bell.slash.fill")
                                .foregroundColor(permissionGranted ? WGColor.success : WGColor.danger)
                                .font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(permissionGranted ? "Notifications Enabled" : "Notifications Disabled")
                                    .font(.system(size: 15, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                                Text(permissionGranted ? "You will receive alerts" : "Enable in Settings for alerts")
                                    .font(.system(size: 13)).foregroundColor(WGColor.textMuted)
                            }
                            Spacer()
                            if !permissionGranted {
                                Button("Enable") {
                                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                                        DispatchQueue.main.async { permissionGranted = granted }
                                    }
                                }
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(WGColor.bg)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(WGColor.yellow).cornerRadius(10)
                            }
                        }
                        .padding(14).background(WGColor.card).cornerRadius(14)

                        // Toggles
                        VStack(spacing: 0) {
                            NotifToggleRow(icon: "calendar.badge.exclamationmark",
                                          title: "Deadline Reminders",
                                          subtitle: "Alert when tasks are due",
                                          color: WGColor.danger, isOn: $notifDeadline)
                            Divider().background(WGColor.divider)
                            NotifToggleRow(icon: "exclamationmark.triangle.fill",
                                          title: "Defect Warnings",
                                          subtitle: "Alert for critical risk defects",
                                          color: WGColor.orange, isOn: $notifWarning)
                            Divider().background(WGColor.divider)
                            NotifToggleRow(icon: "calendar.circle.fill",
                                          title: "Weekly Check Reminder",
                                          subtitle: "Every Monday at 9 AM",
                                          color: WGColor.blue, isOn: $notifWeekly)
                        }
                        .background(WGColor.card).cornerRadius(14)

                        Button {
                            scheduleNotifications()
                            saved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
                        } label: {
                            HStack {
                                Image(systemName: saved ? "checkmark.circle.fill" : "bell.badge.fill")
                                Text(saved ? "Saved!" : "Save Notifications").font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(WGColor.bg).frame(maxWidth: .infinity).frame(height: 52)
                            .background(saved ? WGColor.success : WGColor.yellow).cornerRadius(14)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 18).padding(.top, 16)
                }
            }
            .navigationTitle("Notifications").navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            UNUserNotificationCenter.current().getNotificationSettings { s in
                DispatchQueue.main.async { permissionGranted = s.authorizationStatus == .authorized }
            }
        }
    }

    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard permissionGranted else { return }

        if notifWeekly {
            let content = UNMutableNotificationContent()
            content.title = "Wall Guard Check"
            content.body  = "Time for your weekly wall inspection."
            content.sound = .default
            var dc = DateComponents(); dc.weekday = 2; dc.hour = 9
            let req = UNNotificationRequest(
                identifier: "wg_weekly",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            )
            UNUserNotificationCenter.current().add(req)
        }
    }
}

// MARK: - NotifToggleRow
struct NotifToggleRow: View {
    let icon:     String
    let title:    String
    let subtitle: String
    let color:    Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(WGColor.textPrimary)
                Text(subtitle).font(.system(size: 12)).foregroundColor(WGColor.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn).toggleStyle(.switch).tint(color)
        }
        .padding(14)
    }
}
