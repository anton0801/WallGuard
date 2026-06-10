import SwiftUI
import WebKit

// MARK: - DefectDetailView
struct DefectDetailView: View {
    @EnvironmentObject var appState: AppState
    let defect: WGDefect
    @State private var resolved:         Bool
    @State private var showAddMeasure  = false
    @State private var mWidth:   Double = 0
    @State private var mLength:  Double = 0
    @State private var mNotes           = ""

    init(defect: WGDefect) {
        self.defect = defect
        _resolved = State(initialValue: defect.isResolved)
    }

    var body: some View {
        ZStack {
            WGColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Photo with marker overlay
                    ZStack {
                        if let data = defect.photoData, let ui = UIImage(data: data) {
                            Image(uiImage: ui).resizable().scaledToFill()
                                .frame(maxWidth: .infinity).frame(height: 220).clipped().cornerRadius(16)
                        } else {
                            RoundedRectangle(cornerRadius: 16).fill(WGColor.card).frame(height: 120)
                                .overlay(Image(systemName: "photo").foregroundColor(WGColor.textMuted).font(.system(size: 30)))
                        }
                        GeometryReader { geo in
                            Circle()
                                .fill(Color(hex: defect.riskLevel.color).opacity(0.8))
                                .frame(width: 22, height: 22)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .position(x: geo.size.width * defect.markerX, y: geo.size.height * defect.markerY)
                        }
                    }

                    // Risk badge
                    HStack {
                        Image(systemName: defect.riskLevel.icon).foregroundColor(Color(hex: defect.riskLevel.color))
                        Text(defect.riskLevel.rawValue)
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: defect.riskLevel.color))
                        Spacer()
                        Text(defect.category.rawValue).font(.system(size: 13)).foregroundColor(WGColor.textMuted)
                    }
                    .padding(12).background(Color(hex: defect.riskLevel.color).opacity(0.1)).cornerRadius(12)

                    // Details
                    VStack(spacing: 0) {
                        DetailRow(label: "Title",   value: defect.title)
                        Divider().background(WGColor.divider)
                        DetailRow(label: "Width",   value: "\(String(format: "%.2f", defect.widthMm)) mm")
                        Divider().background(WGColor.divider)
                        DetailRow(label: "Length",  value: "\(String(format: "%.2f", defect.lengthMm)) mm")
                        Divider().background(WGColor.divider)
                        DetailRow(label: "Created", value: defect.createdAt.formatted(date: .abbreviated, time: .omitted))
                    }
                    .background(WGColor.card).cornerRadius(14)

                    // Resolved toggle
                    Toggle(isOn: $resolved) {
                        Label("Mark as Resolved", systemImage: "checkmark.circle.fill")
                            .foregroundColor(resolved ? WGColor.success : WGColor.textSecondary)
                    }
                    .toggleStyle(.switch).tint(WGColor.success)
                    .padding(14).background(WGColor.card).cornerRadius(14)
                    .onChange(of: resolved) { val in
                        var updated = defect; updated.isResolved = val
                        appState.updateDefect(updated)
                    }

                    // Measurement history
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Measurement History")
                                .font(.system(size: 15, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                            Spacer()
                            Button { showAddMeasure = true } label: {
                                Image(systemName: "plus.circle.fill").foregroundColor(WGColor.yellow).font(.system(size: 20))
                            }
                        }
                        if defect.measurements.isEmpty {
                            Text("No measurements yet. Add one to track growth.")
                                .font(.system(size: 13)).foregroundColor(WGColor.textMuted)
                        } else {
                            ForEach(defect.measurements) { m in
                                HStack {
                                    Text(m.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(size: 13)).foregroundColor(WGColor.textMuted)
                                    Spacer()
                                    Text("\(m.widthMm, specifier: "%.1f") × \(m.lengthMm, specifier: "%.1f") mm")
                                        .font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textPrimary)
                                }
                                .padding(10).background(WGColor.bgSoft).cornerRadius(10)
                            }
                        }
                    }
                    .padding(14).background(WGColor.card).cornerRadius(14)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 18).padding(.top, 16)
            }
        }
        .navigationTitle(defect.title).navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddMeasure) {
            AddMeasurementSheet(defect: defect, width: $mWidth, length: $mLength, notes: $mNotes) {
                var updated = defect
                updated.measurements.append(WGDefect.Measurement(widthMm: mWidth, lengthMm: mLength, notes: mNotes))
                appState.updateDefect(updated)
                showAddMeasure = false
            }
        }
    }
}


final class ShowpieceCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = BastionIdiom.cookieBattlements
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}


// MARK: - AddMeasurementSheet
struct AddMeasurementSheet: View {
    @Environment(\.presentationMode) var dismiss
    let defect: WGDefect
    @Binding var width:  Double
    @Binding var length: Double
    @Binding var notes:  String
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Measurement for \(defect.title)")
                        .font(.system(size: 14)).foregroundColor(WGColor.textMuted).multilineTextAlignment(.center)
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Width mm").font(.system(size: 12)).foregroundColor(WGColor.textMuted)
                            TextField("0", value: $width, format: .number)
                                .foregroundColor(WGColor.textPrimary).keyboardType(.decimalPad)
                                .padding(12).background(WGColor.card).cornerRadius(12)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Length mm").font(.system(size: 12)).foregroundColor(WGColor.textMuted)
                            TextField("0", value: $length, format: .number)
                                .foregroundColor(WGColor.textPrimary).keyboardType(.decimalPad)
                                .padding(12).background(WGColor.card).cornerRadius(12)
                        }
                    }
                    WGFormField(title: "Notes", placeholder: "Optional notes...", text: $notes)
                    Button(action: onSave) {
                        Text("Save Measurement")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(WGColor.bg)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(WGColor.yellow).cornerRadius(14)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18).padding(.top, 20)
            }
            .navigationTitle("New Measurement").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(WGColor.textMuted)
                }
            }
        }
        .colorScheme(.dark)
    }
}

extension ShowpieceCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - AddRecordView
struct AddRecordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    var preselectedRoomId: UUID? = nil

    @State private var title            = ""
    @State private var selectedRoomId:  UUID? = nil
    @State private var date             = Date()
    @State private var category:        DefectRecord.RecordCategory = .inspection
    @State private var value            = ""
    @State private var comment          = ""
    @State private var photoData:       Data? = nil
    @State private var showPhotoPicker  = false
    @State private var saved            = false
    @State private var showVal          = false

    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                WGColor.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        WGFormField(title: "Title", placeholder: "Record title", text: $title)

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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact).colorScheme(.dark)
                                .padding(12).background(WGColor.card).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(DefectRecord.RecordCategory.allCases, id: \.self) { cat in
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

                        WGFormField(title: "Value", placeholder: "e.g. 2.3mm, checked, repaired", text: $value)
                        WGFormField(title: "Comment", placeholder: "Additional notes...", text: $comment, isMultiline: true)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            Button { showPhotoPicker = true } label: {
                                if let data = photoData, let ui = UIImage(data: data) {
                                    Image(uiImage: ui).resizable().scaledToFill()
                                        .frame(maxWidth: .infinity).frame(height: 120).clipped().cornerRadius(12)
                                } else {
                                    RoundedRectangle(cornerRadius: 12).fill(WGColor.card).frame(height: 80)
                                        .overlay(Label("Add Photo", systemImage: "camera").foregroundColor(WGColor.textMuted))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1))
                                }
                            }
                        }

                        if showVal && !isValid {
                            Text("Title is required").font(.system(size: 13)).foregroundColor(WGColor.danger)
                        }

                        HStack(spacing: 12) {
                            Button {
                                guard isValid else { showVal = true; return }
                                saveRecord(); saved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { dismiss.wrappedValue.dismiss() }
                            } label: {
                                Text(saved ? "Saved!" : "Save")
                                    .font(.system(size: 15, weight: .semibold)).foregroundColor(WGColor.bg)
                                    .frame(maxWidth: .infinity).frame(height: 50)
                                    .background(saved ? WGColor.success : WGColor.yellow).cornerRadius(14)
                            }
                            Button {
                                guard isValid else { showVal = true; return }
                                saveRecord()
                                title = ""; value = ""; comment = ""; photoData = nil; showVal = false
                            } label: {
                                Text("Add Another")
                                    .font(.system(size: 15, weight: .semibold)).foregroundColor(WGColor.textPrimary)
                                    .frame(maxWidth: .infinity).frame(height: 50)
                                    .background(WGColor.card).cornerRadius(14)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(WGColor.divider, lineWidth: 1))
                            }
                        }
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 18).padding(.top, 8)
                }
            }
            .navigationTitle("Add Record").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(WGColor.textMuted)
                }
            }
            .sheet(isPresented: $showPhotoPicker) { ImagePickerView(imageData: $photoData) }
            .onAppear { if let id = preselectedRoomId { selectedRoomId = id } }
        }
        .colorScheme(.dark)
    }

    private func saveRecord() {
        let r = DefectRecord(title: title.trimmingCharacters(in: .whitespaces),
                             roomId: selectedRoomId, date: date,
                             category: category, value: value,
                             comment: comment, photoData: photoData)
        appState.addRecord(r)
    }
}

extension ShowpieceCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}

// MARK: - RecordDetailView
struct RecordDetailView: View {
    @EnvironmentObject var appState: AppState
    let record: DefectRecord
    @State private var showCreateTask = false

    var room: WGRoom? { record.roomId.flatMap { id in appState.rooms.first { $0.id == id } } }

    var body: some View {
        ZStack {
            WGColor.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if let data = record.photoData, let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFill()
                            .frame(maxWidth: .infinity).frame(height: 200).clipped().cornerRadius(16)
                    }
                    VStack(spacing: 0) {
                        DetailRow(label: "Title",    value: record.title)
                        Divider().background(WGColor.divider)
                        DetailRow(label: "Room",     value: room?.name ?? "—")
                        Divider().background(WGColor.divider)
                        DetailRow(label: "Date",     value: record.date.formatted(date: .long, time: .omitted))
                        Divider().background(WGColor.divider)
                        DetailRow(label: "Category", value: record.category.rawValue)
                        Divider().background(WGColor.divider)
                        DetailRow(label: "Value",    value: record.value.isEmpty ? "—" : record.value)
                        Divider().background(WGColor.divider)
                        DetailRow(label: "Status",   value: record.status.rawValue)
                    }
                    .background(WGColor.card).cornerRadius(16)

                    if !record.comment.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(.system(size: 13, weight: .medium)).foregroundColor(WGColor.textMuted)
                            Text(record.comment).font(.system(size: 14)).foregroundColor(WGColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14).background(WGColor.card).cornerRadius(14)
                    }

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button {
                                var copy = record; copy.id = UUID(); copy.title = "Copy of \(record.title)"
                                appState.addRecord(copy)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                                    .font(.system(size: 14, weight: .medium)).foregroundColor(WGColor.textPrimary)
                                    .frame(maxWidth: .infinity).frame(height: 46)
                                    .background(WGColor.card).cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.divider, lineWidth: 1))
                            }
                            Button { showCreateTask = true } label: {
                                Label("Create Task", systemImage: "checkmark.circle")
                                    .font(.system(size: 14, weight: .medium)).foregroundColor(WGColor.orange)
                                    .frame(maxWidth: .infinity).frame(height: 46)
                                    .background(WGColor.orange.opacity(0.1)).cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.orange.opacity(0.3), lineWidth: 1))
                            }
                        }
                        Button(role: .destructive) { appState.deleteRecord(record) } label: {
                            Label("Delete Record", systemImage: "trash")
                                .font(.system(size: 14, weight: .medium)).foregroundColor(WGColor.danger)
                                .frame(maxWidth: .infinity).frame(height: 46)
                                .background(WGColor.danger.opacity(0.1)).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(WGColor.danger.opacity(0.3), lineWidth: 1))
                        }
                    }
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 18).padding(.top, 16)
            }
        }
        .navigationTitle("Record Detail").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateTask) {
            AddTaskView(defaultTitle: "Follow-up: \(record.title)")
        }
    }
}

extension ShowpieceCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}
