import Foundation

final class SagaLedger {
    var bastion: Bastion
    let kit: SentryKit
    private(set) var enacted: [String] = []
    
    init(bastion: Bastion, kit: SentryKit) {
        self.bastion = bastion
        self.kit = kit
    }
    
    func mark(_ stepID: String) {
        enacted.append(stepID)
    }
    
    var completedSteps: [String] { enacted }
}

enum SagaVerdict {
    case march
    case anchor(WatchOutcome)
    case tripped(BastionTrip)
}

protocol SagaStep: AnyObject {
    var stepID: String { get }
    func forward(ledger: SagaLedger) async -> SagaVerdict
    func compensate(ledger: SagaLedger) async
}

extension SagaStep {
    func compensate(ledger: SagaLedger) async {}
}
