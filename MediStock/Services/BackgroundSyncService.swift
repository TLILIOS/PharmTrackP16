import Foundation
import UIKit

// Service simple de synchronisation en arrière-plan
class BackgroundSyncService {
    static let shared = BackgroundSyncService()
    
    private let offlineCache = OfflineCacheService.shared
    private let queryOptimization = QueryOptimizationService.shared
    private var syncTimer: Timer?
    private var isAppInBackground = false
    
    private init() {
        setupBackgroundNotifications()
    }
    
    // MARK: - Configuration
    
    private func setupBackgroundNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Cycle de vie de l'application
    
    @objc private func appDidEnterBackground() {
        isAppInBackground = true
        startBackgroundSync()
        print("📱 App en arrière-plan - Sync démarrée")
    }
    
    @objc private func appWillEnterForeground() {
        isAppInBackground = false
        stopBackgroundSync()
        print("📱 App au premier plan - Sync arrêtée")
    }
    
    @objc private func appDidBecomeActive() {
        // Synchronisation immédiate quand l'app devient active
        Task {
            await performQuickSync()
        }
    }
    
    // MARK: - Synchronisation en arrière-plan
    
    private func startBackgroundSync() {
        stopBackgroundSync() // Arrêter le précédent timer
        
        // Timer toutes les 30 secondes en arrière-plan
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.performBackgroundSync()
            }
        }
    }
    
    private func stopBackgroundSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    // MARK: - Types de synchronisation
    
    // Synchronisation rapide (données critiques uniquement)
    func performQuickSync() async {
        print("⚡ Synchronisation rapide...")
        
        // Synchroniser seulement les données critiques
        await syncCriticalData()
        
        // Notification de succès
        NotificationCenter.default.post(
            name: Notification.Name("QuickSyncCompleted"),
            object: nil
        )
        
        print("✅ Synchronisation rapide terminée")
    }
    
    // Synchronisation complète 
    func performFullSync() async {
        print("🔄 Synchronisation complète...")
        
        await syncAllData()
        
        NotificationCenter.default.post(
            name: Notification.Name("FullSyncCompleted"),
            object: nil
        )
        
        print("✅ Synchronisation complète terminée")
    }
    
    // Synchronisation en arrière-plan (limitée)
    private func performBackgroundSync() async {
        guard isAppInBackground else { return }
        
        print("🌙 Synchronisation arrière-plan...")
        
        // En arrière-plan, synchroniser seulement les données essentielles
        await syncEssentialData()
        print("✅ Synchronisation arrière-plan terminée")
    }
    
    // MARK: - Synchronisation des données
    
    private func syncCriticalData() async {
        // Synchroniser uniquement les médicaments avec stock critique
        do {
            let medicines = try await queryOptimization.getOptimizedMedicines(
                repository: FirebaseMedicineRepository()
            )
            
            let criticalMedicines = medicines.filter { $0.stockStatus == .critical }
            
            if !criticalMedicines.isEmpty {
                offlineCache.cacheMedicines(criticalMedicines)
                print("🔴 \(criticalMedicines.count) médicaments critiques synchronisés")
            }
        } catch {
            print("❌ Erreur sync données critiques: \(error.localizedDescription)")
        }
    }
    
    private func syncEssentialData() async {
        do {
            // Synchroniser médicaments (avec optimisation)
            let medicines = try await queryOptimization.getOptimizedMedicines(
                repository: FirebaseMedicineRepository()
            )
            offlineCache.cacheMedicines(medicines)
            
            print("💊 \(medicines.count) médicaments synchronisés")
        } catch {
            print("❌ Erreur sync données essentielles: \(error.localizedDescription)")
        }
    }
    
    private func syncAllData() async {
        do {
            // 1. Synchroniser les médicaments
            let medicines = try await queryOptimization.getOptimizedMedicines(
                repository: FirebaseMedicineRepository()
            )
            offlineCache.cacheMedicines(medicines)
            
            // 2. Synchroniser les rayons
            let aisles = try await queryOptimization.getOptimizedAisles(
                repository: FirebaseAisleRepository()
            )
            offlineCache.cacheAisles(aisles)
            
            // 3. Synchroniser l'historique récent
            let history = try await queryOptimization.getOptimizedHistory(
                repository: FirebaseHistoryRepository(),
                limit: 100
            )
            offlineCache.cacheHistory(history)
            
            print("📊 Synchronisation complète: \(medicines.count) médicaments, \(aisles.count) rayons, \(history.count) historiques")
            
        } catch {
            print("❌ Erreur sync toutes données: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Contrôle manuel
    
    func forceSyncNow() async {
        await performFullSync()
    }
    
    func enableAutoSync(_ enabled: Bool) {
        if enabled && !isAppInBackground {
            // Redémarrer la sync si l'app est active
            Task {
                await performQuickSync()
            }
        } else if !enabled {
            stopBackgroundSync()
        }
    }
    
    // MARK: - État de la synchronisation
    
    func getSyncStatus() -> SyncStatus {
        let cacheInfo = offlineCache.getCacheInfo()
        let optimizationStats = queryOptimization.getOptimizationStats()
        
        return SyncStatus(
            isActive: syncTimer != nil,
            isInBackground: isAppInBackground,
            lastSyncTime: getLastSyncTime(),
            cacheInfo: cacheInfo,
            optimizationStats: optimizationStats
        )
    }
    
    private func getLastSyncTime() -> Date? {
        return UserDefaults.standard.object(forKey: "last_sync_time") as? Date
    }
    
    private func updateLastSyncTime() {
        UserDefaults.standard.set(Date(), forKey: "last_sync_time")
    }
    
    // MARK: - Nettoyage
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopBackgroundSync()
    }
}

// MARK: - État de synchronisation

struct SyncStatus {
    let isActive: Bool
    let isInBackground: Bool
    let lastSyncTime: Date?
    let cacheInfo: CacheInfo
    let optimizationStats: OptimizationStats
    
    var lastSyncDescription: String {
        guard let lastSync = lastSyncTime else {
            return "Jamais synchronisé"
        }
        
        let interval = Date().timeIntervalSince(lastSync)
        
        if interval < 60 {
            return "Il y a \(Int(interval))s"
        } else if interval < 3600 {
            return "Il y a \(Int(interval / 60))min"
        } else {
            return "Il y a \(Int(interval / 3600))h"
        }
    }
    
    var statusDescription: String {
        if isActive {
            return isInBackground ? "Sync en arrière-plan" : "Sync active"
        } else {
            return "Sync inactive"
        }
    }
}