import Foundation

protocol Strongroom {
    func seal(_ archive: BastionArchive)
    func brandRoute(url: String, mode: String)
    func raisePrimedFlag()
    func unseal() -> BastionArchive
}

final class JSONStrongroom: Strongroom {
    
    private let fm = FileManager.default
    private let dataDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dataDir = docs.appendingPathComponent("WallBastion", isDirectory: true)
        if !fm.fileExists(atPath: dataDir.path) {
            try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
        }
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: BastionIdiom.suiteBastion) ?? .standard
    }
    
    private var archiveURL: URL {
        dataDir.appendingPathComponent(BastionIdiom.bastionFile)
    }
    
    func seal(_ archive: BastionArchive) {
        let muffled = MuffledBastion(
            banners: muffleDict(archive.banners),
            scouts: muffleDict(archive.scouts),
            routeURL: archive.routeURL,
            routeMode: archive.routeMode,
            unbreached: archive.unbreached,
            consentForged: archive.consentForged,
            consentBarred: archive.consentBarred,
            consentStampedAt: archive.consentStampedAt
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        do {
            let data = try encoder.encode(muffled)
            try data.write(to: archiveURL, options: .atomic)
        } catch {
            print("\(BastionIdiom.logShield) Strongroom seal failed: \(error)")
        }
        
        suiteStore.set(archive.consentForged, forKey: "wg_consent_forged")
        suiteStore.set(archive.consentBarred, forKey: "wg_consent_barred")
        if let date = archive.consentStampedAt {
            suiteStore.set(date.timeIntervalSince1970, forKey: "wg_consent_stamped_at")
        }
        homeStore.set(archive.consentForged, forKey: "wg_consent_forged")
        homeStore.set(archive.consentBarred, forKey: "wg_consent_barred")
        if let date = archive.consentStampedAt {
            homeStore.set(date.timeIntervalSince1970, forKey: "wg_consent_stamped_at")
        }
    }
    
    func brandRoute(url: String, mode: String) {
        suiteStore.set(url, forKey: BastionDictKey.routeURL)
        homeStore.set(url, forKey: BastionDictKey.routeURL)
        suiteStore.set(mode, forKey: BastionDictKey.routeMode)
    }
    
    func raisePrimedFlag() {
        suiteStore.set(true, forKey: BastionDictKey.primed)
        homeStore.set(true, forKey: BastionDictKey.primed)
    }
    
    func unseal() -> BastionArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        if fm.fileExists(atPath: archiveURL.path),
           let data = try? Data(contentsOf: archiveURL),
           let muffled = try? decoder.decode(MuffledBastion.self, from: data) {
            return BastionArchive(
                banners: unmuffleDict(muffled.banners),
                scouts: unmuffleDict(muffled.scouts),
                routeURL: muffled.routeURL,
                routeMode: muffled.routeMode,
                unbreached: muffled.unbreached,
                consentForged: muffled.consentForged,
                consentBarred: muffled.consentBarred,
                consentStampedAt: muffled.consentStampedAt
            )
        }
        
        return restoreFromDefaults()
    }
    
    private func restoreFromDefaults() -> BastionArchive {
        let routeURL = homeStore.string(forKey: BastionDictKey.routeURL)
            ?? suiteStore.string(forKey: BastionDictKey.routeURL)
        let routeMode = suiteStore.string(forKey: BastionDictKey.routeMode)
        let primed = suiteStore.bool(forKey: BastionDictKey.primed)
        
        let forged = suiteStore.bool(forKey: "wg_consent_forged")
            || homeStore.bool(forKey: "wg_consent_forged")
        let barred = suiteStore.bool(forKey: "wg_consent_barred")
            || homeStore.bool(forKey: "wg_consent_barred")
        let stampedTs = suiteStore.double(forKey: "wg_consent_stamped_at")
        let stampedAt: Date? = stampedTs > 0 ? Date(timeIntervalSince1970: stampedTs) : nil
        
        return BastionArchive(
            banners: [:], scouts: [:],
            routeURL: routeURL, routeMode: routeMode,
            unbreached: !primed,
            consentForged: forged, consentBarred: barred, consentStampedAt: stampedAt
        )
    }
    
    private func muffleDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = muffle(v) }
        return result
    }
    
    private func unmuffleDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = unmuffle(v) ?? v }
        return result
    }
    
    private func muffle(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "+", with: "@")
            .replacingOccurrences(of: "/", with: "#")
    }
    
    private func unmuffle(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "@", with: "+")
            .replacingOccurrences(of: "#", with: "/")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct MuffledBastion: Codable {
    let banners: [String: String]
    let scouts: [String: String]
    let routeURL: String?
    let routeMode: String?
    let unbreached: Bool
    let consentForged: Bool
    let consentBarred: Bool
    let consentStampedAt: Date?
}
