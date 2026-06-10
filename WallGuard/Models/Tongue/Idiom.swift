import Foundation

enum BastionIdiom {
    static let appCode = "6775932880"
    static let trackerKey = "2q9Um6tpUFjPRpURHZ6HES"
    static let suiteBastion = "group.wallguard.bastion"
    static let cookieBattlements = "wallguard_battlements"
    static let backendRampart = "https://wallguarrd.com/config.php"
    static let logShield = "🛡 [WallGuard]"
    
    static let bastionFile = "wg_bastion_archive.json"
}

enum BastionDictKey {
    static let routeURL = "wg_route_url"
    static let routeMode = "wg_route_mode"
    static let primed = "wg_primed"
    
    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}

extension Notification.Name {
    static let attributionParapet = Notification.Name("ConversionDataReceived")
    static let deeplinksParapet = Notification.Name("deeplink_values")
    static let pushArrow = Notification.Name("LoadTempURL")
}
