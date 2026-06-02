import SwiftUI

// MARK: - ProjectsView
struct ProjectsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddProject = false
    @State private var showArchived   = false
    @State private var searchText     = ""

    var filtered: [WGProject] {
        let base = showArchived ? appState.projects : appState.projects.filter { !$0.isArchived }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.objectType.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Projects")
                            .font(.system(size: 28, weight: .bold)).foregroundColor(WGColor.textPrimary)
                        Spacer()
                        Button {
                            withAnimation { showArchived.toggle() }
                        } label: {
                            Label(showArchived ? "Active" : "Archived",
                                  systemImage: showArchived ? "archivebox" : "archivebox.fill")
                            .font(.system(size: 12, weight: .medium)).foregroundColor(WGColor.textMuted)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(WGColor.card).cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 12)

                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(WGColor.textMuted)
                        TextField("Search projects...", text: $searchText)
                            .foregroundColor(WGColor.textPrimary)
                    }
                    .padding(12).background(WGColor.card).cornerRadius(12)
                    .padding(.horizontal, 18).padding(.bottom, 8)

                    if filtered.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "building.2").font(.system(size: 48)).foregroundColor(WGColor.textMuted)
                            Text(showArchived ? "No archived projects" : "No projects yet")
                                .font(.system(size: 16, weight: .medium)).foregroundColor(WGColor.textMuted)
                            if !showArchived {
                                Button("Create First Project") { showAddProject = true }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(WGColor.bg).padding(.horizontal, 20).padding(.vertical, 10)
                                    .background(WGColor.yellow).cornerRadius(12)
                            }
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { project in
                                    NavigationLink(destination: RoomsView(project: project)) {
                                        ProjectCard(project: project)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button("Archive") { appState.archiveProject(project) }
                                        Button("Delete", role: .destructive) { appState.deleteProject(project) }
                                    }
                                }
                            }
                            .padding(.horizontal, 18).padding(.bottom, 90)
                        }
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { showAddProject = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold)).foregroundColor(WGColor.bg)
                                .frame(width: 56, height: 56).background(WGColor.yellow).clipShape(Circle())
                                .shadow(color: WGColor.yellowGlowFill, radius: 12)
                        }
                        .padding(.trailing, 20).padding(.bottom, 90)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddProject) { AddProjectView() }
        }
    }
}

// MARK: - ProjectCard
struct ProjectCard: View {
    @EnvironmentObject var appState: AppState
    let project: WGProject

    var roomCount:   Int { appState.rooms(for: project.id).count }
    var defectCount: Int {
        appState.rooms(for: project.id).reduce(0) { $0 + appState.defects(for: $1.id).count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.name)
                        .font(.system(size: 17, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                    Text(project.objectType).font(.system(size: 13)).foregroundColor(WGColor.textMuted)
                }
                Spacer()
                StatusBadge(text: project.isArchived ? "Archived" : "Active",
                            color: project.isArchived ? WGColor.textMuted : WGColor.success)
            }
            if !project.address.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill").font(.system(size: 11)).foregroundColor(WGColor.textMuted)
                    Text(project.address).font(.system(size: 13)).foregroundColor(WGColor.textSecondary).lineLimit(1)
                }
            }
            HStack(spacing: 16) {
                InfoChip(icon: "door.left.hand.open", value: "\(roomCount)",   label: "Rooms")
                InfoChip(icon: "exclamationmark.triangle", value: "\(defectCount)", label: "Defects")
                Spacer()
                Text(project.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12)).foregroundColor(WGColor.textMuted)
            }
        }
        .padding(16).background(WGColor.card).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WGColor.divider, lineWidth: 1))
    }
}

// MARK: - AddProjectView
struct AddProjectView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss

    @State private var name       = ""
    @State private var objectType = WGProject.objectTypes[0]
    @State private var address    = ""
    @State private var startDate  = Date()
    @State private var notes      = ""
    @State private var showVal    = false
    @State private var saved      = false

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        WGFormField(title: "Project Name", placeholder: "e.g. Apartment Renovation", text: $name)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Object Type").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(WGProject.objectTypes, id: \.self) { type in
                                        Button(type) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { objectType = type }
                                        }
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(objectType == type ? WGColor.bg : WGColor.textSecondary)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(objectType == type ? WGColor.yellow : WGColor.card).cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(objectType == type ? WGColor.yellow : WGColor.divider, lineWidth: 1))
                                    }
                                }
                            }
                        }

                        WGFormField(title: "Address / Label", placeholder: "e.g. 12 Main St, Apt 3B", text: $address)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Date").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(.compact).colorScheme(.dark)
                                .padding(12).background(WGColor.card).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1))
                        }

                        WGFormField(title: "Notes", placeholder: "Additional notes...", text: $notes, isMultiline: true)

                        if showVal && !isValid {
                            Text("Project name is required.").font(.system(size: 13)).foregroundColor(WGColor.danger)
                        }

                        Button {
                            guard isValid else { showVal = true; return }
                            let p = WGProject(name: name.trimmingCharacters(in: .whitespaces),
                                             objectType: objectType, address: address,
                                             startDate: startDate, notes: notes)
                            appState.addProject(p)
                            saved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss.wrappedValue.dismiss() }
                        } label: {
                            HStack {
                                Image(systemName: saved ? "checkmark.circle.fill" : "folder.badge.plus")
                                Text(saved ? "Saved!" : "Save Project").font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(WGColor.bg).frame(maxWidth: .infinity).frame(height: 52)
                            .background(saved ? WGColor.success : WGColor.yellow).cornerRadius(14)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: saved)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 18).padding(.top, 8)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(WGColor.textMuted)
                }
            }
        }
        .colorScheme(.dark)
    }
}
