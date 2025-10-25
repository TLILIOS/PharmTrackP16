import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Service spécialisé pour la gestion de l'historique
// Principe KISS : Une seule responsabilité - Gérer l'historique

class HistoryDataService {
    private let db = Firestore.firestore()
    
    // Cache pour optimiser les performances
    private var historyCache: [String: (entries: [HistoryEntry], timestamp: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 30 // 30 secondes
    
    // Helper pour obtenir l'ID utilisateur courant
    private var userId: String {
        Auth.auth().currentUser?.uid ?? "anonymous"
    }
    
    // MARK: - Méthodes Publiques
    
    /// Récupère l'historique avec filtres optionnels
    func getHistory(
        medicineId: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 100
    ) async throws -> [HistoryEntry] {
        print("📡 [HistoryDataService] getHistory() appelée")
        print("   MedicineId: \(medicineId ?? "nil")")
        print("   UserID: \(userId)")

        // 🔧 FIX: Cache désactivé car il cause des problèmes de synchronisation
        // L'historique doit toujours afficher les données les plus récentes
        print("🚫 [HistoryDataService] Cache désactivé - Chargement direct depuis Firestore")

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

        // 🔧 FIX: Toujours charger depuis le serveur pour avoir les données fraîches
        // Ne PAS utiliser le cache Firestore car il peut contenir des données obsolètes
        print("📡 [HistoryDataService] Chargement depuis le SERVEUR (pas de cache)...")
        let snapshot = try await query.getDocuments(source: .server)
        print("📦 [HistoryDataService] Reçu \(snapshot.documents.count) documents du serveur")
        
        // Optimisation: pré-allouer l'array
        var entries = [HistoryEntry]()
        entries.reserveCapacity(snapshot.documents.count)

        var decodingErrors = 0

        for (index, doc) in snapshot.documents.enumerated() {
            do {
                let entry = try doc.data(as: HistoryEntry.self)
                entries.append(entry)
            } catch {
                decodingErrors += 1
                print("❌ [HistoryDataService] [\(index + 1)/\(snapshot.documents.count)] ERREUR de décodage pour document \(doc.documentID)")
                print("   Type d'erreur: \(type(of: error))")
                print("   Message: \(error.localizedDescription)")
                print("   Données brutes du document:")
                let data = doc.data()
                for (key, value) in data.sorted(by: { $0.key < $1.key }) {
                    print("     - \(key): \(value) (type: \(type(of: value)))")
                }
            }
        }

        if decodingErrors > 0 {
            print("⚠️ [HistoryDataService] ATTENTION: \(decodingErrors) entrée(s) ont échoué au décodage sur \(snapshot.documents.count) documents")
        }

        // 🔧 FIX: Ne PAS mettre en cache pour éviter les problèmes de synchronisation
        // Le cache a été désactivé pour garantir des données toujours fraîches

        print("✅ [HistoryDataService] Retour de \(entries.count) entrées (sans mise en cache)")
        return entries
    }
    
    /// Enregistre une action sur un médicament
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
        
        try await saveHistoryEntry(entry)
    }
    
    /// Enregistre une action sur un rayon
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
        
        try await saveHistoryEntry(entry)
    }
    
    /// Enregistre un ajustement de stock
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
            action: "Ajustement stock",
            details: details,
            timestamp: Date(),
            metadata: [
                "medicineName": medicineName,
                "adjustment": String(adjustment),
                "newStock": String(newStock),
                "itemType": "medicine"
            ]
        )
        
        try await saveHistoryEntry(entry)
    }
    
    /// Enregistre une suppression
    func recordDeletion(
        itemType: String,
        itemId: String,
        itemName: String,
        details: String
    ) async throws {
        print("📝 [HistoryDataService] recordDeletion() appelée")
        print("   Type: \(itemType)")
        print("   ID: \(itemId)")
        print("   Nom: \(itemName)")
        print("   Détails: \(details)")
        print("   UserID utilisé: \(userId)")

        let entry = HistoryEntryExtended(
            id: UUID().uuidString,
            medicineId: itemType == "medicine" ? itemId : "",
            userId: userId,
            action: "Suppression",
            details: details,
            timestamp: Date(),
            metadata: [
                "itemType": itemType,
                "itemId": itemId,
                "itemName": itemName
            ]
        )

        print("✅ [HistoryDataService] Entrée d'historique créée, sauvegarde...")

        do {
            try await saveHistoryEntry(entry)
            print("✅ [HistoryDataService] Suppression enregistrée avec succès dans Firestore")
        } catch {
            print("❌ [HistoryDataService] ERREUR lors de la sauvegarde: \(error.localizedDescription)")
            print("   Détails: \(error)")
            throw error
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
        
        print("Suppression de \(entriesToDelete.count) entrées d'historique")
    }
    
    // MARK: - Méthodes Privées
    
    private func saveHistoryEntry(_ entry: HistoryEntryExtended) async throws {
        let docRef = db.collection("history").document(entry.id)

        print("💾 [HistoryDataService] saveHistoryEntry()")
        print("   Document ID: \(entry.id)")
        print("   Collection: history")
        print("   Action: \(entry.action)")
        print("   Details: \(entry.details)")
        print("   MedicineID: \(entry.medicineId)")
        print("   UserID: \(entry.userId)")
        print("   Timestamp: \(entry.timestamp)")

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                // Sauvegarder uniquement le HistoryEntry de base (sans metadata)
                // pour maintenir la compatibilité avec le modèle existant
                print("💾 [HistoryDataService] Encodage de l'entrée...")

                let baseEntry = entry.baseEntry
                print("   BaseEntry - Action: '\(baseEntry.action)' | Details: '\(baseEntry.details)'")

                try transaction.setData(from: baseEntry, forDocument: docRef)
                print("✅ [HistoryDataService] Données encodées et enregistrées dans la transaction")
                print("   DocumentPath: history/\(entry.id)")
            } catch {
                print("❌ [HistoryDataService] Erreur d'encodage/enregistrement: \(error.localizedDescription)")
                print("   Type d'erreur: \(type(of: error))")
                print("   Détails complets: \(error)")
                errorPointer?.pointee = error as NSError
                return nil
            }

            return nil
        }

        print("✅ [HistoryDataService] Transaction terminée avec succès")
        print("   ✓ Entrée '\(entry.action)' enregistrée dans Firestore à history/\(entry.id)")

        // Invalider le cache après l'ajout d'une nouvelle entrée
        clearCache()
        print("🔄 [HistoryDataService] Cache invalidé")
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