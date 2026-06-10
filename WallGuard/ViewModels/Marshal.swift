import Foundation
import Combine

@MainActor
final class WallGuardMarshal: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let runner: SagaRunner
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        self.runner = Anchorage.shared.unmoor(SagaRunner.self)
        bindOutcomes()
    }
    
    deinit {
        deadlineTask?.cancel()
    }
    
    private func bindOutcomes() {
        runner.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.handleOutcome(outcome)
            }
            .store(in: &cancellables)
    }
    
    func ignite() {
        runner.wakeBastion()
        armDeadline()
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        Task {
            runner.absorbBanners(data)
            await runner.runSaga()
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        runner.absorbScouts(data)
    }
    
    func acceptConsent() {
        runner.approveConsent {
            self.showPermissionPrompt = false
        }
    }
    
    func skipConsent() {
        showPermissionPrompt = false
        runner.deferConsent()
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleOutcome(_ outcome: WatchOutcome) {
        guard !uiLocked else { return }
        
        switch outcome {
        case .patrolling:
            break
        case .askConsent:
            showPermissionPrompt = true
        case .raiseDrawbridge:
            navigateToWeb = true
        case .overrun:
            navigateToMain = true
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.runner.reportTimeUp()
            if shouldFire {
                self.handleOutcome(.overrun)
            }
        }
    }
}
