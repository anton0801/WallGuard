import Foundation

final class SentryKit {
    let strongroom: Strongroom
    let sentinel: Sentinel
    let herald: Herald
    let watchman: Watchman
    
    init(strongroom: Strongroom, sentinel: Sentinel, herald: Herald, watchman: Watchman) {
        self.strongroom = strongroom
        self.sentinel = sentinel
        self.herald = herald
        self.watchman = watchman
    }
    
    static func productionKit() -> SentryKit {
        SentryKit(
            strongroom: JSONStrongroom(),
            sentinel: AppsFlyerSentinel(),
            herald: HTTPHerald(),
            watchman: NotificationWatchman()
        )
    }
}

@MainActor
final class Anchorage {
    
    static let shared = Anchorage()
    
    private var slots: [String: Any] = [:]
    
    private init() {}
    
    func lash<T>(_ instance: T, as type: T.Type) {
        let key = String(describing: type)
        slots[key] = instance
    }
    
    func unmoor<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        if let instance = slots[key] as? T {
            return instance
        }
        let inst = buildDefault(for: type)
        slots[key] = inst
        return inst
    }
    
    private func buildDefault<T>(for type: T.Type) -> T {
        let key = String(describing: type)
        switch key {
        case String(describing: SentryKit.self):
            return SentryKit.productionKit() as! T
        case String(describing: SagaRunner.self):
            let kit = unmoor(SentryKit.self)
            return SagaRunner(kit: kit) as! T
        default:
            fatalError("Anchorage: no default builder for \(key)")
        }
    }
}
