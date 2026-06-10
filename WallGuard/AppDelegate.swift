import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private lazy var firebaseSub = FirebaseSubdelegate()
    private lazy var messagingSub = MessagingSubdelegate(host: self)
    private lazy var notificationsSub = NotificationsSubdelegate(host: self)
    private lazy var appsFlyerSub = AppsFlyerSubdelegate(host: self)
    private lazy var fusionSub = FusionSubdelegate()
    private lazy var pushReaperSub = PushReaperSubdelegate()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        firebaseSub.boot()
        messagingSub.boot()
        notificationsSub.boot()
        appsFlyerSub.boot()
        fusionSub.boot()
        pushReaperSub.boot()
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushReaperSub.reap(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        appsFlyerSub.startTracking()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: BastionDictKey.fcm)
            UserDefaults.standard.set(t, forKey: BastionDictKey.push)
            UserDefaults(suiteName: BastionIdiom.suiteBastion)?.set(t, forKey: "shared_fcm")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        pushReaperSub.reap(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        pushReaperSub.reap(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushReaperSub.reap(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        fusionSub.takeBanners(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        fusionSub.takeBanners([
            "error": true,
            "error_desc": error.localizedDescription
        ])
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        fusionSub.takeScouts(link.clickEvent)
    }
}

final class FirebaseSubdelegate {
    func boot() {
        FirebaseApp.configure()
    }
}

final class MessagingSubdelegate {
    private weak var host: MessagingDelegate?
    
    init(host: MessagingDelegate) {
        self.host = host
    }
    
    func boot() {
        Messaging.messaging().delegate = host
        UIApplication.shared.registerForRemoteNotifications()
    }
}

final class NotificationsSubdelegate {
    private weak var host: UNUserNotificationCenterDelegate?
    
    init(host: UNUserNotificationCenterDelegate) {
        self.host = host
    }
    
    func boot() {
        UNUserNotificationCenter.current().delegate = host
    }
}

final class AppsFlyerSubdelegate {
    private weak var attDelegate: AppsFlyerLibDelegate?
    private weak var linkDelegate: DeepLinkDelegate?
    
    init(host: AppDelegate) {
        self.attDelegate = host
        self.linkDelegate = host
    }
    
    func boot() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = BastionIdiom.trackerKey
        sdk.appleAppID = BastionIdiom.appCode
        sdk.delegate = attDelegate
        sdk.deepLinkDelegate = linkDelegate
        sdk.isDebug = false
    }
    
    func startTracking() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

final class FusionSubdelegate {
    
    private var bannersBuffer: [AnyHashable: Any] = [:]
    private var scoutsBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func boot() {}
    
    func takeBanners(_ data: [AnyHashable: Any]) {
        bannersBuffer = data
        scheduleFuse()
        if !scoutsBuffer.isEmpty { performFuse() }
    }
    
    func takeScouts(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: BastionDictKey.primed) else { return }
        scoutsBuffer = data
        NotificationCenter.default.post(
            name: .deeplinksParapet,
            object: nil,
            userInfo: ["deeplinksData": data]
        )
        fuseTimer?.invalidate()
        if !bannersBuffer.isEmpty { performFuse() }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = bannersBuffer
        for (k, v) in scoutsBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(
                name: .attributionParapet,
                object: nil,
                userInfo: ["conversionData": combined]
            )
        }
    }
}

final class PushReaperSubdelegate {
    
    func boot() {}
    
    func reap(_ payload: [AnyHashable: Any]) {
        guard let url = extract(payload) else { return }
        UserDefaults.standard.set(url, forKey: BastionDictKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(
                name: .pushArrow,
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extract(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
}
