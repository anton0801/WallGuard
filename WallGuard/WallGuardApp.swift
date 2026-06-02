import SwiftUI

@main
struct WallGuardApp: App {
    @AppStorage("appTheme") private var appTheme = "dark"
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(colorScheme)
                .onAppear { appState.loadAll() }
        }
    }

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "dark":   return .dark
        case "light":  return .light
        default:       return nil
        }
    }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var phase: AppPhase = .splash

    enum AppPhase { case splash, onboarding, main }

    var body: some View {
        ZStack {
            switch phase {
            case .splash:
                SplashView(onFinish: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        phase = hasCompletedOnboarding ? .main : .onboarding
                    }
                })
            case .onboarding:
                OnboardingContainerView(onFinish: {
                    withAnimation(.easeInOut(duration: 0.5)) { phase = .main }
                })
            case .main:
                MainTabView()
            }
        }
    }
}
