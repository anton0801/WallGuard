import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol Herald {
    func dispatch(missive: [String: Any]) async throws -> String
}

final class HTTPHerald: Herald {
    
    private let session: URLSession
    private let regroup: [Double] = [88.0, 176.0, 352.0]
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""

    func dispatch(missive: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: BastionIdiom.backendRampart) else {
            throw BastionTrip.scrollTorn(at: "herald.url")
        }
        
        var body: [String: Any] = missive
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(BastionIdiom.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: BastionDictKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastTrip: Error?
        
        for (idx, pause) in regroup.enumerated() {
            do {
                return try await runVolley(request)
            } catch let trip as BastionTrip {
                if trip.isSealed {
                    throw trip
                }
                if case .warbandBeating(let coolDown) = trip {
                    try await Task.sleep(nanoseconds: UInt64(coolDown * 1_000_000_000))
                    continue
                }
                lastTrip = trip
                if idx < regroup.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            } catch {
                lastTrip = error
                if idx < regroup.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            }
        }
        
        if let lastTrip = lastTrip {
            throw lastTrip
        }
        throw BastionTrip.messengerLost(stage: "herald.exhausted")
    }
    
    private func runVolley(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw BastionTrip.messengerLost(stage: "herald.response")
        }
        
        if http.statusCode == 404 {
            throw BastionTrip.drawbridgeUp(httpCode: 404)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BastionTrip.scrollTorn(at: "herald.json")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw BastionTrip.scrollTorn(at: "herald.missingOk")
        }
        
        if !ok {
            throw BastionTrip.rampartSealed(reason: "okFalse")
        }
        
        guard let url = json["url"] as? String, !url.isEmpty else {
            throw BastionTrip.scrollTorn(at: "herald.missingURL")
        }
        
        return url
    }
}
