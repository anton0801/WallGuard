import Foundation
import AppsFlyerLib

final class PushSeizureStep: SagaStep {
    let stepID = "pushSeizure"
    
    func forward(ledger: SagaLedger) async -> SagaVerdict {
        guard let pushURL = UserDefaults.standard.string(forKey: BastionDictKey.pushURL),
              !pushURL.isEmpty else {
            return .march
        }
        
        let needsConsent = ledger.bastion.consentRipe
        
        ledger.bastion.routeURL = pushURL
        ledger.bastion.routeMode = "Active"
        ledger.bastion.unbreached = false
        ledger.bastion.fortified = true
        
        ledger.kit.strongroom.seal(ledger.bastion.crystallize())
        ledger.kit.strongroom.brandRoute(url: pushURL, mode: "Active")
        ledger.kit.strongroom.raisePrimedFlag()
        UserDefaults.standard.removeObject(forKey: BastionDictKey.pushURL)
        
        ledger.mark(stepID)
        return .anchor(needsConsent ? .askConsent : .raiseDrawbridge)
    }
    
    func compensate(ledger: SagaLedger) async {}
}

final class BannersGateStep: SagaStep {
    let stepID = "bannersGate"
    
    func forward(ledger: SagaLedger) async -> SagaVerdict {
        guard ledger.bastion.bannersReady else {
            return .anchor(.patrolling)
        }
        ledger.mark(stepID)
        return .march
    }
}

final class OrganicMarchStep: SagaStep {
    let stepID = "organicMarch"
    
    func forward(ledger: SagaLedger) async -> SagaVerdict {
        let needsMarch = ledger.bastion.organicMarch && ledger.bastion.unbreached && !ledger.bastion.organicMarched
        
        guard needsMarch else {
            return .march
        }
        
        ledger.bastion.organicMarched = true
        ledger.kit.strongroom.seal(ledger.bastion.crystallize())
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !ledger.bastion.fortified else {
            return .march
        }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await ledger.kit.sentinel.patrol(deviceID: deviceID)
            for (k, v) in ledger.bastion.scouts {
                if fetched[k] == nil { fetched[k] = v }
            }
            let mapped = fetched.mapValues { "\($0)" }
            ledger.bastion.banners = mapped
            ledger.kit.strongroom.seal(ledger.bastion.crystallize())
        } catch {
        }
        
        ledger.mark(stepID)
        return .march
    }
    
    func compensate(ledger: SagaLedger) async {
        ledger.bastion.organicMarched = false
        ledger.kit.strongroom.seal(ledger.bastion.crystallize())
    }
}

final class HeraldDispatchStep: SagaStep {
    let stepID = "heraldDispatch"
    
    func forward(ledger: SagaLedger) async -> SagaVerdict {
        guard ledger.bastion.bannersReady else {
            return .anchor(.patrolling)
        }
        
        let missive = ledger.bastion.banners.mapValues { $0 as Any }
        
        do {
            let url = try await ledger.kit.herald.dispatch(missive: missive)
            
            let needsConsent = ledger.bastion.consentRipe
            
            ledger.bastion.routeURL = url
            ledger.bastion.routeMode = "Active"
            ledger.bastion.unbreached = false
            ledger.bastion.fortified = true
            
            ledger.kit.strongroom.seal(ledger.bastion.crystallize())
            ledger.kit.strongroom.brandRoute(url: url, mode: "Active")
            ledger.kit.strongroom.raisePrimedFlag()
            UserDefaults.standard.removeObject(forKey: BastionDictKey.pushURL)
            
            ledger.mark(stepID)
            return .anchor(needsConsent ? .askConsent : .raiseDrawbridge)
        } catch let trip as BastionTrip {
            return .tripped(trip)
        } catch {
            return .tripped(.messengerLost(stage: "heraldDispatch"))
        }
    }
}
