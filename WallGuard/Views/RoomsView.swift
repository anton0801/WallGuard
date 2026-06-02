import SwiftUI

// MARK: - RoomsView
struct RoomsView: View {
    @EnvironmentObject var appState: AppState
    let project: WGProject
    @State private var showAddRoom     = false
    @State private var filterStatus:   WGRoom.RoomStatus? = nil

    var rooms: [WGRoom] {
        let all = appState.rooms(for: project.id)
        guard let f = filterStatus else { return all }
        return all.filter { $0.status == f }
    }

    var body: some View {
        ZStack {
            WGColor.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: filterStatus == nil) { filterStatus = nil }
                        ForEach(WGRoom.RoomStatus.allCases, id: \.self) { s in
                            FilterChip(label: s.rawValue, color: Color(hex: s.color), isSelected: filterStatus == s) {
                                filterStatus = filterStatus == s ? nil : s
                            }
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 12)
                }

                if rooms.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "door.left.hand.open").font(.system(size: 48)).foregroundColor(WGColor.textMuted)
                        Text("No rooms yet").foregroundColor(WGColor.textMuted)
                        Button("Add Room") { showAddRoom = true }
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(WGColor.bg)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(WGColor.yellow).cornerRadius(12)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(rooms) { room in
                                NavigationLink(destination: RoomDetailView(room: room)) {
                                    RoomCard(room: room)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button("Delete", role: .destructive) { appState.deleteRoom(room) }
                                }
                            }
                        }
                        .padding(.horizontal, 18).padding(.bottom, 90)
                    }
                }
            }

            // FAB
            VStack { Spacer()
                HStack { Spacer()
                    Button { showAddRoom = true } label: {
                        Image(systemName: "plus").font(.system(size: 20, weight: .bold)).foregroundColor(WGColor.bg)
                            .frame(width: 56, height: 56).background(WGColor.yellow).clipShape(Circle())
                            .shadow(color: WGColor.yellowGlowFill, radius: 12)
                    }
                    .padding(.trailing, 20).padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddRoom) { AddRoomView(projectId: project.id) }
    }
}

// MARK: - RoomCard
struct RoomCard: View {
    @EnvironmentObject var appState: AppState
    let room: WGRoom
    var defectCount: Int { appState.defects(for: room.id).count }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                if let data = room.coverPhotoData, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFill()
                        .frame(width: 60, height: 60).clipped().cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12).fill(WGColor.bgSoft).frame(width: 60, height: 60)
                        .overlay(Image(systemName: "door.left.hand.open").foregroundColor(WGColor.textMuted).font(.system(size: 22)))
                }
                Circle().fill(Color(hex: room.status.color)).frame(width: 10, height: 10)
                    .overlay(Circle().stroke(WGColor.card, lineWidth: 2))
                    .offset(x: 22, y: -22)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name).font(.system(size: 16, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                HStack(spacing: 12) {
                    InfoChip(icon: "square.fill", value: "\(String(format: "%.0f", room.area)) m²", label: "")
                    InfoChip(icon: "exclamationmark.triangle", value: "\(defectCount)", label: "defects")
                }
                Text("Floor \(room.floor)").font(.system(size: 12)).foregroundColor(WGColor.textMuted)
            }
            Spacer()
            StatusBadge(text: room.status.rawValue, color: Color(hex: room.status.color))
        }
        .padding(14).background(WGColor.card).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WGColor.divider, lineWidth: 1))
    }
}

// MARK: - RoomDetailView
struct RoomDetailView: View {
    @EnvironmentObject var appState: AppState
    let room: WGRoom
    @State private var showWallScan  = false
    @State private var showAddRecord = false

    var defects: [WGDefect] { appState.defects(for: room.id) }

    var body: some View {
        ZStack {
            WGColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(room.name).font(.system(size: 22, weight: .bold)).foregroundColor(WGColor.textPrimary)
                                Text("Floor \(room.floor) · \(room.area, specifier: "%.0f") m²")
                                    .font(.system(size: 14)).foregroundColor(WGColor.textMuted)
                            }
                            Spacer()
                            StatusBadge(text: room.status.rawValue, color: Color(hex: room.status.color))
                        }
                        if !room.notes.isEmpty {
                            Text(room.notes).font(.system(size: 14)).foregroundColor(WGColor.textSecondary)
                        }
                    }
                    .padding(16).background(WGColor.card).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(WGColor.divider, lineWidth: 1))

                    HStack(spacing: 12) {
                        Button { showWallScan = true } label: {
                            Label("Wall Scan", systemImage: "camera.viewfinder")
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(WGColor.bg)
                                .frame(maxWidth: .infinity).frame(height: 44)
                                .background(WGColor.yellow).cornerRadius(12)
                        }
                        Button { showAddRecord = true } label: {
                            Label("Add Record", systemImage: "plus.circle")
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                                .frame(maxWidth: .infinity).frame(height: 44)
                                .background(WGColor.card).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1))
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Defects (\(defects.count))")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                        if defects.isEmpty {
                            Text("No defects recorded. Use Wall Scan to add.")
                                .font(.system(size: 14)).foregroundColor(WGColor.textMuted).padding(12)
                        } else {
                            ForEach(defects) { defect in
                                NavigationLink(destination: DefectDetailView(defect: defect)) {
                                    DefectRow(defect: defect)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 18).padding(.top, 16)
            }
        }
        .navigationTitle("Room Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showWallScan)  { WallScanView(preselectedRoomId: room.id) }
        .sheet(isPresented: $showAddRecord) { AddRecordView(preselectedRoomId: room.id) }
    }
}

// MARK: - DefectRow
struct DefectRow: View {
    let defect: WGDefect
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: defect.riskLevel.icon)
                .foregroundColor(Color(hex: defect.riskLevel.color)).font(.system(size: 20)).frame(width: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(defect.title).font(.system(size: 15, weight: .medium)).foregroundColor(WGColor.textPrimary)
                Text("\(defect.category.rawValue) · \(defect.widthMm, specifier: "%.1f")×\(defect.lengthMm, specifier: "%.1f")mm")
                    .font(.system(size: 12)).foregroundColor(WGColor.textMuted)
            }
            Spacer()
            if defect.isResolved { Image(systemName: "checkmark.circle.fill").foregroundColor(WGColor.success) }
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(WGColor.textMuted)
        }
        .padding(12).background(WGColor.card).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: defect.riskLevel.color).opacity(0.2), lineWidth: 1))
    }
}

// MARK: - AddRoomView
struct AddRoomView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    let projectId: UUID

    @State private var name            = ""
    @State private var floor           = 1
    @State private var area:  Double   = 0
    @State private var notes           = ""
    @State private var coverPhotoData: Data? = nil
    @State private var showPhotoPicker = false
    @State private var showVal         = false
    @State private var saved           = false

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        WGFormField(title: "Room Name", placeholder: "e.g. Living Room", text: $name)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Floor").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            HStack {
                                Button { if floor > -10 { floor -= 1 } } label: {
                                    Image(systemName: "minus.circle.fill").foregroundColor(WGColor.textMuted).font(.system(size: 24))
                                }
                                Spacer()
                                Text(floor == 0 ? "Ground" : (floor < 0 ? "B\(abs(floor))" : "\(floor)"))
                                    .font(.system(size: 20, weight: .bold)).foregroundColor(WGColor.textPrimary).frame(width: 60)
                                Spacer()
                                Button { if floor < 100 { floor += 1 } } label: {
                                    Image(systemName: "plus.circle.fill").foregroundColor(WGColor.yellow).font(.system(size: 24))
                                }
                            }
                            .padding(14).background(WGColor.card).cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Area (m²)").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            HStack {
                                TextField("0", value: $area, format: .number)
                                    .foregroundColor(WGColor.textPrimary).keyboardType(.decimalPad)
                                Text("m²").foregroundColor(WGColor.textMuted)
                            }
                            .padding(12).background(WGColor.card).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1))
                        }

                        WGFormField(title: "Notes", placeholder: "Room description...", text: $notes, isMultiline: true)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cover Photo").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            Button { showPhotoPicker = true } label: {
                                ZStack {
                                    if let data = coverPhotoData, let ui = UIImage(data: data) {
                                        Image(uiImage: ui).resizable().scaledToFill()
                                            .frame(maxWidth: .infinity).frame(height: 140).clipped().cornerRadius(14)
                                    } else {
                                        RoundedRectangle(cornerRadius: 14).fill(WGColor.card).frame(height: 140)
                                            .overlay(VStack(spacing: 8) {
                                                Image(systemName: "camera.fill").font(.system(size: 28)).foregroundColor(WGColor.textMuted)
                                                Text("Tap to add cover photo").font(.system(size: 13)).foregroundColor(WGColor.textMuted)
                                            })
                                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(WGColor.divider, lineWidth: 1))
                                    }
                                }
                            }
                        }

                        if showVal && !isValid {
                            Text("Room name is required.").font(.system(size: 13)).foregroundColor(WGColor.danger)
                        }

                        Button {
                            guard isValid else { showVal = true; return }
                            let r = WGRoom(projectId: projectId,
                                          name: name.trimmingCharacters(in: .whitespaces),
                                          floor: floor, area: area, notes: notes,
                                          coverPhotoData: coverPhotoData)
                            appState.addRoom(r)
                            saved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss.wrappedValue.dismiss() }
                        } label: {
                            HStack {
                                Image(systemName: saved ? "checkmark.circle.fill" : "plus.circle.fill")
                                Text(saved ? "Saved!" : "Save Room").font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(WGColor.bg).frame(maxWidth: .infinity).frame(height: 52)
                            .background(saved ? WGColor.success : WGColor.yellow).cornerRadius(14)
                        }
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 18).padding(.top, 8)
                }
            }
            .navigationTitle("New Room").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(WGColor.textMuted)
                }
            }
            .sheet(isPresented: $showPhotoPicker) { ImagePickerView(imageData: $coverPhotoData) }
        }
        .colorScheme(.dark)
    }
}
