import SwiftUI

@main
struct WallGuardApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegator

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }

}

struct RootView: View {
    
    @AppStorage("appTheme") private var appTheme = "dark"
    @StateObject private var appState = AppState()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var phase: AppPhase = .none

    enum AppPhase { case onboarding, main, none }

    var body: some View {
        ZStack {
            switch phase {
            case .onboarding:
                OnboardingContainerView(onFinish: {
                    withAnimation(.easeInOut(duration: 0.5)) { phase = .main }
                })
            case .main:
                MainTabView()
            case .none:
                EmptyView()
            }
        }
        .preferredColorScheme(colorScheme)
        .onAppear { appState.loadAll() }
    }
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "dark":   return .dark
        case "light":  return .light
        default:       return nil
        }
    }
    
}
