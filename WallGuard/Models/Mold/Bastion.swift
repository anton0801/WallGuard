import Foundation

struct BastionArchive: Codable {
    let banners: [String: String]
    let scouts: [String: String]
    let routeURL: String?
    let routeMode: String?
    let unbreached: Bool
    let consentForged: Bool
    let consentBarred: Bool
    let consentStampedAt: Date?
}

struct Bastion {
    var banners: [String: String] = [:]
    var scouts: [String: String] = [:]
    var routeURL: String? = nil
    var routeMode: String? = nil
    var unbreached: Bool = true
    var fortified: Bool = false
    var organicMarched: Bool = false
    var consentForged: Bool = false
    var consentBarred: Bool = false
    var consentStampedAt: Date? = nil
    
    var bannersReady: Bool { !banners.isEmpty }
    var organicMarch: Bool { banners["af_status"] == "Organic" }
    
    var consentRipe: Bool {
        guard !consentForged && !consentBarred else { return false }
        if let date = consentStampedAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    static func revive(from archive: BastionArchive) -> Bastion {
        var b = Bastion()
        b.banners = archive.banners
        b.scouts = archive.scouts
        b.routeURL = archive.routeURL
        b.routeMode = archive.routeMode
        b.unbreached = archive.unbreached
        b.consentForged = archive.consentForged
        b.consentBarred = archive.consentBarred
        b.consentStampedAt = archive.consentStampedAt
        return b
    }
    
    func crystallize() -> BastionArchive {
        BastionArchive(
            banners: banners, scouts: scouts,
            routeURL: routeURL, routeMode: routeMode,
            unbreached: unbreached,
            consentForged: consentForged, consentBarred: consentBarred,
            consentStampedAt: consentStampedAt
        )
    }
}

enum WatchOutcome: Equatable {
    case patrolling
    case askConsent
    case raiseDrawbridge
    case overrun
}

final class WatchSigil {
    private var stamped: Bool = false
    private let lock = NSLock()
    
    func tryStamp() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !stamped else { return false }
        stamped = true
        return true
    }
    
    var isStamped: Bool {
        lock.lock()
        defer { lock.unlock() }
        return stamped
    }
}
