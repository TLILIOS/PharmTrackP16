import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Service de données Firebase unifié avec validation et transactions

class FirebaseDataService: DataServiceProtocol {
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
            .order(by: "name")
            .addSnapshotListener { snapshot, error in
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

    func startListeningToAisles(completion: @escaping ([Aisle]) -> Void) {
        let listener = db.collection("aisles")
            .whereField("userId", isEqualTo: userId)
            .order(by: "name")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching aisles: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let aisles = documents.compactMap { doc in
                    if let aisleWithTimestamps = try? doc.data(as: AisleWithTimestamps.self) {
                        return aisleWithTimestamps.toAisle
                    }
                    return try? doc.data(as: Aisle.self)
                }

                completion(aisles)
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
    
    // MARK: - Médicaments (Version refactorisée)
    
    private var lastMedicineDocument: DocumentSnapshot?
    private var hasMoreMedicines = true
    
    func getMedicines() async throws -> [Medicine] {
        // Essayer d'abord le cache, puis le serveur si le cache est vide
        do {
            let cacheSnapshot = try await db.collection("medicines")
                .whereField("userId", isEqualTo: userId)
                .getDocuments(source: .cache)

            let cachedMedicines = cacheSnapshot.documents.compactMap { doc in
                try? doc.data(as: Medicine.self)
            }

            // Si le cache contient des données, les retourner
            if !cachedMedicines.isEmpty {
                return cachedMedicines
            }
        } catch {
            // Le cache est vide ou une erreur s'est produite, continuer avec le serveur
            print("⚠️ Cache vide ou erreur cache : \(error.localizedDescription)")
        }

        // Charger depuis le serveur si le cache est vide
        print("📡 Chargement des médicaments depuis le serveur...")
        let serverSnapshot = try await db.collection("medicines")
            .whereField("userId", isEqualTo: userId)
            .getDocuments(source: .server)

        return serverSnapshot.documents.compactMap { doc in
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

        // Si c'est un refresh (chargement initial), forcer le serveur
        // Sinon, utiliser le comportement par défaut (cache + serveur)
        let source: FirestoreSource = refresh ? .server : .default
        let snapshot = try await query.getDocuments(source: source)

        if snapshot.documents.count < limit {
            hasMoreMedicines = false
        }

        lastMedicineDocument = snapshot.documents.last

        let medicines = snapshot.documents.compactMap { doc in
            try? doc.data(as: Medicine.self)
        }

        if refresh {
            print("📡 Chargement initial : \(medicines.count) médicaments depuis le serveur")
        }

        return medicines
    }
    
    // MARK: - Fonction saveMedicine refactorisée avec validation complète
    
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        // 1. Validation côté client
        try medicine.validate()
        
        // 2. Vérifier que le rayon existe
        let aisleExists = try await checkAisleExists(medicine.aisleId)
        guard aisleExists else {
            throw ValidationError.invalidAisleReference(aisleId: medicine.aisleId)
        }
        
        // 3. Vérifier les limites utilisateur
        if medicine.id?.isEmpty ?? true {
            let medicineCount = try await getUserMedicineCount()
            guard medicineCount < ValidationRules.maxMedicinesPerUser else {
                throw ValidationError.tooManyAisles(max: ValidationRules.maxMedicinesPerUser)
            }
        }

        // 4. Préparer le médicament avec les bonnes données
        let medicineToSave: Medicine
        let isNewMedicine = medicine.id?.isEmpty ?? true
        
        if isNewMedicine {
            // Création : générer un nouvel ID et les timestamps
            let docRef = db.collection("medicines").document()
            medicineToSave = medicine.copyWith(
                id: docRef.documentID,
                name: ValidationHelper.sanitizeName(medicine.name),
                createdAt: Date(),
                updatedAt: Date()
            )
        } else {
            // Mise à jour : conserver createdAt, mettre à jour updatedAt
            medicineToSave = medicine.copyWith(
                name: ValidationHelper.sanitizeName(medicine.name),
                updatedAt: Date()
            )
        }
        
        // 5. Utiliser une transaction pour garantir l'atomicité
        let result = try await db.runTransaction { [weak self] transaction, errorPointer in
            guard let self = self else {
                errorPointer?.pointee = NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])
                return nil
            }
            
            guard let medicineId = medicineToSave.id else {
                errorPointer?.pointee = NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Medicine ID is missing"])
                return nil
            }

            let docRef = self.db.collection("medicines").document(medicineId)
            
            // Encoder les données
            var data: [String: Any]
            do {
                data = try Firestore.Encoder().encode(medicineToSave)
                data["userId"] = self.userId
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Sauvegarder dans la transaction
            transaction.setData(data, forDocument: docRef)
            
            // Créer l'entrée d'historique dans la même transaction
            let historyEntry = HistoryEntry(
                id: UUID().uuidString,
                medicineId: medicineId,
                userId: self.userId,
                action: isNewMedicine ? "Création" : "Modification",
                details: "Médicament: \(medicineToSave.name)",
                timestamp: Date()
            )
            
            do {
                let historyData = try Firestore.Encoder().encode(historyEntry)
                let historyRef = self.db.collection("history").document(historyEntry.id)
                transaction.setData(historyData, forDocument: historyRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            return medicineToSave
        }

        guard let medicine = result as? Medicine else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction failed"])
        }

        // Notifier que l'historique a changé
        NotificationCenter.default.post(name: NSNotification.Name("HistoryDidChange"), object: nil)

        return medicine
    }
    
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        // Validation de la quantité
        guard newStock >= 0 else {
            throw ValidationError.negativeQuantity(field: "stock")
        }
        
        let result = try await db.runTransaction { [weak self] transaction, errorPointer in
            guard let self = self else {
                errorPointer?.pointee = NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])
                return nil
            }
            
            let docRef = self.db.collection("medicines").document(id)
            
            // Lire le document actuel dans la transaction
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(docRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard document.exists,
                  var medicine = try? document.data(as: Medicine.self) else {
                errorPointer?.pointee = NSError(domain: "DataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Médicament non trouvé"])
                return nil
            }
            
            // Capturer l'ancienne quantité avant la mise à jour
            let oldQuantity = medicine.currentQuantity
            
            // Mettre à jour les données
            medicine.currentQuantity = newStock
            
            // Sauvegarder
            transaction.updateData([
                "currentQuantity": newStock,
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: docRef)
            
            // Créer l'entrée d'historique avec le format cohérent
            guard let medicineId = medicine.id else {
                errorPointer?.pointee = NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Medicine ID is missing"])
                return nil
            }

            let change = newStock - oldQuantity
            let historyEntry = HistoryEntry(
                id: UUID().uuidString,
                medicineId: medicineId,
                userId: self.userId,
                action: change > 0 ? "Ajout stock" : (change < 0 ? "Retrait stock" : "Ajustement de stock"),
                details: "\(abs(change)) \(medicine.unit) - Ajustement manuel (Stock: \(oldQuantity) → \(newStock))",
                timestamp: Date()
            )
            
            do {
                let historyData = try Firestore.Encoder().encode(historyEntry)
                let historyRef = self.db.collection("history").document(historyEntry.id)
                transaction.setData(historyData, forDocument: historyRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            return medicine.copyWith(currentQuantity: newStock, updatedAt: Date())
        }
        
        guard let medicine = result as? Medicine else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction failed"])
        }

        // Notifier que l'historique a changé
        NotificationCenter.default.post(name: NSNotification.Name("HistoryDidChange"), object: nil)

        return medicine
    }

    func deleteMedicine(id: String) async throws {
        print("🗑️ [FirebaseDataService] deleteMedicine() appelée pour ID: \(id)")

        _ = try await db.runTransaction { [weak self] transaction, errorPointer in
            guard let self = self else {
                errorPointer?.pointee = NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])
                return nil
            }

            let docRef = self.db.collection("medicines").document(id)

            // Vérifier que le document existe
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(docRef)
            } catch {
                print("❌ [FirebaseDataService] Erreur lors de la récupération du document: \(error.localizedDescription)")
                errorPointer?.pointee = error as NSError
                return nil
            }

            guard document.exists else {
                print("❌ [FirebaseDataService] Document non trouvé")
                errorPointer?.pointee = NSError(domain: "DataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Médicament non trouvé"])
                return nil
            }

            // Supprimer le médicament
            print("✅ [FirebaseDataService] Suppression du document")
            transaction.deleteDocument(docRef)

            // Créer l'entrée d'historique
            if let medicine = try? document.data(as: Medicine.self) {
                let historyEntry = HistoryEntry(
                    id: UUID().uuidString,
                    medicineId: id,
                    userId: self.userId,
                    action: "Suppression",
                    details: "Médicament supprimé: \(medicine.name)",
                    timestamp: Date()
                )

                print("📝 [FirebaseDataService] Création de l'entrée d'historique:")
                print("   Action: \(historyEntry.action)")
                print("   Details: \(historyEntry.details)")
                print("   UserID: \(historyEntry.userId)")

                do {
                    let historyData = try Firestore.Encoder().encode(historyEntry)
                    let historyRef = self.db.collection("history").document(historyEntry.id)
                    transaction.setData(historyData, forDocument: historyRef)
                    print("✅ [FirebaseDataService] Historique ajouté à la transaction")
                } catch {
                    print("❌ [FirebaseDataService] Erreur d'encodage de l'historique: \(error.localizedDescription)")
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }

            return true
        }

        print("✅ [FirebaseDataService] Transaction de suppression terminée")

        // Notifier que l'historique a changé
        NotificationCenter.default.post(name: NSNotification.Name("HistoryDidChange"), object: nil)
        print("📢 [FirebaseDataService] Notification HistoryDidChange envoyée")
    }

    // MARK: - Rayons (Version refactorisée)
    
    private var lastAisleDocument: DocumentSnapshot?
    private var hasMoreAisles = true
    
    func getAisles() async throws -> [Aisle] {
        let snapshot = try await db.collection("aisles")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            if let aisleWithTimestamps = try? doc.data(as: AisleWithTimestamps.self) {
                return aisleWithTimestamps.toAisle
            }
            return try? doc.data(as: Aisle.self)
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

        // Si c'est un refresh (chargement initial), forcer le serveur
        let source: FirestoreSource = refresh ? .server : .default
        let snapshot = try await query.getDocuments(source: source)

        if snapshot.documents.count < limit {
            hasMoreAisles = false
        }

        lastAisleDocument = snapshot.documents.last

        let aisles = snapshot.documents.compactMap { doc in
            if let aisleWithTimestamps = try? doc.data(as: AisleWithTimestamps.self) {
                return aisleWithTimestamps.toAisle
            }
            return try? doc.data(as: Aisle.self)
        }

        if refresh {
            print("📡 Chargement initial : \(aisles.count) rayons depuis le serveur")
        }

        return aisles
    }
    
    // MARK: - Fonction saveAisle refactorisée avec validation complète
    
    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        // 1. Validation côté client
        try aisle.validate()
        
        // 2. Vérifier l'unicité du nom
        let nameExists = try await checkAisleNameExists(aisle.name, excludingId: aisle.id)
        guard !nameExists else {
            throw ValidationError.nameAlreadyExists(name: aisle.name)
        }
        
        // 3. Déterminer si c'est un nouveau rayon
        let isNewAisle = aisle.id == nil || aisle.id?.isEmpty == true

        // 4. Vérifier les limites utilisateur pour les nouveaux rayons
        if isNewAisle {
            let aisleCount = try await getUserAisleCount()
            guard aisleCount < ValidationRules.maxAislesPerUser else {
                throw ValidationError.tooManyAisles(max: ValidationRules.maxAislesPerUser)
            }
        }

        // 5. Préparer le rayon avec timestamps
        let aisleWithTimestamps: AisleWithTimestamps

        if isNewAisle {
            // Création
            let docRef = db.collection("aisles").document()
            aisleWithTimestamps = aisle.copyWith(
                id: docRef.documentID,
                name: ValidationHelper.sanitizeName(aisle.name),
                createdAt: Date(),
                updatedAt: Date()
            )
        } else {
            // Mise à jour : récupérer createdAt existant
            guard let aisleId = aisle.id else {
                throw ValidationError.invalidId
            }
            let existingDoc = try await db.collection("aisles").document(aisleId).getDocument()
            let createdAt = existingDoc.data()?["createdAt"] as? Timestamp ?? Timestamp(date: Date())

            aisleWithTimestamps = aisle.copyWith(
                name: ValidationHelper.sanitizeName(aisle.name),
                createdAt: createdAt.dateValue(),
                updatedAt: Date()
            )
        }
        
        // 5. Utiliser une transaction pour l'atomicité
        let result = try await db.runTransaction { [weak self] transaction, errorPointer in
            guard let self = self else {
                errorPointer?.pointee = NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])
                return nil
            }
            
            let docRef = self.db.collection("aisles").document(aisleWithTimestamps.id)
            
            // Encoder et sauvegarder
            var data: [String: Any]
            do {
                data = try Firestore.Encoder().encode(aisleWithTimestamps)
                data["userId"] = self.userId
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            transaction.setData(data, forDocument: docRef)
            
            return aisleWithTimestamps.toAisle
        }
        
        guard let aisle = result as? Aisle else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction failed"])
        }
        
        return aisle
    }
    
    func deleteAisle(id: String) async throws {
        // Vérifier qu'aucun médicament n'est lié à ce rayon
        let hasMedicines = try await checkAisleHasMedicines(id)
        guard !hasMedicines else {
            throw NSError(domain: "DataService", code: 400, 
                         userInfo: [NSLocalizedDescriptionKey: "Impossible de supprimer un rayon contenant des médicaments"])
        }
        
        try await db.collection("aisles").document(id).delete()
    }
    
    // MARK: - Méthodes utilitaires privées
    
    private func checkAisleExists(_ aisleId: String) async throws -> Bool {
        let doc = try await db.collection("aisles")
            .document(aisleId)
            .getDocument()
        
        return doc.exists && doc.data()?["userId"] as? String == userId
    }
    
    private func checkAisleNameExists(_ name: String, excludingId: String? = nil) async throws -> Bool {
        let sanitizedName = ValidationHelper.sanitizeName(name).lowercased()
        
        let query = db.collection("aisles")
            .whereField("userId", isEqualTo: userId)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.contains { doc in
            guard doc.documentID != excludingId else { return false }
            if let docName = doc.data()["name"] as? String {
                return docName.lowercased() == sanitizedName
            }
            return false
        }
    }
    
    private func checkAisleHasMedicines(_ aisleId: String) async throws -> Bool {
        // Pour éviter l'erreur d'index, on récupère tous les médicaments de l'utilisateur
        // et on filtre côté client
        let snapshot = try await db.collection("medicines")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.contains { doc in
            doc.data()["aisleId"] as? String == aisleId
        }
    }
    
    private func getUserAisleCount() async throws -> Int {
        let snapshot = try await db.collection("aisles")
            .whereField("userId", isEqualTo: userId)
            .count
            .getAggregation(source: .server)
        
        return Int(truncating: snapshot.count)
    }
    
    private func getUserMedicineCount() async throws -> Int {
        let snapshot = try await db.collection("medicines")
            .whereField("userId", isEqualTo: userId)
            .count
            .getAggregation(source: .server)
        
        return Int(truncating: snapshot.count)
    }
    
    // MARK: - Historique

    func getHistory() async throws -> [HistoryEntry] {
        // 🔧 FIX: Toujours charger depuis le serveur pour avoir les données fraîches
        // Le cache Firestore peut contenir des données obsolètes qui ne reflètent pas
        // les suppressions ou modifications récentes
        print("📡 Chargement de l'historique depuis le serveur...")
        let serverSnapshot = try await db.collection("history")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
            .getDocuments(source: .server)

        print("📦 Documents reçus de Firestore: \(serverSnapshot.documents.count)")

        var history: [HistoryEntry] = []
        var decodingErrors = 0

        for (index, doc) in serverSnapshot.documents.enumerated() {
            do {
                let entry = try doc.data(as: HistoryEntry.self)
                history.append(entry)
                print("✅ [\(index + 1)/\(serverSnapshot.documents.count)] Décodé: \(entry.action) | \(entry.details)")
            } catch {
                decodingErrors += 1
                print("❌ [\(index + 1)/\(serverSnapshot.documents.count)] ERREUR de décodage pour document \(doc.documentID)")
                print("   Type d'erreur: \(type(of: error))")
                print("   Message: \(error.localizedDescription)")
                print("   Données brutes du document:")
                let data = doc.data()
                for (key, value) in data.sorted(by: { $0.key < $1.key }) {
                    print("     - \(key): \(value) (type: \(type(of: value)))")
                }
            }
        }

        print("✅ Historique chargé: \(history.count) entrées décodées avec succès")
        if decodingErrors > 0 {
            print("⚠️ ATTENTION: \(decodingErrors) entrée(s) ont échoué au décodage")
        }

        return history
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        var data = try Firestore.Encoder().encode(entry)
        data["userId"] = userId
        
        try await db.collection("history").document(entry.id).setData(data)
    }
    
    // MARK: - Batch Operations avec validation
    
    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        // Valider tous les médicaments avant la transaction
        for medicine in medicines {
            try medicine.validate()
        }
        
        let batch = db.batch()

        for medicine in medicines {
            guard let medicineId = medicine.id else {
                throw ValidationError.invalidId
            }

            let ref = db.collection("medicines").document(medicineId)
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

// MARK: - Rétrocompatibilité

/// Typealias pour maintenir la compatibilité avec le code existant
typealias DataService = FirebaseDataService