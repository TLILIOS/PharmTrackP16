import Foundation
import Combine

// Service simple d'optimisation des requêtes Firebase
class QueryOptimizationService {
    static let shared = QueryOptimizationService()
    
    private var queryCache: [String: CachedQuery] = [:]
    private var pendingQueries: [String: AnyCancellable] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Optimisation des requêtes
    
    // Exécuter une requête avec cache et dédoublonnage
    func executeOptimizedQuery<T>(
        key: String,
        query: @escaping () async throws -> T
    ) async throws -> T {
        
        // 1. Vérifier le cache
        if let cachedResult = getCachedResult(key: key) as? T {
            print("✅ Résultat récupéré du cache pour: \(key)")
            return cachedResult
        }
        
        // 2. Vérifier si une requête similaire est en cours
        if pendingQueries[key] != nil {
            print("⏳ Requête en cours pour: \(key), en attente...")
            // Attendre un délai court puis réessayer
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            return try await executeOptimizedQuery(key: key, query: query)
        }
        
        // 3. Exécuter la nouvelle requête
        print("🔄 Exécution de la requête: \(key)")
        
        // Marquer comme en cours
        let cancellable = AnyCancellable {}
        pendingQueries[key] = cancellable
        
        defer {
            // Nettoyer après exécution
            pendingQueries.removeValue(forKey: key)
        }
        
        do {
            let result = try await query()
            
            // Mettre en cache le résultat
            cacheResult(key: key, result: result)
            
            return result
        } catch {
            print("❌ Erreur requête \(key): \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Gestion du cache de requêtes
    
    private func getCachedResult(key: String) -> Any? {
        guard let cachedQuery = queryCache[key] else {
            return nil
        }
        
        // Vérifier la validité du cache
        if Date().timeIntervalSince(cachedQuery.timestamp) > cacheTimeout {
            queryCache.removeValue(forKey: key)
            return nil
        }
        
        return cachedQuery.result
    }
    
    private func cacheResult(key: String, result: Any) {
        queryCache[key] = CachedQuery(
            result: result,
            timestamp: Date()
        )
        
        // Nettoyer automatiquement le cache
        cleanExpiredCache()
    }
    
    private func cleanExpiredCache() {
        let now = Date()
        queryCache = queryCache.filter { _, cachedQuery in
            now.timeIntervalSince(cachedQuery.timestamp) <= cacheTimeout
        }
    }
    
    // MARK: - Optimisations spécifiques
    
    // Requête optimisée pour les médicaments
    func getOptimizedMedicines(
        repository: MedicineRepositoryProtocol
    ) async throws -> [Medicine] {
        return try await executeOptimizedQuery(key: "all_medicines") {
            try await repository.getMedicines()
        }
    }
    
    // Requête optimisée pour les rayons
    func getOptimizedAisles(
        repository: AisleRepositoryProtocol
    ) async throws -> [Aisle] {
        return try await executeOptimizedQuery(key: "all_aisles") {
            try await repository.getAisles()
        }
    }
    
    // Requête optimisée pour un médicament spécifique
    func getOptimizedMedicine(
        id: String,
        repository: MedicineRepositoryProtocol
    ) async throws -> Medicine? {
        return try await executeOptimizedQuery(key: "medicine_\(id)") {
            try await repository.getMedicine(id: id)
        }
    }
    
    // Requête optimisée pour l'historique
    func getOptimizedHistory(
        repository: HistoryRepositoryProtocol,
        limit: Int = 50
    ) async throws -> [HistoryEntry] {
        return try await executeOptimizedQuery(key: "history_limit_\(limit)") {
            // Simuler une méthode d'historique avec limite
            let allHistory = try await repository.getAllHistory()
            return Array(allHistory.prefix(limit))
        }
    }
    
    // MARK: - Invalidation du cache
    
    func invalidateCache(for key: String) {
        queryCache.removeValue(forKey: key)
        print("🗑️ Cache invalidé pour: \(key)")
    }
    
    func invalidateAllMedicinesCache() {
        let medicineCacheKeys = queryCache.keys.filter { $0.hasPrefix("medicine") || $0 == "all_medicines" }
        medicineCacheKeys.forEach { invalidateCache(for: $0) }
    }
    
    func invalidateAllAislesCache() {
        let aisleCacheKeys = queryCache.keys.filter { $0.hasPrefix("aisle") || $0 == "all_aisles" }
        aisleCacheKeys.forEach { invalidateCache(for: $0) }
    }
    
    func clearAllCache() {
        queryCache.removeAll()
        pendingQueries.removeAll()
        print("🗑️ Tout le cache de requêtes vidé")
    }
    
    // MARK: - Statistiques
    
    func getOptimizationStats() -> OptimizationStats {
        let cachedQueriesCount = queryCache.count
        let pendingQueriesCount = pendingQueries.count
        let cacheHitRatio = calculateCacheHitRatio()
        
        return OptimizationStats(
            cachedQueries: cachedQueriesCount,
            pendingQueries: pendingQueriesCount,
            cacheHitRatio: cacheHitRatio,
            oldestCacheEntry: getOldestCacheAge()
        )
    }
    
    private func calculateCacheHitRatio() -> Double {
        // Calcul simplifié basé sur le nombre d'entrées cache
        guard queryCache.count > 0 else { return 0.0 }
        return min(1.0, Double(queryCache.count) / 10.0) // Ratio approximatif
    }
    
    private func getOldestCacheAge() -> TimeInterval? {
        guard !queryCache.isEmpty else { return nil }
        
        let oldestTimestamp = queryCache.values.map(\.timestamp).min()
        return oldestTimestamp.map { Date().timeIntervalSince($0) }
    }
}

// MARK: - Structures de support

private struct CachedQuery {
    let result: Any
    let timestamp: Date
}

struct OptimizationStats {
    let cachedQueries: Int
    let pendingQueries: Int
    let cacheHitRatio: Double
    let oldestCacheEntry: TimeInterval?
    
    var cacheHitPercentage: String {
        return String(format: "%.1f%%", cacheHitRatio * 100)
    }
    
    var oldestCacheAgeDescription: String {
        guard let age = oldestCacheEntry else {
            return "Aucune entrée"
        }
        
        if age < 60 {
            return "\(Int(age))s"
        } else if age < 3600 {
            return "\(Int(age / 60))min"
        } else {
            return "\(Int(age / 3600))h"
        }
    }
}