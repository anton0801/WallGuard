import SwiftUI

// MARK: - PhotosView
struct PhotosView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCat: WGPhoto.PhotoCategory? = nil
    @State private var showAddPhoto = false
    @State private var selectedPhoto: WGPhoto?   = nil

    var filtered: [WGPhoto] {
        guard let cat = selectedCat else { return appState.photos }
        return appState.photos.filter { $0.category == cat }
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("Photos").font(.system(size: 28, weight: .bold)).foregroundColor(WGColor.textPrimary)
                        Spacer()
                        Button { showAddPhoto = true } label: {
                            Image(systemName: "plus.circle.fill").font(.system(size: 26)).foregroundColor(WGColor.yellow)
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 12)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: selectedCat == nil) { selectedCat = nil }
                            ForEach(WGPhoto.PhotoCategory.allCases, id: \.self) { cat in
                                FilterChip(label: cat.rawValue, color: Color(hex: cat.color),
                                           isSelected: selectedCat == cat) {
                                    selectedCat = selectedCat == cat ? nil : cat
                                }
                            }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 8)
                    }

                    if filtered.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "photo.stack").font(.system(size: 48)).foregroundColor(WGColor.textMuted)
                            Text("No photos yet").foregroundColor(WGColor.textMuted)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 3) {
                                ForEach(filtered) { photo in
                                    PhotoThumb(photo: photo) { selectedPhoto = photo }
                                        .contextMenu {
                                            Button("Delete", role: .destructive) { appState.deletePhoto(photo) }
                                        }
                                }
                            }
                            .padding(.bottom, 90)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddPhoto) { AddPhotoView() }
            .sheet(item: $selectedPhoto)      { photo in PhotoDetailView(photo: photo) }
        }
    }
}

// MARK: - PhotoThumb
struct PhotoThumb: View {
    let photo: WGPhoto
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                if let ui = UIImage(data: photo.imageData) {
                    Image(uiImage: ui).resizable().scaledToFill()
                        .aspectRatio(1, contentMode: .fill).clipped()
                } else {
                    Rectangle().fill(WGColor.card).aspectRatio(1, contentMode: .fill)
                        .overlay(Image(systemName: "photo").foregroundColor(WGColor.textMuted))
                }
                Image(systemName: photo.category.icon)
                    .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                    .padding(4).background(Color(hex: photo.category.color).opacity(0.85)).cornerRadius(6).padding(4)
            }
        }
    }
}

// MARK: - PhotoDetailView
struct PhotoDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    let photo: WGPhoto

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss.wrappedValue.dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                if let ui = UIImage(data: photo.imageData) {
                    Image(uiImage: ui).resizable().scaledToFit()
                }
                VStack(spacing: 6) {
                    Text(photo.caption.isEmpty ? photo.category.rawValue : photo.caption)
                        .font(.system(size: 16, weight: .medium)).foregroundColor(.white)
                    Text(photo.createdAt.formatted(date: .long, time: .omitted))
                        .font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                }
                .padding()
                Spacer()
            }
        }
    }
}

// MARK: - AddPhotoView
struct AddPhotoView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss

    @State private var imageData: Data?                  = nil
    @State private var category:  WGPhoto.PhotoCategory  = .problem
    @State private var caption    = ""
    @State private var showPicker = false
    @State private var saved      = false

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                VStack(spacing: 20) {
                    Button { showPicker = true } label: {
                        ZStack {
                            if let data = imageData, let ui = UIImage(data: data) {
                                Image(uiImage: ui).resizable().scaledToFill()
                                    .frame(maxWidth: .infinity).frame(height: 200).clipped().cornerRadius(16)
                            } else {
                                RoundedRectangle(cornerRadius: 16).fill(WGColor.card).frame(height: 200)
                                    .overlay(VStack(spacing: 8) {
                                        Image(systemName: "camera.fill").font(.system(size: 36)).foregroundColor(WGColor.yellow)
                                        Text("Select Photo").foregroundColor(WGColor.textMuted)
                                    })
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(WGColor.divider, lineWidth: 1))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                        HStack(spacing: 8) {
                            ForEach(WGPhoto.PhotoCategory.allCases, id: \.self) { cat in
                                Button { withAnimation { category = cat } } label: {
                                    Text(cat.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(category == cat ? .white : WGColor.textSecondary)
                                        .frame(maxWidth: .infinity).frame(height: 38)
                                        .background(category == cat ? Color(hex: cat.color) : WGColor.card).cornerRadius(10)
                                }
                            }
                        }
                    }

                    WGFormField(title: "Caption", placeholder: "Optional caption...", text: $caption)

                    Button {
                        guard let data = imageData else { return }
                        let p = WGPhoto(imageData: data, category: category, caption: caption)
                        appState.addPhoto(p)
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss.wrappedValue.dismiss() }
                    } label: {
                        Text(saved ? "Saved!" : "Save Photo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(imageData == nil ? WGColor.textMuted : WGColor.bg)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(imageData == nil ? WGColor.divider : (saved ? WGColor.success : WGColor.yellow))
                            .cornerRadius(14)
                    }
                    .disabled(imageData == nil)

                    Spacer()
                }
                .padding(.horizontal, 18).padding(.top, 8)
            }
            .navigationTitle("Add Photo").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(WGColor.textMuted)
                }
            }
            .sheet(isPresented: $showPicker) { ImagePickerView(imageData: $imageData) }
        }
        .colorScheme(.dark)
    }
}
