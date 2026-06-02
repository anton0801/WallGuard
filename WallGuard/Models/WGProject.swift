import Foundation

struct WGProject: Identifiable, Codable, Equatable {
    var id          = UUID()
    var name:         String
    var objectType:   String
    var address:      String
    var startDate:    Date
    var notes:        String
    var isArchived:   Bool = false
    var createdAt:    Date = Date()

    static let objectTypes = [
        "Apartment", "House", "Office",
        "Warehouse", "Commercial Building", "Other"
    ]
}
