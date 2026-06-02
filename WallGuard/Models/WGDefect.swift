import Foundation

struct WGDefect: Identifiable, Codable, Equatable {
    var id           = UUID()
    var roomId:        UUID
    var title:         String
    var category:      DefectCategory
    var widthMm:       Double
    var lengthMm:      Double
    var riskLevel:     RiskLevel
    var notes:         String
    var isResolved:    Bool   = false
    var photoData:     Data?
    var markerX:       Double = 0.5
    var markerY:       Double = 0.5
    var createdAt:     Date   = Date()
    var updatedAt:     Date   = Date()
    var measurements:  [Measurement] = []

    // MARK: - Measurement
    struct Measurement: Identifiable, Codable, Equatable {
        var id      = UUID()
        var widthMm:  Double
        var lengthMm: Double
        var date:     Date   = Date()
        var notes:    String = ""
    }

    // MARK: - DefectCategory
    enum DefectCategory: String, Codable, CaseIterable {
        case crack       = "Crack"
        case spalling    = "Spalling"
        case moisture    = "Moisture"
        case corrosion   = "Corrosion"
        case deformation = "Deformation"
        case other       = "Other"

        var icon: String {
            switch self {
            case .crack:       return "bolt.fill"
            case .spalling:    return "square.3.layers.3d"
            case .moisture:    return "drop.fill"
            case .corrosion:   return "flame.fill"
            case .deformation: return "waveform"
            case .other:       return "exclamationmark.triangle"
            }
        }
    }

    // MARK: - RiskLevel
    enum RiskLevel: String, Codable, CaseIterable {
        case low      = "Low"
        case medium   = "Medium"
        case high     = "High"
        case critical = "Critical"

        var color: String {
            switch self {
            case .low:      return "22C55E"
            case .medium:   return "FACC15"
            case .high:     return "F97316"
            case .critical: return "EF4444"
            }
        }

        var icon: String {
            switch self {
            case .low:      return "checkmark.circle.fill"
            case .medium:   return "exclamationmark.circle.fill"
            case .high:     return "exclamationmark.triangle.fill"
            case .critical: return "xmark.octagon.fill"
            }
        }

        static func assess(width: Double, length: Double) -> RiskLevel {
            let score = width * length
            switch score {
            case ..<5:   return .low
            case 5..<50: return .medium
            case 50..<200: return .high
            default:     return .critical
            }
        }
    }
}
