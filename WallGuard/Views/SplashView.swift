import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var isVisible       = false
    @StateObject private var marshal = WallGuardMarshal()
    @State private var bgOpacity:      Double   = 0
    @State private var bgScale:        CGFloat  = 1.1
    @State private var scanLineOpacity: Double  = 0
    @State private var crackLength1:   CGFloat  = 0
    @State private var crackLength2:   CGFloat  = 0
    @State private var crackLength3:   CGFloat  = 0
    @State private var networkMonitor = NWPathMonitor()
    @State private var logoScale:      CGFloat  = 0.4
    @State private var logoOpacity:    Double   = 0
    @State private var titleOffset:    CGFloat  = 30
    @State private var subtitleOpacity: Double  = 0
    @State private var exitScale:      CGFloat  = 1.0
    @State private var exitOpacity:    Double   = 1.0
    @State private var cancellables = Set<AnyCancellable>()
    @State private var scanY:          CGFloat  = -400
    @State private var radarPulse:     CGFloat  = 0.6
    @State private var gridOpacity:    Double   = 0.12

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bgDeep
                       .ignoresSafeArea()
                
                // Layer 1: Background gradient
                LinearGradient(
                    colors: [WGColor.bgDeep, WGColor.bg, WGColor.bgSoft],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .opacity(bgOpacity)
                .scaleEffect(bgScale)
                
                Image("wall2")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .opacity(0.5)
                    .blur(radius: 2)
                    .ignoresSafeArea()

                // Layer 2: Wall grid texture
                WallGridLayer()
                    .opacity(gridOpacity)
                    .ignoresSafeArea()
                
                NavigationLink(
                    destination: WallGuardShowpiece().navigationBarHidden(true),
                    isActive: $marshal.navigateToWeb
                ) { EmptyView() }

                // Layer 4: Scan beam
                if isVisible {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.clear, WGColor.yellow.opacity(0.15), WGColor.yellow.opacity(0.3),
                                     WGColor.yellow.opacity(0.15), .clear],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(height: 80)
                        .offset(y: scanY)
                        .ignoresSafeArea()
                }

                // Layer 5: Radar pulses
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(WGColor.yellow.opacity(0.08 + Double(i) * 0.04), lineWidth: 1)
                        .frame(width: 120 + CGFloat(i) * 80)
                        .scaleEffect(radarPulse + CGFloat(i) * 0.15)
                        .opacity(Double(3 - i) * 0.12)
                }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $marshal.navigateToMain
                ) { EmptyView() }

                // Layer 6: Logo + Title
                VStack(spacing: 0) {
                    Spacer()

                    // App icon
                    ZStack {
                        Circle()
                            .fill(WGColor.card)
                            .frame(width: 100, height: 100)
                            .shadow(color: WGColor.yellowGlowFill, radius: 20)

                        Image(systemName: "hammer")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(WGColor.yellow)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: WGColor.yellowGlowFill, radius: 30)

                    Spacer().frame(height: 24)

                    Text("Wall Guard")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(WGColor.textPrimary)
                        .offset(y: titleOffset)
                        .opacity(logoOpacity)

                    Spacer().frame(height: 8)

                    HStack(spacing: 6) {
                        Rectangle().fill(WGColor.yellow).frame(width: 20, height: 1)
                        Text("Loading in app content")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(WGColor.textMuted)
                        Rectangle().fill(WGColor.yellow).frame(width: 20, height: 1)
                    }
                    .opacity(subtitleOpacity)

                    Spacer()
                }
                .padding(.horizontal, 40)
            }
            .scaleEffect(exitScale)
            .opacity(exitOpacity)
            .onAppear { runAnimation() }
            .onDisappear { isVisible = false; stopLoops() }
            .fullScreenCover(isPresented: $marshal.showPermissionPrompt) {
                ConsentBastion(marshal: marshal)
            }
            .fullScreenCover(isPresented: $marshal.showOfflineView) {
                OfflineBastion()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func runAnimation() {
        wireStreams()
        wireNetworkMonitoring()
        marshal.ignite()
        isVisible = true

        // Phase 1: Background (0–0.6s)
        withAnimation(.easeOut(duration: 0.6)) { bgOpacity = 1; bgScale = 1.0 }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.3)) {
            gridOpacity = 0.22
        }
        
        func wireNetworkMonitoring() {
            networkMonitor.pathUpdateHandler = { path in
                Task { @MainActor in
                    marshal.networkConnectivityChanged(path.status == .satisfied)
                }
            }
            networkMonitor.start(queue: .global(qos: .background))
        }

        // Phase 2: Cracks + scan (0.6–1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard isVisible else { return }
            withAnimation(.easeInOut(duration: 0.3)) { scanLineOpacity = 1 }
            withAnimation(.easeOut(duration: 0.6)) { crackLength1 = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) { crackLength2 = 1 }
            withAnimation(.easeOut(duration: 0.4).delay(0.25)) { crackLength3 = 1 }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { scanY = 500 }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { radarPulse = 1.1 }
        }

        // Phase 3: Logo (1.4–2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                logoScale = 1.0; logoOpacity = 1.0; titleOffset = 0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.2)) { subtitleOpacity = 1 }
        }
        
        func wireStreams() {
            NotificationCenter.default.publisher(for: .attributionParapet)
                .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
                .sink { data in
                    marshal.ingestAttribution(data)
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: .deeplinksParapet)
                .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
                .sink { data in
                    marshal.ingestDeeplinks(data)
                }
                .store(in: &cancellables)
        }
    }

    private func stopLoops() {
        bgOpacity = 0; bgScale = 1.1; scanLineOpacity = 0
        crackLength1 = 0; crackLength2 = 0; crackLength3 = 0
        logoScale = 0.4; logoOpacity = 0; titleOffset = 30; subtitleOpacity = 0
        scanY = -400; radarPulse = 0.6; gridOpacity = 0.12
    }
}

// MARK: - WallGridLayer
struct WallGridLayer: View {
    var body: some View {
        GeometryReader { _ in
            Canvas { ctx, size in
                let cols = Int(size.width  / 40) + 1
                let rows = Int(size.height / 40) + 1
                for col in 0..<cols {
                    for row in 0..<rows {
                        var path = Path()
                        path.addRect(CGRect(x: CGFloat(col) * 40,
                                           y: CGFloat(row) * 40,
                                           width: 40, height: 40))
                        ctx.stroke(path, with: .color(Color(hex: "334155")), lineWidth: 0.5)
                    }
                }
            }
        }
    }
}

struct ConsentBastion: View {
    let marshal: WallGuardMarshal
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "wall3" : "wall")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.9)
                
                VStack(spacing: 18) {
                    Spacer()
                    Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .multilineTextAlignment(.center)
                    subtitleText
                        .multilineTextAlignment(.center)
                    actionButtons
                }
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM OUR CASINO")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 18) {
            Button {
                marshal.acceptConsent()
            } label: {
                Image("guard")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                marshal.skipConsent()
            } label: {
                Text("Skip")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
    }
}

struct OfflineBastion: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("wall2")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 11)
                    .opacity(0.3)
                
                Image("error")
                    .resizable()
                    .frame(width: 220, height: 260)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
