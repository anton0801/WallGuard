import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                DashboardView().tag(0)
                ProjectsView().tag(1)
                WallScanView().tag(2)
                ReportsView().tag(3)
                SettingsView().tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - CustomTabBar
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let items: [(icon: String, label: String)] = [
        ("square.grid.2x2.fill", "Dashboard"),
        ("building.2.fill",      "Projects"),
        ("camera.viewfinder",    "Scan"),
        ("chart.bar.fill",       "Reports"),
        ("gearshape.fill",       "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = i }
                } label: {
                    VStack(spacing: 4) {
                        if i == 2 {
                            // Center Scan button
                            ZStack {
                                Circle()
                                    .fill(selectedTab == 2
                                          ? LinearGradient(colors: [WGColor.yellow, WGColor.yellowActive],
                                                           startPoint: .top, endPoint: .bottom)
                                          : LinearGradient(colors: [WGColor.card, WGColor.cardHover],
                                                           startPoint: .top, endPoint: .bottom))
                                    .frame(width: 56, height: 56)
                                    .shadow(color: selectedTab == 2 ? WGColor.yellowGlowFill : .clear, radius: 12)
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(selectedTab == 2 ? WGColor.bg : WGColor.textMuted)
                            }
                            .offset(y: -10)
                        } else {
                            Image(systemName: items[i].icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == i ? WGColor.yellow : WGColor.textMuted)
                            Text(items[i].label)
                                .font(.system(size: 10, weight: selectedTab == i ? .semibold : .regular))
                                .foregroundColor(selectedTab == i ? WGColor.yellow : WGColor.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(height: 70)
        .background(WGColor.card.ignoresSafeArea())
        .overlay(Rectangle().fill(WGColor.divider).frame(height: 0.5), alignment: .top)
    }
}
