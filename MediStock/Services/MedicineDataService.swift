import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Service spécialisé pour la gestion des médicaments
// Principe KISS : Une seule responsabilité - Gérer les médicaments

class MedicineDataService {
    private let db = Firestore.firestore()
    private let historyService: HistoryDataService
    
    // MARK: - Pagination State
    private var lastDocument: DocumentSnapshot?
    private var hasMore = true
    
    // Helper pour obtenir l'ID utilisateur courant
    private var userId: String {
        Auth.auth().currentUser?.uid ?? "anonymous"
    }
    
    // MARK: - Initialisation avec injection de dépendances
    
    init(historyService: HistoryDataService = HistoryDataService()) {
        self.historyService = historyService
    }
    
    // MARK: - Méthodes Publiques
    
    /// Récupère tous les médicaments de l'utilisateur
    func getAllMedicines() async throws -> [Medicine] {
        let snapshot = try await db.collection("medicines")
            .whereField("userId", isEqualTo: userId)
            .order(by: "name")
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? decodeMedicine(from: doc)
        }
    }
    
    /// Récupère les médicaments avec pagination
    func getMedicinesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Medicine] {
        if refresh {
            resetPagination()
        }

        guard hasMore else { return [] }

        var query = db.collection("medicines")
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
            try? decodeMedicine(from: doc)
        }
    }
    
    /// Récupère un médicament par son ID
    func getMedicine(by id: String) async throws -> Medicine? {
        let doc = try await db.collection("medicines").document(id).getDocument()
        guard doc.exists else { return nil }
        return try? decodeMedicine(from: doc)
    }
    
    /// Sauvegarde ou met à jour un médicament
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        // 1. Validation
        try medicine.validate()
        
        // 2. Vérifier que le rayon existe
        try await validateAisleReference(medicine.aisleId)
        
        // 3. Préparer le médicament pour la sauvegarde
        let (docId, medicineData) = prepareMedicineForSave(medicine)
        
        // 4. Sauvegarder avec transaction
        let savedMedicine = try await performSaveTransaction(medicine, docId: docId, data: medicineData)
        
        // 5. Enregistrer dans l'historique
        try await recordMedicineHistory(savedMedicine, isNew: medicine.id?.isEmpty ?? true)

        // Notifier que l'historique a changé
        NotificationCenter.default.post(name: NSNotification.Name("HistoryDidChange"), object: nil)

        return savedMedicine
    }
    
    /// Supprime un médicament
    func deleteMedicine(_ medicine: Medicine) async throws {
        guard let medicineId = medicine.id, !medicineId.isEmpty else {
            throw ValidationError.invalidId
        }

        // Transaction pour supprimer et enregistrer l'historique
        _ = try await db.runTransaction { [weak self] transaction, errorPointer in
            guard let self = self else { return nil }

            let medicineRef = self.db.collection("medicines").document(medicineId)

            // Vérifier que le médicament existe
            let doc: DocumentSnapshot
            do {
                doc = try transaction.getDocument(medicineRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            guard doc.exists else {
                errorPointer?.pointee = NSError(
                    domain: "MedicineDataService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Médicament introuvable"]
                )
                return nil
            }

            // Supprimer le médicament
            transaction.deleteDocument(medicineRef)

            return nil
        }

        // Enregistrer dans l'historique (hors transaction pour éviter les blocages)
        do {
            try await historyService.recordDeletion(
                itemType: "medicine",
                itemId: medicineId,
                itemName: medicine.name,
                details: "Suppression du médicament \(medicine.name)"
            )
        } catch {
            throw error
        }

        // Notifier que l'historique a changé
        NotificationCenter.default.post(name: NSNotification.Name("HistoryDidChange"), object: nil)
    }
    
    /// Met à jour le stock d'un médicament
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        let medicineRef = db.collection("medicines").document(id)
        
        let updatedMedicine = try await db.runTransaction { transaction, errorPointer in
            let doc: DocumentSnapshot
            do {
                doc = try transaction.getDocument(medicineRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil as Any?
            }
            
            guard var medicine = try? doc.data(as: Medicine.self) else {
                errorPointer?.pointee = NSError(
                    domain: "MedicineDataService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Médicament introuvable"]
                )
                return nil
            }

            // 🔧 FIX: Assigner l'ID manuellement
            medicine.id = doc.documentID

            // Mettre à jour le stock
            medicine.currentQuantity = newStock
            
            // Mettre à jour dans Firestore
            let data: [String: Any] = [
                "currentQuantity": newStock,
                "updatedAt": Date()
            ]
            
            transaction.updateData(data, forDocument: medicineRef)
            
            return medicine
        }
        
        guard let updatedMedicine = updatedMedicine as? Medicine else {
            throw ValidationError.transactionFailed
        }
        
        // Enregistrer dans l'historique
        guard let medicineId = updatedMedicine.id else {
            throw ValidationError.invalidId
        }

        try await historyService.recordMedicineAction(
            medicineId: medicineId,
            medicineName: updatedMedicine.name,
            action: HistoryActionType.modification.rawValue,
            details: "Stock mis à jour: \(updatedMedicine.currentQuantity)"
        )

        // Notifier que l'historique a changé
        NotificationCenter.default.post(name: NSNotification.Name("HistoryDidChange"), object: nil)

        return updatedMedicine
    }
    
    /// Met à jour plusieurs médicaments
    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        let batch = db.batch()

        for medicine in medicines {
            guard let medicineId = medicine.id else {
                throw ValidationError.invalidId
            }

            let medicineRef = db.collection("medicines").document(medicineId)
            let data: [String: Any] = [
                "name": medicine.name,
                "currentQuantity": medicine.currentQuantity,
                "maxQuantity": medicine.maxQuantity,
                "warningThreshold": medicine.warningThreshold,
                "criticalThreshold": medicine.criticalThreshold,
                "updatedAt": Date()
            ]
            batch.updateData(data, forDocument: medicineRef)
        }

        try await batch.commit()

        // Enregistrer dans l'historique
        for medicine in medicines {
            guard let medicineId = medicine.id else { continue }

            try await historyService.recordMedicineAction(
                medicineId: medicineId,
                medicineName: medicine.name,
                action: HistoryActionType.modification.rawValue,
                details: "Médicament mis à jour en batch"
            )
        }
    }
    
    /// Ajuste le stock d'un médicament
    func adjustStock(medicineId: String, adjustment: Int) async throws -> Medicine {
        guard adjustment != 0 else {
            throw ValidationError.invalidStockAdjustment
        }
        
        let medicineRef = db.collection("medicines").document(medicineId)
        
        let updatedMedicine = try await db.runTransaction { transaction, errorPointer in
            let doc: DocumentSnapshot
            do {
                doc = try transaction.getDocument(medicineRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil as Any?
            }
            
            guard var medicine = try? doc.data(as: Medicine.self) else {
                errorPointer?.pointee = NSError(
                    domain: "MedicineDataService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Médicament introuvable"]
                )
                return nil
            }

            // 🔧 FIX: Assigner l'ID manuellement
            medicine.id = doc.documentID

            // Calculer le nouveau stock
            let newStock = max(0, medicine.currentQuantity + adjustment)
            medicine.currentQuantity = newStock
            
            // Mettre à jour dans Firestore
            do {
                try transaction.setData(from: medicine, forDocument: medicineRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            return medicine
        }
        
        guard let updatedMedicine = updatedMedicine as? Medicine else {
            throw ValidationError.transactionFailed
        }
        
        // Enregistrer l'ajustement dans l'historique
        guard let medicineId = updatedMedicine.id else {
            throw ValidationError.invalidId
        }

        let action = adjustment > 0 ? "Ajout" : "Retrait"
        let details = "\(action) de \(abs(adjustment)) unité(s). Nouveau stock: \(updatedMedicine.currentQuantity)"

        try await historyService.recordStockAdjustment(
            medicineId: medicineId,
            medicineName: updatedMedicine.name,
            adjustment: adjustment,
            newStock: updatedMedicine.currentQuantity,
            details: details
        )

        // Notifier que l'historique a changé
        NotificationCenter.default.post(name: NSNotification.Name("HistoryDidChange"), object: nil)

        return updatedMedicine
    }
    
    // MARK: - Méthodes Privées

    /// Helper pour décoder un médicament depuis Firestore et assigner l'ID manuellement
    private func decodeMedicine(from document: DocumentSnapshot) throws -> Medicine {
        var medicine = try document.data(as: Medicine.self)

        // 🔧 FIX: Assigner manuellement le documentID car @DocumentID ne fonctionne pas toujours
        // avec doc.data(as:)
        medicine.id = document.documentID

        return medicine
    }

    private func resetPagination() {
        lastDocument = nil
        hasMore = true
    }
    
    private func validateAisleReference(_ aisleId: String) async throws {
        let aisleDoc = try await db.collection("aisles").document(aisleId).getDocument()
        guard aisleDoc.exists else {
            throw ValidationError.invalidAisleReference(aisleId: aisleId)
        }
    }
    
    private func prepareMedicineForSave(_ medicine: Medicine) -> (id: String, data: [String: Any]) {
        let docId = (medicine.id?.isEmpty ?? true) ? db.collection("medicines").document().documentID : (medicine.id ?? "")
        
        var data: [String: Any] = [
            "name": ValidationHelper.sanitizeName(medicine.name),
            "currentQuantity": medicine.currentQuantity,
            "maxQuantity": medicine.maxQuantity,
            "warningThreshold": medicine.warningThreshold,
            "criticalThreshold": medicine.criticalThreshold,
            "aisleId": medicine.aisleId,
            "unit": medicine.unit,
            "userId": userId,
            "updatedAt": Date()
        ]
        
        // Add optional fields
        if let description = medicine.description {
            data["description"] = description
        }
        if let dosage = medicine.dosage {
            data["dosage"] = dosage
        }
        if let form = medicine.form {
            data["form"] = form
        }
        if let reference = medicine.reference {
            data["reference"] = reference
        }
        if let expiryDate = medicine.expiryDate {
            data["expiryDate"] = expiryDate
        }
        
        // Add createdAt for new medicines
        if medicine.id?.isEmpty ?? true {
            data["createdAt"] = Date()
        } else {
            data["createdAt"] = medicine.createdAt
        }
        
        return (id: docId, data: data)
    }
    
    private func performSaveTransaction(_ medicine: Medicine, docId: String, data: [String: Any]) async throws -> Medicine {
        let medicineRef = db.collection("medicines").document(docId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            // Sauvegarder le médicament
            transaction.setData(data, forDocument: medicineRef)
            return nil
        }
        
        // Return the medicine with the correct ID
        return Medicine(
            id: docId,
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
            createdAt: (medicine.id?.isEmpty ?? true) ? Date() : medicine.createdAt,
            updatedAt: Date()
        )
    }
    
    private func recordMedicineHistory(_ medicine: Medicine, isNew: Bool) async throws {
        guard let medicineId = medicine.id else {
            throw ValidationError.invalidId
        }

        let action = isNew ? HistoryActionType.addition.rawValue : HistoryActionType.modification.rawValue
        let details = isNew
            ? "Ajout du médicament \(medicine.name) avec un stock initial de \(medicine.currentQuantity)"
            : "Mise à jour du médicament \(medicine.name)"

        try await historyService.recordMedicineAction(
            medicineId: medicineId,
            medicineName: medicine.name,
            action: action,
            details: details
        )
    }
}

// MARK: - Listener pour les mises à jour temps réel

extension MedicineDataService {
    /// Crée un listener pour les mises à jour temps réel des médicaments
    func createMedicinesListener(completion: @escaping ([Medicine]) -> Void) -> ListenerRegistration {
        return db.collection("medicines")
            .whereField("userId", isEqualTo: userId)
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if error != nil {
                    completion([])
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                // Décoder les médicaments
                let medicines: [Medicine] = documents.compactMap { doc in
                    try? self.decodeMedicine(from: doc)
                }

                completion(medicines)
            }
    }
}