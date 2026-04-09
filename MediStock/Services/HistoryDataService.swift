import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Service spécialisé pour la gestion de l'historique
// Principe KISS : Une seule responsabilité - Gérer l'historique

class HistoryDataService {
    // MARK: - Test Mode Detection
    private var isTestMode: Bool {
        ProcessInfo.processInfo.environment["UNIT_TESTS_ONLY"] == "1"
    }

    // Lazy initialization to avoid crash during tests
    private lazy var db: Firestore = {
        guard !isTestMode else {
            fatalError("Firestore should not be accessed in test mode. Use mocks instead.")
        }
        return Firestore.firestore()
    }()

    // Cache pour optimiser les performances
    private var historyCache: [String: (entries: [HistoryEntry], timestamp: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 30 // 30 secondes

    // Helper pour obtenir l'ID utilisateur courant
    private var userId: String {
        guard !isTestMode else { return "test-user" }
        return Auth.auth().currentUser?.uid ?? "anonymous"
    }
    
    // MARK: - Méthodes Publiques
    
    /// Récupère l'historique avec filtres optionnels
    func getHistory(
        medicineId: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 100
    ) async throws -> [HistoryEntry] {
        var query = db.collection("history")
            .whereField("userId", isEqualTo: userId)

        // Appliquer les filtres
        if let medicineId = medicineId {
            query = query.whereField("medicineId", isEqualTo: medicineId)
        }

        if let startDate = startDate {
            query = query.whereField("timestamp", isGreaterThanOrEqualTo: startDate)
        }

        if let endDate = endDate {
            query = query.whereField("timestamp", isLessThanOrEqualTo: endDate)
        }

        // Ordonner par date décroissante et limiter
        query = query.order(by: "timestamp", descending: true).limit(to: limit)

        let snapshot = try await query.getDocuments(source: .server)

        // Décoder les entrées
        let entries: [HistoryEntry] = snapshot.documents.compactMap { doc in
            try? doc.data(as: HistoryEntry.self)
        }

        return entries
    }
    
    /// Enregistre une action sur un médicament
    /// Note: Les erreurs sont gérées silencieusement car l'historique est optionnel
    /// et ne doit pas bloquer les opérations principales
    func recordMedicineAction(
        medicineId: String,
        medicineName: String,
        action: String,
        details: String
    ) async throws {
        let entry = HistoryEntryExtended(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: userId,
            action: action,
            details: details,
            timestamp: Date(),
            metadata: [
                "medicineName": medicineName,
                "itemType": "medicine"
            ]
        )

        do {
            try await saveHistoryEntry(entry)
        } catch {
            // Gestion silencieuse : l'historique est une fonctionnalité secondaire qui ne doit pas bloquer
            Task {
                await FirebaseService.shared.logError(error, userInfo: [
                    "action": action,
                    "context": "recordMedicineAction_silent_failure"
                ])
            }
        }
    }
    
    /// Enregistre une action sur un rayon
    /// Note: Les erreurs sont gérées silencieusement car l'historique est optionnel
    func recordAisleAction(
        aisleId: String,
        aisleName: String,
        action: String,
        details: String
    ) async throws {
        let entry = HistoryEntryExtended(
            id: UUID().uuidString,
            medicineId: "", // Pas de médicament associé
            userId: userId,
            action: action,
            details: details,
            timestamp: Date(),
            metadata: [
                "aisleId": aisleId,
                "aisleName": aisleName,
                "itemType": "aisle"
            ]
        )

        do {
            try await saveHistoryEntry(entry)
        } catch {
            Task {
                await FirebaseService.shared.logError(error, userInfo: [
                    "action": action,
                    "context": "recordAisleAction_silent_failure"
                ])
            }
        }
    }
    
    /// Enregistre un ajustement de stock
    /// Note: Les erreurs sont gérées silencieusement car l'historique est optionnel
    func recordStockAdjustment(
        medicineId: String,
        medicineName: String,
        adjustment: Int,
        newStock: Int,
        details: String
    ) async throws {
        let entry = HistoryEntryExtended(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: userId,
            action: HistoryActionType.adjustment.rawValue,
            details: details,
            timestamp: Date(),
            metadata: [
                "medicineName": medicineName,
                "adjustment": String(adjustment),
                "newStock": String(newStock),
                "itemType": "medicine"
            ]
        )

        do {
            try await saveHistoryEntry(entry)
        } catch {
            Task {
                await FirebaseService.shared.logError(error, userInfo: [
                    "adjustment": String(adjustment),
                    "context": "recordStockAdjustment_silent_failure"
                ])
            }
        }
    }
    
    /// Enregistre une suppression
    /// Note: Les erreurs sont gérées silencieusement car l'historique est optionnel
    func recordDeletion(
        itemType: String,
        itemId: String,
        itemName: String,
        details: String
    ) async throws {
        let entry = HistoryEntryExtended(
            id: UUID().uuidString,
            medicineId: itemType == "medicine" ? itemId : "",
            userId: userId,
            action: HistoryActionType.deletion.rawValue,
            details: details,
            timestamp: Date(),
            metadata: [
                "itemType": itemType,
                "itemId": itemId,
                "itemName": itemName
            ]
        )

        do {
            try await saveHistoryEntry(entry)
        } catch {
            Task {
                await FirebaseService.shared.logError(error, userInfo: [
                    "itemType": itemType,
                    "context": "recordDeletion_silent_failure"
                ])
            }
        }
    }
    
    /// Supprime les entrées d'historique plus anciennes qu'une date donnée
    func cleanOldHistory(olderThan date: Date) async throws {
        let batch = db.batch()
        
        let oldEntries = try await db.collection("history")
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isLessThan: date)
            .getDocuments()
        
        // Limiter à 500 suppressions par batch (limite Firestore)
        let entriesToDelete = oldEntries.documents.prefix(500)
        
        for doc in entriesToDelete {
            batch.deleteDocument(doc.reference)
        }

        try await batch.commit()
    }
    
    // MARK: - Méthodes Privées
    
    private func saveHistoryEntry(_ entry: HistoryEntryExtended) async throws {
        let docRef = db.collection("history").document(entry.id)

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                // Sauvegarder uniquement le HistoryEntry de base (sans metadata)
                // pour maintenir la compatibilité avec le modèle existant
                let baseEntry = entry.baseEntry
                try transaction.setData(from: baseEntry, forDocument: docRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            return nil
        }

        // Invalider le cache après l'ajout d'une nouvelle entrée
        clearCache()
    }
    
    private func clearCache() {
        historyCache.removeAll()
    }
}

// MARK: - Statistiques d'Historique

extension HistoryDataService {
    /// Structure pour les statistiques d'historique
    struct HistoryStats {
        let totalActions: Int
        let actionsByType: [String: Int]
        let recentActivity: [Date: Int] // Actions par jour
    }
    
    /// Récupère les statistiques d'historique
    func getHistoryStats(days: Int = 30) async throws -> HistoryStats {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let entries = try await getHistory(
            startDate: startDate,
            limit: 1000
        )
        
        // Calculer les statistiques
        var actionsByType: [String: Int] = [:]
        var recentActivity: [Date: Int] = [:]
        
        for entry in entries {
            // Actions par type
            actionsByType[entry.action, default: 0] += 1
            
            // Activité par jour
            let dayStart = Calendar.current.startOfDay(for: entry.timestamp)
            recentActivity[dayStart, default: 0] += 1
        }
        
        return HistoryStats(
            totalActions: entries.count,
            actionsByType: actionsByType,
            recentActivity: recentActivity
        )
    }
}