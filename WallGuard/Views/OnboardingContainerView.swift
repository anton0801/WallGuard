import SwiftUI

// MARK: - OnboardingContainerView
struct OnboardingContainerView: View {
    var onFinish: () -> Void
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            WGColor.bg.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPage1(onNext: { withAnimation { currentPage = 1 } }).tag(0)
                OnboardingPage2(onNext: { withAnimation { currentPage = 2 } }).tag(1)
                OnboardingPage3(onFinish: { hasCompletedOnboarding = true; onFinish() }).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)

            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { hasCompletedOnboarding = true; onFinish() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(WGColor.textMuted)
                        .padding()
                }
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == currentPage ? WGColor.yellow : WGColor.divider)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Page 1: Understand the problem
struct OnboardingPage1: View {
    var onNext: () -> Void

    @State private var appear         = false
    @State private var burst          = false
    @State private var crackScale:    CGFloat = 0
    @State private var particleOpacity: Double = 0
    @State private var particles: [(CGFloat, CGFloat)] = []

    var body: some View {
        ZStack {
            LinearGradient(colors: [WGColor.bgDeep, WGColor.bg],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                // Interactive wall illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(WGColor.card).frame(width: 280, height: 200)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(WGColor.divider, lineWidth: 1))

                    ForEach(0..<5) { i in
                        Rectangle().fill(WGColor.divider.opacity(0.5))
                            .frame(width: 230, height: 0.5).offset(y: CGFloat(i - 2) * 30)
                    }

                    Canvas { ctx, size in
                        var p = Path()
                        p.move(to: CGPoint(x: size.width * 0.4,  y: size.height * 0.2))
                        p.addLine(to: CGPoint(x: size.width * 0.48, y: size.height * 0.45))
                        p.addLine(to: CGPoint(x: size.width * 0.42, y: size.height * 0.6))
                        p.addLine(to: CGPoint(x: size.width * 0.5,  y: size.height * 0.8))
                        ctx.stroke(p, with: .color(WGColor.orange), lineWidth: 2)
                        var p2 = Path()
                        p2.move(to: CGPoint(x: size.width * 0.48, y: size.height * 0.45))
                        p2.addLine(to: CGPoint(x: size.width * 0.62, y: size.height * 0.55))
                        ctx.stroke(p2, with: .color(WGColor.orange.opacity(0.6)), lineWidth: 1.5)
                    }
                    .frame(width: 280, height: 200).scaleEffect(crackScale)

                    ZStack {
                        Circle().fill(WGColor.danger.opacity(0.2)).frame(width: 40, height: 40)
                        Circle().fill(WGColor.danger).frame(width: 12, height: 12)
                    }
                    .offset(x: 10, y: 10)
                    .scaleEffect(burst ? 1.4 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: burst)

                    if burst {
                        ForEach(particles.indices, id: \.self) { i in
                            Circle().fill(WGColor.orange).frame(width: 5, height: 5)
                                .offset(x: particles[i].0 * 60, y: particles[i].1 * 60)
                                .opacity(particleOpacity)
                        }
                    }
                    Text("Tap to reveal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(WGColor.textMuted)
                        .offset(y: 90).opacity(burst ? 0 : 1)
                }
                .onTapGesture { triggerBurst() }
                .scaleEffect(appear ? 1 : 0.85).opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appear)

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    Text("Understand the problem")
                        .font(.system(size: 26, weight: .bold)).foregroundColor(WGColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Cracks grow unnoticed.\nDamage gets worse over time without tracking.")
                        .font(.system(size: 15)).foregroundColor(WGColor.textSecondary)
                        .multilineTextAlignment(.center).lineSpacing(4)
                }
                .offset(y: appear ? 0 : 20).opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35), value: appear)
                .padding(.horizontal, 32)

                Spacer().frame(height: 48)

                Button(action: onNext) {
                    HStack {
                        Text("Next").font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(WGColor.bg).frame(maxWidth: .infinity).frame(height: 52)
                    .background(WGColor.yellow).cornerRadius(14)
                }
                .padding(.horizontal, 32)
                .scaleEffect(appear ? 1 : 0.9).opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: appear)

                Spacer().frame(height: 80)
            }
        }
        .onAppear {
            appear = true; crackScale = 1
            particles = (0..<12).map { _ in (CGFloat.random(in: -1...1), CGFloat.random(in: -1...1)) }
        }
        .onDisappear { appear = false; burst = false }
    }

    private func triggerBurst() {
        burst = true
        withAnimation(.easeOut(duration: 0.4))          { particleOpacity = 1 }
        withAnimation(.easeIn(duration: 0.6).delay(0.3)) { particleOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { burst = false }
    }
}

// MARK: - Page 2: Track everything
struct OnboardingPage2: View {
    var onNext: () -> Void

    @State private var appear          = false
    @State private var dragOffset:     CGSize = .zero
    @State private var cardAngle:      Double = 0
    @State private var visibleCard     = 0

    let cards: [(String, String, String)] = [
        ("ruler",           "2.3 mm width",        "Crack A"),
        ("calendar",        "Dec 5, 2024",          "Last check"),
        ("chart.bar.fill",  "Growing 0.2mm/mo",     "Trend"),
        ("camera.fill",     "4 photos",             "Evidence")
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [WGColor.bgDeep, WGColor.bg],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    ForEach(cards.indices.reversed(), id: \.self) { i in
                        if i >= visibleCard && i < visibleCard + 3 {
                            let off = i - visibleCard
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(WGColor.yellow.opacity(0.15)).frame(width: 44, height: 44)
                                    Image(systemName: cards[i].0).foregroundColor(WGColor.yellow).font(.system(size: 18))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cards[i].2).font(.system(size: 12, weight: .medium)).foregroundColor(WGColor.textMuted)
                                    Text(cards[i].1).font(.system(size: 16, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(WGColor.textMuted)
                            }
                            .padding(16).background(WGColor.card).cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(WGColor.divider, lineWidth: 1))
                            .frame(width: 300)
                            .offset(x: off == 0 ? dragOffset.width : 0, y: CGFloat(off) * -8)
                            .rotationEffect(.degrees(off == 0 ? cardAngle : 0))
                            .scaleEffect(1.0 - CGFloat(off) * 0.04)
                            .shadow(color: .black.opacity(0.3), radius: 8)
                            .gesture(off == 0 ? DragGesture()
                                .onChanged { v in dragOffset = v.translation; cardAngle = Double(v.translation.width / 20) }
                                .onEnded   { v in
                                    if abs(v.translation.width) > 80 || abs(v.translation.height) > 80 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            dragOffset = CGSize(width: v.translation.width * 3, height: v.translation.height * 3)
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            visibleCard = (visibleCard + 1) % cards.count
                                            dragOffset = .zero; cardAngle = 0
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { dragOffset = .zero; cardAngle = 0 }
                                    }
                                } : nil)
                        }
                    }
                }
                .frame(height: 200)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appear)

                Text("← Swipe cards →")
                    .font(.system(size: 12)).foregroundColor(WGColor.textMuted)
                    .padding(.top, 12).opacity(appear ? 1 : 0)

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    Text("Track everything")
                        .font(.system(size: 26, weight: .bold)).foregroundColor(WGColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Keep all measurements, photos and notes\nin one place. Never lose a defect.")
                        .font(.system(size: 15)).foregroundColor(WGColor.textSecondary)
                        .multilineTextAlignment(.center).lineSpacing(4)
                }
                .padding(.horizontal, 32)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35), value: appear)

                Spacer().frame(height: 48)

                Button(action: onNext) {
                    HStack {
                        Text("Next").font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(WGColor.bg).frame(maxWidth: .infinity).frame(height: 52)
                    .background(WGColor.yellow).cornerRadius(14)
                }
                .padding(.horizontal, 32)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: appear)

                Spacer().frame(height: 80)
            }
        }
        .onAppear { appear = true }
        .onDisappear { appear = false }
    }
}

// MARK: - Page 3: Get better results
struct OnboardingPage3: View {
    var onFinish: () -> Void

    @State private var appear          = false
    @State private var checkStates     = [false, false, false]
    @State private var progressValue:  CGFloat = 0

    let checks = [
        ("checkmark.seal.fill",         "Weekly crack scans",    WGColor.success),
        ("chart.line.uptrend.xyaxis",   "Growth trend reports",  WGColor.blue),
        ("bell.badge.fill",             "Smart reminders",       WGColor.orange)
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [WGColor.bgDeep, WGColor.bg],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    ForEach(checks.indices, id: \.self) { i in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(checkStates[i] ? checks[i].2.opacity(0.2) : WGColor.card)
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().stroke(checkStates[i] ? checks[i].2 : WGColor.divider, lineWidth: 1.5))
                                Image(systemName: checks[i].0)
                                    .foregroundColor(checkStates[i] ? checks[i].2 : WGColor.textMuted)
                                    .font(.system(size: 18))
                            }
                            Text(checks[i].1)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(checkStates[i] ? WGColor.textPrimary : WGColor.textSecondary)
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(checkStates[i] ? checks[i].2 : WGColor.divider)
                                    .frame(width: 28, height: 28)
                                if checkStates[i] {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                }
                            }
                        }
                        .padding(16).background(WGColor.card).cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(checkStates[i] ? checks[i].2.opacity(0.4) : WGColor.divider, lineWidth: 1))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                checkStates[i].toggle()
                                progressValue = CGFloat(checkStates.filter { $0 }.count) / CGFloat(checks.count)
                            }
                        }
                        .scaleEffect(appear ? 1 : 0.9).opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.1 + 0.2), value: appear)
                    }
                }
                .padding(.horizontal, 32)

                VStack(spacing: 6) {
                    HStack {
                        Text("Readiness").font(.system(size: 12, weight: .medium)).foregroundColor(WGColor.textMuted)
                        Spacer()
                        Text("\(Int(progressValue * 100))%").font(.system(size: 12, weight: .bold)).foregroundColor(WGColor.yellow)
                    }
                    ZStack(alignment: .leading) {
                        Capsule().fill(WGColor.divider).frame(height: 6)
                        Capsule().fill(WGColor.yellow).frame(width: 240 * progressValue, height: 6)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: progressValue)
                    }.frame(width: 240)
                }
                .padding(.top, 16)
                .opacity(appear ? 1 : 0)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    Text("Get better results")
                        .font(.system(size: 26, weight: .bold)).foregroundColor(WGColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Use clear checks, reports and reminders\nto stay ahead of any damage.")
                        .font(.system(size: 15)).foregroundColor(WGColor.textSecondary)
                        .multilineTextAlignment(.center).lineSpacing(4)
                }
                .padding(.horizontal, 32)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: appear)

                Spacer().frame(height: 32)

                Button(action: onFinish) {
                    HStack {
                        Text("Get Started").font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(WGColor.bg).frame(maxWidth: .infinity).frame(height: 52)
                    .background(LinearGradient(colors: [WGColor.yellow, WGColor.yellowActive],
                                              startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
                    .shadow(color: WGColor.yellowGlowFill, radius: 12)
                }
                .padding(.horizontal, 32)
                .scaleEffect(appear ? 1 : 0.9).opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.55), value: appear)

                Spacer().frame(height: 80)
            }
        }
        .onAppear { appear = true }
        .onDisappear { appear = false }
    }
}
