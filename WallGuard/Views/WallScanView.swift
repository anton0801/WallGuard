import SwiftUI

struct WallScanView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss

    var preselectedRoomId: UUID? = nil

    @State private var selectedRoomId: UUID?   = nil
    @State private var title          = ""
    @State private var widthMm:       Double   = 0
    @State private var lengthMm:      Double   = 0
    @State private var category:      WGDefect.DefectCategory = .crack
    @State private var notes          = ""
    @State private var photoData:     Data?    = nil
    @State private var markerX:       Double   = 0.5
    @State private var markerY:       Double   = 0.5
    @State private var showPhotoPicker = false
    @State private var showCompare    = false
    @State private var saved          = false
    @State private var showVal        = false

    var riskLevel: WGDefect.RiskLevel { WGDefect.RiskLevel.assess(width: widthMm, length: lengthMm) }
    var isValid:   Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Photo + marker
                        ZStack {
                            if let data = photoData, let ui = UIImage(data: data) {
                                Image(uiImage: ui).resizable().scaledToFill()
                                    .frame(maxWidth: .infinity).frame(height: 220).clipped().cornerRadius(16)
                            } else {
                                RoundedRectangle(cornerRadius: 16).fill(WGColor.card).frame(height: 220)
                                    .overlay(VStack(spacing: 12) {
                                        Image(systemName: "camera.viewfinder").font(.system(size: 40)).foregroundColor(WGColor.yellow)
                                        Text("Tap camera to photograph wall").font(.system(size: 14)).foregroundColor(WGColor.textMuted)
                                    })
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(WGColor.divider, lineWidth: 1))
                            }

                            // Draggable marker
                            GeometryReader { geo in
                                Circle()
                                    .fill(Color(hex: riskLevel.color).opacity(0.8))
                                    .frame(width: 24, height: 24)
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                                    .shadow(color: Color(hex: riskLevel.color).opacity(0.5), radius: 8)
                                    .position(x: geo.size.width * markerX, y: geo.size.height * markerY)
                                    .gesture(DragGesture().onChanged { v in
                                        markerX = max(0, min(1, v.location.x / geo.size.width))
                                        markerY = max(0, min(1, v.location.y / geo.size.height))
                                    })
                            }
                            .frame(height: 220).cornerRadius(16)

                            // Camera button
                            VStack {
                                HStack {
                                    Spacer()
                                    Button { showPhotoPicker = true } label: {
                                        ZStack {
                                            Circle().fill(WGColor.card.opacity(0.85)).frame(width: 40, height: 40)
                                            Image(systemName: "camera.fill").foregroundColor(WGColor.yellow).font(.system(size: 16))
                                        }
                                    }
                                    .padding(10)
                                }
                                Spacer()
                            }
                        }
                        .frame(height: 220)

                        // Risk indicator
                        HStack {
                            Image(systemName: riskLevel.icon).foregroundColor(Color(hex: riskLevel.color))
                            Text("Risk: \(riskLevel.rawValue)")
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: riskLevel.color))
                            Spacer()
                            Text("Drag marker to position defect").font(.system(size: 11)).foregroundColor(WGColor.textMuted)
                        }
                        .padding(12).background(Color(hex: riskLevel.color).opacity(0.1)).cornerRadius(12)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: riskLevel)

                        WGFormField(title: "Defect Title", placeholder: "e.g. Corner crack", text: $title)

                        // Room picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Room").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            Picker("Room", selection: $selectedRoomId) {
                                Text("None").tag(nil as UUID?)
                                ForEach(appState.rooms) { r in Text(r.name).tag(r.id as UUID?) }
                            }
                            .pickerStyle(.menu).accentColor(WGColor.yellow)
                            .padding(12).background(WGColor.card).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1))
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(WGDefect.DefectCategory.allCases, id: \.self) { cat in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { category = cat }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: cat.icon)
                                                Text(cat.rawValue)
                                            }
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(category == cat ? WGColor.bg : WGColor.textSecondary)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(category == cat ? WGColor.yellow : WGColor.card).cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10)
                                                .stroke(category == cat ? WGColor.yellow : WGColor.divider, lineWidth: 1))
                                        }
                                    }
                                }
                            }
                        }

                        // Measurements
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Measurements").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Width (mm)").font(.system(size: 11)).foregroundColor(WGColor.textMuted)
                                    HStack {
                                        TextField("0", value: $widthMm, format: .number)
                                            .foregroundColor(WGColor.textPrimary).keyboardType(.decimalPad)
                                        Text("mm").foregroundColor(WGColor.textMuted)
                                    }
                                    .padding(10).background(WGColor.card).cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(WGColor.divider, lineWidth: 1))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Length (mm)").font(.system(size: 11)).foregroundColor(WGColor.textMuted)
                                    HStack {
                                        TextField("0", value: $lengthMm, format: .number)
                                            .foregroundColor(WGColor.textPrimary).keyboardType(.decimalPad)
                                        Text("mm").foregroundColor(WGColor.textMuted)
                                    }
                                    .padding(10).background(WGColor.card).cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(WGColor.divider, lineWidth: 1))
                                }
                            }
                        }

                        WGFormField(title: "Notes", placeholder: "Observations...", text: $notes, isMultiline: true)

                        if showVal && !isValid {
                            Text("Defect title is required.").font(.system(size: 13)).foregroundColor(WGColor.danger)
                        }

                        HStack(spacing: 12) {
                            Button {
                                guard isValid else { showVal = true; return }
                                let d = WGDefect(
                                    roomId:    selectedRoomId ?? (appState.rooms.first?.id ?? UUID()),
                                    title:     title.trimmingCharacters(in: .whitespaces),
                                    category:  category,
                                    widthMm:   widthMm, lengthMm: lengthMm,
                                    riskLevel: riskLevel,
                                    notes:     notes,
                                    photoData: photoData,
                                    markerX:   markerX, markerY: markerY
                                )
                                appState.addDefect(d)
                                saved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { dismiss.wrappedValue.dismiss() }
                            } label: {
                                HStack {
                                    Image(systemName: saved ? "checkmark.circle.fill" : "target")
                                    Text(saved ? "Saved!" : "Save Defect").font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(WGColor.bg).frame(maxWidth: .infinity).frame(height: 50)
                                .background(saved ? WGColor.success : WGColor.yellow).cornerRadius(14)
                            }

                            Button { showCompare = true } label: {
                                HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                    Text("Compare").font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(WGColor.textPrimary).frame(width: 130).frame(height: 50)
                                .background(WGColor.card).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(WGColor.divider, lineWidth: 1))
                            }
                        }

                        Spacer().frame(height: 50)
                    }
                    .padding(.horizontal, 18).padding(.top, 16)
                }
            }
            .navigationTitle("Wall Scan").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss.wrappedValue.dismiss() }.foregroundColor(WGColor.textMuted)
                }
            }
            .sheet(isPresented: $showPhotoPicker) { ImagePickerView(imageData: $photoData) }
            .sheet(isPresented: $showCompare) { CompareDefectsView() }
            .onAppear { if let id = preselectedRoomId { selectedRoomId = id } }
        }
        .colorScheme(.dark)
    }
}

// MARK: - CompareDefectsView
struct CompareDefectsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @State private var leftId:  UUID? = nil
    @State private var rightId: UUID? = nil

    var leftDefect:  WGDefect? { appState.defects.first { $0.id == leftId  } }
    var rightDefect: WGDefect? { appState.defects.first { $0.id == rightId } }

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Select two defects to compare")
                            .font(.system(size: 14)).foregroundColor(WGColor.textMuted)

                        HStack(spacing: 12) {
                            CompareSlot(label: "Defect A", defect: leftDefect) {
                                if let d = appState.defects.first(where: { $0.id != rightId }) { leftId = d.id }
                            }
                            CompareSlot(label: "Defect B", defect: rightDefect) {
                                if let d = appState.defects.first(where: { $0.id != leftId  }) { rightId = d.id }
                            }
                        }

                        if let l = leftDefect, let r = rightDefect {
                            CompareResultView(a: l, b: r)
                        }

                        ForEach(appState.defects) { d in
                            Button {
                                if leftId == nil || leftId == d.id { leftId = d.id }
                                else { rightId = d.id }
                            } label: {
                                HStack {
                                    Text(d.title).foregroundColor(WGColor.textPrimary).font(.system(size: 14))
                                    Spacer()
                                    if d.id == leftId  { Text("A").foregroundColor(WGColor.yellow).font(.system(size: 12, weight: .bold)) }
                                    if d.id == rightId { Text("B").foregroundColor(WGColor.blue).font(.system(size: 12, weight: .bold)) }
                                }
                                .padding(12).background(WGColor.card).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(WGColor.divider, lineWidth: 1))
                            }
                        }
                        Spacer().frame(height: 40)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Compare Defects").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss.wrappedValue.dismiss() }.foregroundColor(WGColor.textMuted)
                }
            }
        }
        .colorScheme(.dark)
    }
}

struct CompareSlot: View {
    let label: String; let defect: WGDefect?; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(WGColor.textMuted)
                if let d = defect {
                    Text(d.title).font(.system(size: 13, weight: .semibold)).foregroundColor(WGColor.textPrimary).lineLimit(2)
                    Text(d.riskLevel.rawValue).font(.system(size: 11)).foregroundColor(Color(hex: d.riskLevel.color))
                } else {
                    Image(systemName: "plus.circle").foregroundColor(WGColor.textMuted)
                    Text("Select").font(.system(size: 13)).foregroundColor(WGColor.textMuted)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 100)
            .background(WGColor.card).cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(WGColor.divider, lineWidth: 1))
        }
    }
}

struct CompareResultView: View {
    let a: WGDefect; let b: WGDefect
    var body: some View {
        VStack(spacing: 10) {
            Text("Comparison").font(.system(size: 15, weight: .semibold)).foregroundColor(WGColor.textPrimary)
            compareRow("Width",  av: "\(String(format: "%.1f", a.widthMm))mm",  bv: "\(String(format: "%.1f", b.widthMm))mm",  aWins: a.widthMm < b.widthMm)
            compareRow("Length", av: "\(String(format: "%.1f", a.lengthMm))mm", bv: "\(String(format: "%.1f", b.lengthMm))mm", aWins: a.lengthMm < b.lengthMm)
            compareRow("Risk",   av: a.riskLevel.rawValue, bv: b.riskLevel.rawValue, aWins: a.riskLevel != .critical)
        }
        .padding(14).background(WGColor.card).cornerRadius(14)
    }

    @ViewBuilder
    func compareRow(_ label: String, av: String, bv: String, aWins: Bool) -> some View {
        HStack {
            Text(av).font(.system(size: 13, weight: .semibold))
                .foregroundColor(aWins ? WGColor.success : WGColor.danger).frame(maxWidth: .infinity, alignment: .leading)
            Text(label).font(.system(size: 12)).foregroundColor(WGColor.textMuted).frame(width: 70, alignment: .center)
            Text(bv).font(.system(size: 13, weight: .semibold))
                .foregroundColor(aWins ? WGColor.danger : WGColor.success).frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
