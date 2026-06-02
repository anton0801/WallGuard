import Foundation

struct WGRoom: Identifiable, Codable, Equatable {
    var id             = UUID()
    var projectId:       UUID
    var name:            String
    var floor:           Int
    var area:            Double
    var notes:           String
    var coverPhotoData:  Data?
    var createdAt:       Date = Date()
    var status:          RoomStatus = .ok

    enum RoomStatus: String, Codable, CaseIterable {
        case ok        = "OK"
        case attention = "Attention"
        case critical  = "Critical"

        var color: String {
            switch self {
            case .ok:        return "22C55E"
            case .attention: return "FACC15"
            case .critical:  return "EF4444"
            }
        }
    }
}
