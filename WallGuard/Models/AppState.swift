import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var projects: [WGProject]     = []
    @Published var rooms:    [WGRoom]        = []
    @Published var defects:  [WGDefect]      = []
    @Published var records:  [DefectRecord]  = []
    @Published var tasks:    [WGTask]        = []
    @Published var photos:   [WGPhoto]       = []

    // MARK: - Persistence
    func loadAll() {
        projects = load("wg_projects")
        rooms    = load("wg_rooms")
        defects  = load("wg_defects")
        records  = load("wg_records")
        tasks    = load("wg_tasks")
        photos   = load("wg_photos")
    }

    func saveAll() {
        save(projects, "wg_projects")
        save(rooms,    "wg_rooms")
        save(defects,  "wg_defects")
        save(records,  "wg_records")
        save(tasks,    "wg_tasks")
        save(photos,   "wg_photos")
    }

    private func load<T: Codable>(_ key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return items
    }

    private func save<T: Codable>(_ items: [T], _ key: String) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Projects
    func addProject(_ p: WGProject)    { projects.append(p); save(projects, "wg_projects") }
    func updateProject(_ p: WGProject) {
        if let i = projects.firstIndex(where: { $0.id == p.id }) {
            projects[i] = p; save(projects, "wg_projects")
        }
    }
    func deleteProject(_ p: WGProject) {
        projects.removeAll { $0.id == p.id }
        rooms.removeAll    { $0.projectId == p.id }
        save(projects, "wg_projects"); save(rooms, "wg_rooms")
    }
    func archiveProject(_ p: WGProject) { var u = p; u.isArchived = true; updateProject(u) }

    // MARK: - Rooms
    func addRoom(_ r: WGRoom)    { rooms.append(r); save(rooms, "wg_rooms") }
    func updateRoom(_ r: WGRoom) {
        if let i = rooms.firstIndex(where: { $0.id == r.id }) {
            rooms[i] = r; save(rooms, "wg_rooms")
        }
    }
    func deleteRoom(_ r: WGRoom) {
        rooms.removeAll   { $0.id == r.id }
        defects.removeAll { $0.roomId == r.id }
        save(rooms, "wg_rooms"); save(defects, "wg_defects")
    }
    func rooms(for projectId: UUID) -> [WGRoom] { rooms.filter { $0.projectId == projectId } }

    // MARK: - Defects
    func addDefect(_ d: WGDefect)    { defects.append(d); save(defects, "wg_defects") }
    func updateDefect(_ d: WGDefect) {
        if let i = defects.firstIndex(where: { $0.id == d.id }) {
            defects[i] = d; save(defects, "wg_defects")
        }
    }
    func deleteDefect(_ d: WGDefect) { defects.removeAll { $0.id == d.id }; save(defects, "wg_defects") }
    func defects(for roomId: UUID) -> [WGDefect] { defects.filter { $0.roomId == roomId } }

    // MARK: - Records
    func addRecord(_ r: DefectRecord)    { records.append(r); save(records, "wg_records") }
    func updateRecord(_ r: DefectRecord) {
        if let i = records.firstIndex(where: { $0.id == r.id }) {
            records[i] = r; save(records, "wg_records")
        }
    }
    func deleteRecord(_ r: DefectRecord) { records.removeAll { $0.id == r.id }; save(records, "wg_records") }

    // MARK: - Tasks
    func addTask(_ t: WGTask)    { tasks.append(t); save(tasks, "wg_tasks") }
    func toggleTask(_ t: WGTask) {
        if let i = tasks.firstIndex(where: { $0.id == t.id }) {
            tasks[i].isDone.toggle(); save(tasks, "wg_tasks")
        }
    }
    func deleteTask(_ t: WGTask) { tasks.removeAll { $0.id == t.id }; save(tasks, "wg_tasks") }

    // MARK: - Photos
    func addPhoto(_ p: WGPhoto)    { photos.append(p); save(photos, "wg_photos") }
    func deletePhoto(_ p: WGPhoto) { photos.removeAll { $0.id == p.id }; save(photos, "wg_photos") }

    // MARK: - Computed
    var activeProjectsCount: Int { projects.filter { !$0.isArchived }.count }
    var openDefectsCount:    Int { defects.filter { $0.riskLevel != .low && !$0.isResolved }.count }
    var pendingTasksCount:   Int { tasks.filter { !$0.isDone }.count }
    var overdueTasks: [WGTask]   { tasks.filter { !$0.isDone && $0.dueDate < Date() } }
}
