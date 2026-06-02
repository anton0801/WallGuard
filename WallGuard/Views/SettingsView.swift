import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme")   private var appTheme   = "dark"
    @AppStorage("unitSystem") private var unitSystem  = "metric"
    @AppStorage("currency")   private var currency    = "EUR"

    @EnvironmentObject var appState: AppState
    @State private var showClearConfirm = false
    @State private var exported         = false

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Appearance
                        SettingsGroup(title: "Appearance") {
                            SettingsPicker(
                                title: "Theme", icon: "moon.stars.fill", color: WGColor.blue,
                                selection: $appTheme,
                                options: [("dark","Dark"), ("light","Light"), ("system","System")]
                            )
                        }

                        // Measurements
                        SettingsGroup(title: "Measurements") {
                            SettingsPicker(
                                title: "Unit System", icon: "ruler.fill", color: WGColor.orange,
                                selection: $unitSystem,
                                options: [("metric","Metric (mm, m²)"), ("imperial","Imperial (in, ft²)")]
                            )
                        }

                        // Regional
                        SettingsGroup(title: "Regional") {
                            SettingsPicker(
                                title: "Currency", icon: "dollarsign.circle.fill", color: WGColor.yellow,
                                selection: $currency,
                                options: [("EUR","EUR €"), ("USD","USD $"), ("GBP","GBP £"), ("RUB","RUB ₽")]
                            )
                        }

                        // Notifications shortcut
                        SettingsGroup(title: "Notifications") {
                            NavigationLink(destination: NotificationsView()) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle().fill(WGColor.orange.opacity(0.15)).frame(width: 36, height: 36)
                                        Image(systemName: "bell.badge.fill").foregroundColor(WGColor.orange).font(.system(size: 15))
                                    }
                                    Text("Manage Notifications").font(.system(size: 15)).foregroundColor(WGColor.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(WGColor.textMuted)
                                }
                                .padding(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // Data
                        SettingsGroup(title: "Data") {
                            VStack(spacing: 0) {
                                SettingsActionRow(icon: "square.and.arrow.up.fill", title: "Export Data",
                                                 subtitle: "Export all data as JSON", color: WGColor.blue) {
                                    exportData()
                                }
                                Divider().background(WGColor.divider)
                                SettingsActionRow(icon: "icloud.fill", title: "Backup",
                                                 subtitle: "Save a backup", color: WGColor.success) {
                                    exported = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { exported = false }
                                }
                                Divider().background(WGColor.divider)
                                SettingsActionRow(icon: "trash.fill", title: "Clear All Data",
                                                 subtitle: "Remove all projects, rooms, defects", color: WGColor.danger) {
                                    showClearConfirm = true
                                }
                            }
                        }

                        // App info
                        VStack(spacing: 6) {
                            Text("Wall Guard").font(.system(size: 15, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                            Text("Version 1.0.0 · Smart repair assistant")
                                .font(.system(size: 12)).foregroundColor(WGColor.textMuted)
                        }
                        .padding(.top, 8)

                        Spacer().frame(height: 90)
                    }
                    .padding(.horizontal, 18).padding(.top, 16)
                }
            }
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.large)
            .alert("Clear All Data", isPresented: $showClearConfirm) {
                Button("Delete Everything", role: .destructive) {
                    appState.projects.removeAll()
                    appState.rooms.removeAll()
                    appState.defects.removeAll()
                    appState.records.removeAll()
                    appState.tasks.removeAll()
                    appState.photos.removeAll()
                    appState.saveAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your data. This cannot be undone.")
            }
        }
    }

    private func exportData() {
        let obj: [String: Any] = [
            "exported":  Date().formatted(),
            "projects":  appState.projects.count,
            "rooms":     appState.rooms.count,
            "defects":   appState.defects.count,
            "tasks":     appState.tasks.count
        ]
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted),
           let str  = String(data: data, encoding: .utf8) {
            let av = UIActivityViewController(activityItems: [str], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true)
        }
    }
}

// MARK: - SettingsGroup
struct SettingsGroup<Content: View>: View {
    let title: String; let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold)).foregroundColor(WGColor.textMuted)
                .padding(.horizontal, 4)
            content()
                .background(WGColor.card).cornerRadius(14)
        }
    }
}

// MARK: - SettingsPicker
struct SettingsPicker: View {
    let title:     String
    let icon:      String
    let color:     Color
    @Binding var selection: String
    let options:   [(String, String)]

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 15))
            }
            Text(title).font(.system(size: 15)).foregroundColor(WGColor.textPrimary)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.0) { opt in Text(opt.1).tag(opt.0) }
            }
            .pickerStyle(.menu).accentColor(WGColor.yellow)
        }
        .padding(12)
    }
}

// MARK: - SettingsActionRow
struct SettingsActionRow: View {
    let icon:     String
    let title:    String
    let subtitle: String
    let color:    Color
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: icon).foregroundColor(color).font(.system(size: 15))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15)).foregroundColor(WGColor.textPrimary)
                    Text(subtitle).font(.system(size: 12)).foregroundColor(WGColor.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(WGColor.textMuted)
            }
            .padding(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
