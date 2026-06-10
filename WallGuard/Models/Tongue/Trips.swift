import Foundation

enum BastionTrip: Error, CustomStringConvertible {
    case suppliesEmpty(at: String)
    case scrollTorn(at: String)
    case messengerLost(stage: String)
    case warbandBeating(coolDown: TimeInterval)
    case hourglassEmpty(stage: String)
    case drawbridgeUp(httpCode: Int)
    case rampartSealed(reason: String)
    
    var description: String {
        switch self {
        case .suppliesEmpty(let at): return "suppliesEmpty(\(at))"
        case .scrollTorn(let at): return "scrollTorn(\(at))"
        case .messengerLost(let stage): return "messengerLost(\(stage))"
        case .warbandBeating(let cd): return "warbandBeating(cd=\(cd))"
        case .hourglassEmpty(let stage): return "hourglassEmpty(\(stage))"
        case .drawbridgeUp(let code): return "drawbridgeUp(\(code))"
        case .rampartSealed(let reason): return "rampartSealed(\(reason))"
        }
    }
    
    var isSealed: Bool {
        switch self {
        case .drawbridgeUp, .rampartSealed: return true
        default: return false
        }
    }
    
    var isMessenger: Bool {
        switch self {
        case .messengerLost, .warbandBeating, .hourglassEmpty: return true
        default: return false
        }
    }
}
