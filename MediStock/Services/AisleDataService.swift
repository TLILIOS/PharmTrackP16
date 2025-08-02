import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Service spécialisé pour la gestion des rayons
// Principe KISS : Une seule responsabilité - Gérer les rayons

class AisleDataService {
    private let db = Firestore.firestore()
    private let historyService: HistoryDataService
    
    // MARK: - Pagination State
    private var lastDocument: DocumentSnapshot?
    private var hasMore = true
    
    // Helper pour obtenir l'ID utilisateur courant
    private var userId: String {
        Auth.auth().currentUser?.uid ?? "anonymous"
    }
    
    // MARK: - Initialisation
    
    init(historyService: HistoryDataService = HistoryDataService()) {
        self.historyService = historyService
    }
    
    // MARK: - Méthodes Publiques
    
    /// Récupère tous les rayons de l'utilisateur
    func getAllAisles() async throws -> [Aisle] {
        let snapshot = try await db.collection("aisles")
            .whereField("userId", isEqualTo: userId)
            .order(by: "name")
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Aisle.self)
        }
    }
    
    /// Récupère les rayons avec pagination
    func getAislesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Aisle] {
        if refresh {
            resetPagination()
        }
        
        guard hasMore else { return [] }
        
        var query = db.collection("aisles")
            .whereField("userId", isEqualTo: userId)
            .order(by: "name")
            .limit(to: limit)
        
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await query.getDocuments()
        
        // Mise à jour de l'état de pagination
        hasMore = snapshot.documents.count >= limit
        lastDocument = snapshot.documents.last
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Aisle.self)
        }
    }
    
    /// Récupère un rayon par son ID
    func getAisle(by id: String) async throws -> Aisle? {
        let doc = try await db.collection("aisles").document(id).getDocument()
        return try? doc.data(as: Aisle.self)
    }
    
    /// Vérifie si un rayon existe
    func checkAisleExists(_ aisleId: String) async throws -> Bool {
        let doc = try await db.collection("aisles").document(aisleId).getDocument()
        return doc.exists && doc.data()?["userId"] as? String == userId
    }
    
    /// Sauvegarde ou met à jour un rayon
    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        // 1. Validation
        try aisle.validate()
        
        // 2. Vérifier l'unicité du nom
        try await validateUniqueName(aisle)
        
        // 3. Préparer le rayon pour la sauvegarde
        let (docId, aisleData) = prepareAisleForSave(aisle)
        
        // 4. Sauvegarder
        let savedAisle = try await performSaveTransaction(aisle, docId: docId, data: aisleData)
        
        // 5. Enregistrer dans l'historique
        try await recordAisleHistory(savedAisle, isNew: aisle.id.isEmpty)
        
        return savedAisle
    }
    
    /// Supprime un rayon
    func deleteAisle(_ aisle: Aisle) async throws {
        guard !aisle.id.isEmpty else {
            throw ValidationError.invalidId
        }
        
        // Vérifier qu'aucun médicament n'est lié à ce rayon
        try await validateNoMedicinesInAisle(aisle.id)
        
        // Supprimer le rayon
        try await db.collection("aisles").document(aisle.id).delete()
        
        // Enregistrer dans l'historique
        try await historyService.recordDeletion(
            itemType: "aisle",
            itemId: aisle.id,
            itemName: aisle.name,
            details: "Suppression du rayon \(aisle.name)"
        )
    }
    
    /// Compte le nombre de médicaments dans un rayon
    func countMedicinesInAisle(_ aisleId: String) async throws -> Int {
        let snapshot = try await db.collection("medicines")
            .whereField("userId", isEqualTo: userId)
            .whereField("aisleId", isEqualTo: aisleId)
            .count
            .getAggregation(source: .server)
        
        return Int(truncating: snapshot.count)
    }
    
    // MARK: - Méthodes Privées
    
    private func resetPagination() {
        lastDocument = nil
        hasMore = true
    }
    
    private func validateUniqueName(_ aisle: Aisle) async throws {
        var query = db.collection("aisles")
            .whereField("userId", isEqualTo: userId)
            .whereField("name", isEqualTo: aisle.name)
        
        // Si mise à jour, exclure le rayon actuel
        if !aisle.id.isEmpty {
            query = query.whereField(FieldPath.documentID(), isNotEqualTo: aisle.id)
        }
        
        let snapshot = try await query.getDocuments()
        
        if !snapshot.documents.isEmpty {
            throw ValidationError.duplicateAisleName(name: aisle.name)
        }
    }
    
    private func validateNoMedicinesInAisle(_ aisleId: String) async throws {
        let count = try await countMedicinesInAisle(aisleId)
        
        if count > 0 {
            throw ValidationError.aisleContainsMedicines(count: count)
        }
    }
    
    private func prepareAisleForSave(_ aisle: Aisle) -> (id: String, data: [String: Any]) {
        let docId = aisle.id.isEmpty ? db.collection("aisles").document().documentID : aisle.id
        
        var data: [String: Any] = [
            "name": ValidationHelper.sanitizeName(aisle.name),
            "colorHex": aisle.colorHex,
            "icon": aisle.icon,
            "userId": userId,
            "updatedAt": Date()
        ]
        
        // Add optional description if present
        if let description = aisle.description {
            data["description"] = description
        }
        
        // Add createdAt for new aisles
        if aisle.id.isEmpty {
            data["createdAt"] = Date()
        }
        
        return (id: docId, data: data)
    }
    
    private func performSaveTransaction(_ aisle: Aisle, docId: String, data: [String: Any]) async throws -> Aisle {
        let aisleRef = db.collection("aisles").document(docId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            // Sauvegarder le rayon
            transaction.setData(data, forDocument: aisleRef)
            return nil
        }
        
        // Return the aisle with the correct ID
        return Aisle(
            id: docId,
            name: aisle.name,
            description: aisle.description,
            colorHex: aisle.colorHex,
            icon: aisle.icon
        )
    }
    
    private func recordAisleHistory(_ aisle: Aisle, isNew: Bool) async throws {
        let action = isNew ? "Création" : "Modification"
        let details = isNew 
            ? "Création du rayon \(aisle.name)"
            : "Mise à jour du rayon \(aisle.name)"
        
        try await historyService.recordAisleAction(
            aisleId: aisle.id,
            aisleName: aisle.name,
            action: action,
            details: details
        )
    }
}

// MARK: - Listener pour les mises à jour temps réel

extension AisleDataService {
    /// Crée un listener pour les mises à jour temps réel des rayons
    func createAislesListener(completion: @escaping ([Aisle]) -> Void) -> ListenerRegistration {
        return db.collection("aisles")
            .whereField("userId", isEqualTo: userId)
            .order(by: "name")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Erreur listener aisles: \(error?.localizedDescription ?? "Unknown")")
                    completion([])
                    return
                }
                
                let aisles = documents.compactMap { doc in
                    try? doc.data(as: Aisle.self)
                }
                
                completion(aisles)
            }
    }
}