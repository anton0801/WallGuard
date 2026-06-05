import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @State private var exported = false

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Summary cards
                        HStack(spacing: 12) {
                            ReportStat(value: "\(appState.projects.count)", label: "Total Projects", color: WGColor.blue)
                            ReportStat(value: "\(appState.defects.count)",  label: "Defects Found",  color: WGColor.danger)
                            ReportStat(value: "\(appState.tasks.filter { $0.isDone }.count)", label: "Tasks Done", color: WGColor.success)
                        }

                        // Defects by risk level
                        ChartSection(title: "Defects by Risk Level") { RiskBarChart() }

                        // Rooms by status
                        ChartSection(title: "Rooms by Status") { RoomStatusChart() }

                        // Defects by category
                        ChartSection(title: "Defects by Category") { CategoryChart() }

                        // Recent records
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Records")
                                .font(.system(size: 16, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                            if appState.records.isEmpty {
                                Text("No records yet").font(.system(size: 14)).foregroundColor(WGColor.textMuted)
                            } else {
                                ForEach(appState.records.prefix(5)) { r in
                                    HStack(spacing: 10) {
                                        Image(systemName: r.category.icon).foregroundColor(WGColor.blue).font(.system(size: 14))
                                        Text(r.title).font(.system(size: 14)).foregroundColor(WGColor.textPrimary).lineLimit(1)
                                        Spacer()
                                        Text(r.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.system(size: 12)).foregroundColor(WGColor.textMuted)
                                    }
                                }
                            }
                        }
                        .padding(14).background(WGColor.card).cornerRadius(16)

                        // Export buttons
                        HStack(spacing: 12) {
                            Button {
                                withAnimation { exported = true }
                                let reportText = buildReportText()
                                presentShareSheet(items: [reportText])
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation { exported = false }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: exported
                                          ? "checkmark.circle.fill"
                                          : "doc.fill")
                                    Text(exported ? "Exported!" : "Export PDF")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(WGColor.bg)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(exported ? WGColor.success : WGColor.yellow)
                                .cornerRadius(14)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: exported)
                            }

                            ShareButton()
                        }

                        Spacer().frame(height: 90)
                    }
                    .padding(.horizontal, 18).padding(.top, 16)
                }
            }
            .navigationTitle("Reports").navigationBarTitleDisplayMode(.large)
        }
    }

    private func buildReportText() -> String {
        var lines = ["=== Wall Guard Report ===",
                     "Generated: \(Date().formatted())", ""]
        lines += ["SUMMARY",
                  "Projects: \(appState.projects.count)",
                  "Rooms: \(appState.rooms.count)",
                  "Defects: \(appState.defects.count)",
                  "Open tasks: \(appState.tasks.filter { !$0.isDone }.count)", ""]
        lines += ["DEFECTS BY RISK"]
        for lvl in WGDefect.RiskLevel.allCases {
            let c = appState.defects.filter { $0.riskLevel == lvl }.count
            lines.append("  \(lvl.rawValue): \(c)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Sub-components
struct ReportStat: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.system(size: 26, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(WGColor.textMuted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(WGColor.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

struct ChartSection<Content: View>: View {
    let title: String; let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(WGColor.textPrimary)
            content()
        }
        .padding(14).background(WGColor.card).cornerRadius(16)
    }
}

struct RiskBarChart: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        let maxCount = max(1, WGDefect.RiskLevel.allCases.map {
            lvl in appState.defects.filter { $0.riskLevel == lvl }.count
        }.max() ?? 1)

        VStack(spacing: 8) {
            ForEach(WGDefect.RiskLevel.allCases, id: \.self) { lvl in
                let count = appState.defects.filter { $0.riskLevel == lvl }.count
                HStack(spacing: 10) {
                    Text(lvl.rawValue).font(.system(size: 12)).foregroundColor(WGColor.textMuted)
                        .frame(width: 60, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(WGColor.bgSoft).frame(height: 20)
                            Capsule().fill(Color(hex: lvl.color))
                                .frame(width: max(8, geo.size.width * CGFloat(count) / CGFloat(maxCount)), height: 20)
                        }
                    }
                    .frame(height: 20)
                    Text("\(count)").font(.system(size: 12, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                        .frame(width: 24)
                }
            }
        }
    }
}

struct RoomStatusChart: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        HStack(spacing: 12) {
            ForEach(WGRoom.RoomStatus.allCases, id: \.self) { status in
                let count = appState.rooms.filter { $0.status == status }.count
                let total = max(1, appState.rooms.count)
                VStack(spacing: 6) {
                    ZStack {
                        Circle().stroke(WGColor.divider, lineWidth: 2).frame(width: 60, height: 60)
                        Circle()
                            .trim(from: 0, to: CGFloat(count) / CGFloat(total))
                            .stroke(Color(hex: status.color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        Text("\(count)").font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: status.color))
                    }
                    Text(status.rawValue).font(.system(size: 11)).foregroundColor(WGColor.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct CategoryChart: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        let total = max(1, appState.defects.count)
        VStack(spacing: 8) {
            ForEach(WGDefect.DefectCategory.allCases, id: \.self) { cat in
                let count = appState.defects.filter { $0.category == cat }.count
                HStack(spacing: 10) {
                    Image(systemName: cat.icon).foregroundColor(WGColor.yellow).font(.system(size: 14)).frame(width: 20)
                    Text(cat.rawValue).font(.system(size: 13)).foregroundColor(WGColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(WGColor.bgSoft).frame(height: 8)
                            Capsule().fill(WGColor.yellow.opacity(0.7))
                                .frame(width: max(4, geo.size.width * CGFloat(count) / CGFloat(total)), height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text("\(count)").font(.system(size: 12, weight: .medium)).foregroundColor(WGColor.textMuted).frame(width: 24)
                }
            }
        }
    }
}

struct ShareButton: View {
    @EnvironmentObject var appState: AppState
    @State private var anchor: CGRect = .zero

    var body: some View {
        Button {
            let text = buildText()
            // Use GeometryReader-captured frame as popover anchor
            let sourceView = findKeyWindow()
            presentShareSheet(items: [text], sourceView: sourceView)
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(WGColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(WGColor.card)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(WGColor.divider, lineWidth: 1)
            )
        }
    }

    private func buildText() -> String {
        var lines = ["=== Wall Guard Report ===",
                     "Generated: \(Date().formatted())", ""]
        lines += ["Projects: \(appState.projects.count)",
                  "Rooms: \(appState.rooms.count)",
                  "Defects: \(appState.defects.count)",
                  "Open tasks: \(appState.tasks.filter { !$0.isDone }.count)"]
        return lines.joined(separator: "\n")
    }

    private func findKeyWindow() -> UIView? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: { $0.isKeyWindow })
    }
}
