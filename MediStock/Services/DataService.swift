import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Service de données unifié (remplace tous les repositories)

class DataService {
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    // Helper pour obtenir l'ID utilisateur courant
    private var userId: String {
        Auth.auth().currentUser?.uid ?? "anonymous"
    }
    
    // MARK: - Gestion des listeners
    
    func startListeningToMedicines(completion: @escaping ([Medicine]) -> Void) {
        let listener = db.collection("medicines")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching medicines: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let medicines = documents.compactMap { doc in
                    try? doc.data(as: Medicine.self)
                }
                
                completion(medicines)
            }
        
        listeners.append(listener)
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    deinit {
        stopListening()
    }
    
    // MARK: - Médicaments
    
    private var lastMedicineDocument: DocumentSnapshot?
    private var hasMoreMedicines = true
    
    func getMedicines() async throws -> [Medicine] {
        let snapshot = try await db.collection("medicines")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Medicine.self)
        }
    }
    
    func getMedicinesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Medicine] {
        if refresh {
            lastMedicineDocument = nil
            hasMoreMedicines = true
        }
        
        guard hasMoreMedicines else { return [] }
        
        var query = db.collection("medicines")
            .whereField("userId", isEqualTo: userId)
            .order(by: "name")
            .limit(to: limit)
        
        if let lastDoc = lastMedicineDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await query.getDocuments()
        
        if snapshot.documents.count < limit {
            hasMoreMedicines = false
        }
        
        lastMedicineDocument = snapshot.documents.last
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Medicine.self)
        }
    }
    
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        var medicineToSave = medicine
        
        if medicine.id.isEmpty {
            // Nouveau médicament
            let docRef = db.collection("medicines").document()
            medicineToSave = Medicine(
                id: docRef.documentID,
                name: medicine.name,
                description: medicine.description,
                dosage: medicine.dosage,
                form: medicine.form,
                reference: medicine.reference,
                unit: medicine.unit,
                currentQuantity: medicine.currentQuantity,
                maxQuantity: medicine.maxQuantity,
                warningThreshold: medicine.warningThreshold,
                criticalThreshold: medicine.criticalThreshold,
                expiryDate: medicine.expiryDate,
                aisleId: medicine.aisleId,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            var data = try Firestore.Encoder().encode(medicineToSave)
            data["userId"] = userId
            
            try await docRef.setData(data)
        } else {
            // Mise à jour
            medicineToSave = Medicine(
                id: medicine.id,
                name: medicine.name,
                description: medicine.description,
                dosage: medicine.dosage,
                form: medicine.form,
                reference: medicine.reference,
                unit: medicine.unit,
                currentQuantity: medicine.currentQuantity,
                maxQuantity: medicine.maxQuantity,
                warningThreshold: medicine.warningThreshold,
                criticalThreshold: medicine.criticalThreshold,
                expiryDate: medicine.expiryDate,
                aisleId: medicine.aisleId,
                createdAt: medicine.createdAt,
                updatedAt: Date()
            )
            
            var data = try Firestore.Encoder().encode(medicineToSave)
            data["userId"] = userId
            
            try await db.collection("medicines").document(medicine.id).setData(data)
        }
        
        return medicineToSave
    }
    
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        let docRef = db.collection("medicines").document(id)
        
        try await docRef.updateData([
            "currentQuantity": newStock,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        let doc = try await docRef.getDocument()
        guard let medicine = try? doc.data(as: Medicine.self) else {
            throw NSError(domain: "DataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Médicament non trouvé"])
        }
        
        return medicine
    }
    
    func deleteMedicine(id: String) async throws {
        try await db.collection("medicines").document(id).delete()
    }
    
    // MARK: - Rayons
    
    private var lastAisleDocument: DocumentSnapshot?
    private var hasMoreAisles = true
    
    func getAisles() async throws -> [Aisle] {
        let snapshot = try await db.collection("aisles")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Aisle.self)
        }
    }
    
    func getAislesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Aisle] {
        if refresh {
            lastAisleDocument = nil
            hasMoreAisles = true
        }
        
        guard hasMoreAisles else { return [] }
        
        var query = db.collection("aisles")
            .whereField("userId", isEqualTo: userId)
            .order(by: "name")
            .limit(to: limit)
        
        if let lastDoc = lastAisleDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await query.getDocuments()
        
        if snapshot.documents.count < limit {
            hasMoreAisles = false
        }
        
        lastAisleDocument = snapshot.documents.last
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Aisle.self)
        }
    }
    
    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        var aisleToSave = aisle
        
        if aisle.id.isEmpty {
            let docRef = db.collection("aisles").document()
            aisleToSave = Aisle(
                id: docRef.documentID,
                name: aisle.name,
                description: aisle.description,
                colorHex: aisle.colorHex,
                icon: aisle.icon
            )
        }
        
        var data = try Firestore.Encoder().encode(aisleToSave)
        data["userId"] = userId
        
        try await db.collection("aisles").document(aisleToSave.id).setData(data)
        return aisleToSave
    }
    
    func deleteAisle(id: String) async throws {
        try await db.collection("aisles").document(id).delete()
    }
    
    // MARK: - Historique
    
    func getHistory() async throws -> [HistoryEntry] {
        let snapshot = try await db.collection("history")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: HistoryEntry.self)
        }
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        var data = try Firestore.Encoder().encode(entry)
        data["userId"] = userId
        
        try await db.collection("history").document(entry.id).setData(data)
    }
    
    // MARK: - Batch Operations
    
    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        let batch = db.batch()
        
        for medicine in medicines {
            let ref = db.collection("medicines").document(medicine.id)
            let data: [String: Any] = [
                "currentQuantity": medicine.currentQuantity,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            batch.updateData(data, forDocument: ref)
        }
        
        try await batch.commit()
    }
    
    func deleteMultipleMedicines(ids: [String]) async throws {
        let batch = db.batch()
        
        for id in ids {
            let ref = db.collection("medicines").document(id)
            batch.deleteDocument(ref)
        }
        
        try await batch.commit()
    }
}