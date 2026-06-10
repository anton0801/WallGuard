import Foundation
import Combine

@MainActor
final class SagaRunner {
    
    private var bastion: Bastion = Bastion()
    private var hydrated: Bool = false
    
    let sigil = WatchSigil()
    
    private let kit: SentryKit
    
    private let outcomeSubject = PassthroughSubject<WatchOutcome, Never>()
    var outcomePublisher: AnyPublisher<WatchOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var effectQueue: EffectQueue!
    private var consentTask: Task<Void, Never>?
    
    init(kit: SentryKit) {
        self.kit = kit
        self.effectQueue = EffectQueue(
            onPersist: { [weak self] in
                guard let self = self else { return }
                self.kit.strongroom.seal(self.bastion.crystallize())
            },
            onPublish: { [weak self] outcome in
                guard let self = self else { return }
                self.outcomeSubject.send(outcome)
            },
            onWirePush: { [weak self] in
                self?.kit.watchman.wirePushBeacon()
            }
        )
    }
    
    private func ensureHydrated() {
        guard !hydrated else { return }
        let archive = kit.strongroom.unseal()
        bastion = Bastion.revive(from: archive)
        hydrated = true
    }
    
    func wakeBastion() {
        ensureHydrated()
    }
    
    func absorbBanners(_ raw: [String: Any]) {
        ensureHydrated()
        let mapped = raw.mapValues { "\($0)" }
        bastion.banners = mapped
        effectQueue.enqueue(.persistState)
    }
    
    func absorbScouts(_ raw: [String: Any]) {
        ensureHydrated()
        let mapped = raw.mapValues { "\($0)" }
        bastion.scouts = mapped
        effectQueue.enqueue(.persistState)
    }
    
    func runSaga() async {
        ensureHydrated()
        guard !sigil.isStamped else { return }
        
        let steps: [SagaStep] = [
            PushSeizureStep(),
            BannersGateStep(),
            OrganicMarchStep(),
            HeraldDispatchStep()
        ]
        
        let ledger = SagaLedger(bastion: bastion, kit: kit)
        
        for step in steps {
            if sigil.isStamped {
                bastion = ledger.bastion
                return
            }
            
            let verdict = await step.forward(ledger: ledger)
            
            switch verdict {
            case .march:
                continue
            case .anchor(let outcome):
                bastion = ledger.bastion
                if case .patrolling = outcome {
                    outcomeSubject.send(.patrolling)
                    return
                }
                if sigil.tryStamp() {
                    outcomeSubject.send(outcome)
                }
                return
            case .tripped(let trip):
                await rollback(steps: steps, ledger: ledger, upTo: step.stepID)
                bastion = ledger.bastion
                _ = trip
                if sigil.tryStamp() {
                    outcomeSubject.send(.overrun)
                }
                return
            }
        }
        
        bastion = ledger.bastion
    }
    
    private func rollback(steps: [SagaStep], ledger: SagaLedger, upTo failedStepID: String) async {
        let completed = ledger.completedSteps
        let stepMap: [String: SagaStep] = Dictionary(uniqueKeysWithValues: steps.map { ($0.stepID, $0) })
        
        for stepID in completed.reversed() {
            guard let step = stepMap[stepID] else { continue }
            await step.compensate(ledger: ledger)
        }
    }
    
    func approveConsent(das: @escaping () -> Void) {
        ensureHydrated()
        consentTask = Task { [weak self] in
            guard let self = self else { return }
            
            let granted = await self.kit.watchman.raiseQuery()
            let now = Date()
            
            self.bastion.consentForged = granted
            self.bastion.consentBarred = !granted
            self.bastion.consentStampedAt = now
            
            self.effectQueue.enqueue(.persistState)
            
            if granted {
                self.effectQueue.enqueue(.wirePushBeacon)
            }
            
            self.outcomeSubject.send(.raiseDrawbridge)
            das()
        }
    }
    
    func deferConsent() {
        ensureHydrated()
        let now = Date()
        bastion.consentStampedAt = now
        effectQueue.enqueue(.persistState)
        outcomeSubject.send(.raiseDrawbridge)
    }
    
    func reportTimeUp() -> Bool {
        return sigil.tryStamp()
    }
}
