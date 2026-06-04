import SwiftUI

// MARK: - ScaleButtonStyle
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - WGFormField
struct WGFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(WGColor.textMuted)
            if isMultiline {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(WGColor.textMuted)
                            .font(.system(size: 15))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $text)
                        .foregroundColor(WGColor.textPrimary)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .padding(12)
                .background(WGColor.card)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1))
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(WGColor.textPrimary)
                    .padding(12)
                    .background(WGColor.card)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1))
            }
        }
    }
}

// MARK: - WGButton
struct WGButton: View {
    enum Style { case primary, secondary, outline, danger }

    let title: String
    let icon: String
    let style: Style
    let action: () -> Void

    init(title: String, icon: String = "", style: Style = .primary, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.style = style; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if !icon.isEmpty { Image(systemName: icon).font(.system(size: 15)) }
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(bgColor)
            .cornerRadius(12)
            .overlay(border)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    var textColor: Color {
        switch style {
        case .primary: return WGColor.bg
        case .secondary: return WGColor.textPrimary
        case .outline: return WGColor.yellow
        case .danger: return .white
        }
    }

    var bgColor: Color {
        switch style {
        case .primary: return WGColor.yellow
        case .secondary: return WGColor.card
        case .outline: return .clear
        case .danger: return WGColor.danger
        }
    }

    @ViewBuilder var border: some View {
        switch style {
        case .outline:   RoundedRectangle(cornerRadius: 12).stroke(WGColor.yellow, lineWidth: 1.5)
        case .secondary: RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1)
        default:         EmptyView()
        }
    }
}

// MARK: - StatusBadge
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - FilterChip
struct FilterChip: View {
    let label: String
    var color: Color = WGColor.yellow
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? WGColor.bg : WGColor.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : WGColor.card)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? color : WGColor.divider, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - InfoChip
struct InfoChip: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(WGColor.textMuted)
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(WGColor.textPrimary)
            if !label.isEmpty {
                Text(label).font(.system(size: 12)).foregroundColor(WGColor.textMuted)
            }
        }
    }
}

// MARK: - DetailRow
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(WGColor.textMuted)
            Spacer()
            Text(value).font(.system(size: 14, weight: .medium)).foregroundColor(WGColor.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - ImagePickerView
import PhotosUI
import AVFoundation

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.presentationMode) var dismiss

    @State private var showSettingsAlert = false

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIViewController {
        let container = UIViewController()

        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authStatus {
        case .authorized:
            presentPicker(on: container, useCamera: true, context: context)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        presentPicker(on: container, useCamera: true, context: context)
                    } else {
                        presentPicker(on: container, useCamera: false, context: context)
                    }
                }
            }

        case .denied, .restricted:
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Camera Access Required",
                    message: "Wall Guard needs camera access to photograph wall defects. Please enable it in Settings.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    dismiss.wrappedValue.dismiss()
                })
                alert.addAction(UIAlertAction(title: "Use Photo Library", style: .default) { _ in
                    presentPicker(on: container, useCamera: false, context: context)
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    dismiss.wrappedValue.dismiss()
                })
                container.present(alert, animated: true)
            }

        @unknown default:
            presentPicker(on: container, useCamera: false, context: context)
        }

        return container
    }

    private func presentPicker(on container: UIViewController,
                                useCamera: Bool,
                                context: Context) {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        picker.sourceType = (useCamera && cameraAvailable) ? .camera : .photoLibrary
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen

        // Small delay to ensure the container view is in the hierarchy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            container.present(picker, animated: true)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    // MARK: - Coordinator
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let img = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.imageData = img.jpegData(compressionQuality: 0.75)
            }
            parent.dismiss.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss.wrappedValue.dismiss()
        }
    }
}
