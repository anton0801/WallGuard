import Foundation

enum SagaEffect {
    case persistState
    case publishOutcome(WatchOutcome)
    case wirePushBeacon
    case clearPushURL
}

@MainActor
final class EffectQueue {
    
    private var pending: [SagaEffect] = []
    private var draining: Bool = false
    
    private let onPersist: () -> Void
    private let onPublish: (WatchOutcome) -> Void
    private let onWirePush: () -> Void
    
    init(
        onPersist: @escaping () -> Void,
        onPublish: @escaping (WatchOutcome) -> Void,
        onWirePush: @escaping () -> Void
    ) {
        self.onPersist = onPersist
        self.onPublish = onPublish
        self.onWirePush = onWirePush
    }
    
    func enqueue(_ effect: SagaEffect) {
        pending.append(effect)
        drain()
    }
    
    func enqueueMany(_ effects: [SagaEffect]) {
        pending.append(contentsOf: effects)
        drain()
    }
    
    private func drain() {
        guard !draining else { return }
        draining = true
        defer { draining = false }
        
        while !pending.isEmpty {
            let effect = pending.removeFirst()
            execute(effect)
        }
    }
    
    private func execute(_ effect: SagaEffect) {
        switch effect {
        case .persistState:
            onPersist()
        case .publishOutcome(let outcome):
            onPublish(outcome)
        case .wirePushBeacon:
            onWirePush()
        case .clearPushURL:
            UserDefaults.standard.removeObject(forKey: BastionDictKey.pushURL)
        }
    }
}
