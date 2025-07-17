import Foundation

// Service simple de cache hors ligne avec UserDefaults
class OfflineCacheService {
    static let shared = OfflineCacheService()
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Cache des médicaments
    
    func cacheMedicines(_ medicines: [Medicine]) {
        do {
            let data = try encoder.encode(medicines)
            userDefaults.set(data, forKey: CacheKeys.medicines)
            userDefaults.set(Date(), forKey: CacheKeys.medicinesTimestamp)
            print("✅ \(medicines.count) médicaments mis en cache")
        } catch {
            print("❌ Erreur cache médicaments: \(error.localizedDescription)")
        }
    }
    
    func getCachedMedicines() -> [Medicine] {
        guard let data = userDefaults.data(forKey: CacheKeys.medicines),
              isCacheValid(for: CacheKeys.medicinesTimestamp) else {
            return []
        }
        
        do {
            let medicines = try decoder.decode([Medicine].self, from: data)
            print("✅ \(medicines.count) médicaments récupérés du cache")
            return medicines
        } catch {
            print("❌ Erreur lecture cache médicaments: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Cache des rayons
    
    func cacheAisles(_ aisles: [Aisle]) {
        do {
            let data = try encoder.encode(aisles)
            userDefaults.set(data, forKey: CacheKeys.aisles)
            userDefaults.set(Date(), forKey: CacheKeys.aislesTimestamp)
            print("✅ \(aisles.count) rayons mis en cache")
        } catch {
            print("❌ Erreur cache rayons: \(error.localizedDescription)")
        }
    }
    
    func getCachedAisles() -> [Aisle] {
        guard let data = userDefaults.data(forKey: CacheKeys.aisles),
              isCacheValid(for: CacheKeys.aislesTimestamp) else {
            return []
        }
        
        do {
            let aisles = try decoder.decode([Aisle].self, from: data)
            print("✅ \(aisles.count) rayons récupérés du cache")
            return aisles
        } catch {
            print("❌ Erreur lecture cache rayons: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Cache de l'historique
    
    func cacheHistory(_ history: [HistoryEntry]) {
        do {
            let data = try encoder.encode(history)
            userDefaults.set(data, forKey: CacheKeys.history)
            userDefaults.set(Date(), forKey: CacheKeys.historyTimestamp)
            print("✅ \(history.count) entrées d'historique mises en cache")
        } catch {
            print("❌ Erreur cache historique: \(error.localizedDescription)")
        }
    }
    
    func getCachedHistory() -> [HistoryEntry] {
        guard let data = userDefaults.data(forKey: CacheKeys.history),
              isCacheValid(for: CacheKeys.historyTimestamp) else {
            return []
        }
        
        do {
            let history = try decoder.decode([HistoryEntry].self, from: data)
            print("✅ \(history.count) entrées d'historique récupérées du cache")
            return history
        } catch {
            print("❌ Erreur lecture cache historique: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Gestion de la validité du cache
    
    private func isCacheValid(for timestampKey: String, maxAge: TimeInterval = 300) -> Bool {
        guard let timestamp = userDefaults.object(forKey: timestampKey) as? Date else {
            return false
        }
        
        let age = Date().timeIntervalSince(timestamp)
        let isValid = age < maxAge
        
        if !isValid {
            print("⚠️ Cache expiré pour \(timestampKey) (âge: \(Int(age))s)")
        }
        
        return isValid
    }
    
    // MARK: - État de connexion
    
    var isOffline: Bool {
        // Simple vérification basique - peut être améliorée avec Network framework
        return !userDefaults.bool(forKey: CacheKeys.isOnline)
    }
    
    func setOnlineStatus(_ isOnline: Bool) {
        userDefaults.set(isOnline, forKey: CacheKeys.isOnline)
    }
    
    // MARK: - Nettoyage du cache
    
    func clearCache() {
        let keysToRemove = [
            CacheKeys.medicines,
            CacheKeys.medicinesTimestamp,
            CacheKeys.aisles,
            CacheKeys.aislesTimestamp,
            CacheKeys.history,
            CacheKeys.historyTimestamp
        ]
        
        keysToRemove.forEach { userDefaults.removeObject(forKey: $0) }
        print("✅ Cache vidé complètement")
    }
    
    func clearExpiredCache() {
        if !isCacheValid(for: CacheKeys.medicinesTimestamp) {
            userDefaults.removeObject(forKey: CacheKeys.medicines)
            userDefaults.removeObject(forKey: CacheKeys.medicinesTimestamp)
        }
        
        if !isCacheValid(for: CacheKeys.aislesTimestamp) {
            userDefaults.removeObject(forKey: CacheKeys.aisles)
            userDefaults.removeObject(forKey: CacheKeys.aislesTimestamp)
        }
        
        if !isCacheValid(for: CacheKeys.historyTimestamp) {
            userDefaults.removeObject(forKey: CacheKeys.history)
            userDefaults.removeObject(forKey: CacheKeys.historyTimestamp)
        }
        
        print("✅ Cache expiré nettoyé")
    }
    
    // MARK: - Statistiques du cache
    
    func getCacheInfo() -> CacheInfo {
        let medicinesCount = getCachedMedicines().count
        let aislesCount = getCachedAisles().count
        let historyCount = getCachedHistory().count
        
        let medicinesAge = getCacheAge(for: CacheKeys.medicinesTimestamp)
        let aislesAge = getCacheAge(for: CacheKeys.aislesTimestamp)
        let historyAge = getCacheAge(for: CacheKeys.historyTimestamp)
        
        return CacheInfo(
            medicinesCount: medicinesCount,
            aislesCount: aislesCount,
            historyCount: historyCount,
            medicinesAge: medicinesAge,
            aislesAge: aislesAge,
            historyAge: historyAge,
            isOffline: isOffline
        )
    }
    
    private func getCacheAge(for timestampKey: String) -> TimeInterval? {
        guard let timestamp = userDefaults.object(forKey: timestampKey) as? Date else {
            return nil
        }
        return Date().timeIntervalSince(timestamp)
    }
}

// MARK: - Clés de cache

private struct CacheKeys {
    static let medicines = "cached_medicines"
    static let medicinesTimestamp = "cached_medicines_timestamp"
    static let aisles = "cached_aisles"
    static let aislesTimestamp = "cached_aisles_timestamp"
    static let history = "cached_history"
    static let historyTimestamp = "cached_history_timestamp"
    static let isOnline = "is_online_status"
}

// MARK: - Informations du cache

struct CacheInfo {
    let medicinesCount: Int
    let aislesCount: Int
    let historyCount: Int
    let medicinesAge: TimeInterval?
    let aislesAge: TimeInterval?
    let historyAge: TimeInterval?
    let isOffline: Bool
    
    var totalItemsCount: Int {
        medicinesCount + aislesCount + historyCount
    }
    
    var hasData: Bool {
        totalItemsCount > 0
    }
}
