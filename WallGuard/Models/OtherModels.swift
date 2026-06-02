import Foundation

// MARK: - DefectRecord
struct DefectRecord: Identifiable, Codable, Equatable {
    var id        = UUID()
    var title:      String
    var roomId:     UUID?
    var date:       Date = Date()
    var category:   RecordCategory
    var value:      String
    var comment:    String
    var photoData:  Data?
    var status:     RecordStatus = .open
    var createdAt:  Date = Date()

    enum RecordCategory: String, Codable, CaseIterable {
        case inspection  = "Inspection"
        case measurement = "Measurement"
        case repair      = "Repair"
        case monitoring  = "Monitoring"
        case other       = "Other"

        var icon: String {
            switch self {
            case .inspection:  return "magnifyingglass"
            case .measurement: return "ruler"
            case .repair:      return "hammer.fill"
            case .monitoring:  return "eye.fill"
            case .other:       return "doc.text"
            }
        }
    }

    enum RecordStatus: String, Codable, CaseIterable {
        case open       = "Open"
        case inProgress = "In Progress"
        case closed     = "Closed"
    }
}

// MARK: - WGTask
struct WGTask: Identifiable, Codable, Equatable {
    var id         = UUID()
    var title:       String
    var notes:       String
    var dueDate:     Date
    var priority:    Priority
    var isDone:      Bool  = false
    var projectId:   UUID?
    var roomId:      UUID?
    var createdAt:   Date  = Date()

    enum Priority: String, Codable, CaseIterable {
        case low    = "Low"
        case medium = "Medium"
        case high   = "High"

        var color: String {
            switch self {
            case .low:    return "22C55E"
            case .medium: return "FACC15"
            case .high:   return "EF4444"
            }
        }
    }
}

// MARK: - WGPhoto
struct WGPhoto: Identifiable, Codable, Equatable {
    var id         = UUID()
    var imageData:   Data
    var category:    PhotoCategory
    var caption:     String
    var projectId:   UUID?
    var roomId:      UUID?
    var defectId:    UUID?
    var createdAt:   Date = Date()

    enum PhotoCategory: String, Codable, CaseIterable {
        case before   = "Before"
        case problem  = "Problem"
        case progress = "Progress"
        case after    = "After"

        var color: String {
            switch self {
            case .before:   return "3B82F6"
            case .problem:  return "EF4444"
            case .progress: return "F97316"
            case .after:    return "22C55E"
            }
        }

        var icon: String {
            switch self {
            case .before:   return "clock.fill"
            case .problem:  return "exclamationmark.triangle.fill"
            case .progress: return "arrow.forward.circle.fill"
            case .after:    return "checkmark.circle.fill"
            }
        }
    }
}
