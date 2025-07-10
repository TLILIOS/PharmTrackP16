import Foundation
import Firebase
import FirebaseFirestore
import Combine

class FirebaseMedicineRepository: MedicineRepositoryProtocol {
    private let db = Firestore.firestore()
    private let collection = "medicines"
    
    // MARK: - Basic CRUD Operations
    
    func getMedicines() async throws -> [Medicine] {
        let snapshot = try await db.collection(collection).getDocuments(source: .cache)
        
        if !snapshot.isEmpty {
            return snapshot.documents.compactMap { document in
                try? document.data(as: MedicineDTO.self).toDomain()
            }
        }
        
        let serverSnapshot = try await db.collection(collection).getDocuments(source: .server)
        return serverSnapshot.documents.compactMap { document in
            try? document.data(as: MedicineDTO.self).toDomain()
        }
    }
    
    func getMedicine(id: String) async throws -> Medicine? {
        let document = try await db.collection(collection).document(id).getDocument(source: .cache)
        
        if document.exists, let medicineDTO = try? document.data(as: MedicineDTO.self) {
            return medicineDTO.toDomain()
        }
        
        let serverDocument = try await db.collection(collection).document(id).getDocument(source: .server)
        guard serverDocument.exists,
              let medicineDTO = try? serverDocument.data(as: MedicineDTO.self) else {
            return nil
        }
        
        return medicineDTO.toDomain()
    }
    
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        let medicineDTO = MedicineDTO.fromDomain(medicine)
        
        if medicine.id.isEmpty {
            // Créer un nouveau médicament avec un ID généré
            let documentRef = db.collection(collection).document()
            let newMedicine = Medicine(
                id: documentRef.documentID,
                name: medicine.name,
                description: medicine.description,
                dosage: medicine.dosage,
                form: medicine.form,
                reference: medicine.reference,
                barcode: medicine.barcode,
                manufacturer: medicine.manufacturer,
                currentStock: medicine.currentStock,
                minimumStock: medicine.minimumStock,
                maximumStock: medicine.maximumStock,
                unitPrice: medicine.unitPrice,
                aisleId: medicine.aisleId,
                expiryDate: medicine.expiryDate,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            let newMedicineDTO = MedicineDTO.fromDomain(newMedicine)
            try await documentRef.setData(from: newMedicineDTO)
            return newMedicine
        } else {
            // Mettre à jour un médicament existant
            let updatedMedicine = Medicine(
                id: medicine.id,
                name: medicine.name,
                description: medicine.description,
                dosage: medicine.dosage,
                form: medicine.form,
                reference: medicine.reference,
                barcode: medicine.barcode,
                manufacturer: medicine.manufacturer,
                currentStock: medicine.currentStock,
                minimumStock: medicine.minimumStock,
                maximumStock: medicine.maximumStock,
                unitPrice: medicine.unitPrice,
                aisleId: medicine.aisleId,
                expiryDate: medicine.expiryDate,
                createdAt: medicine.createdAt,
                updatedAt: Date()
            )
            
            let updatedMedicineDTO = MedicineDTO.fromDomain(updatedMedicine)
            try await db.collection(collection).document(medicine.id).setData(from: updatedMedicineDTO)
            return updatedMedicine
        }
    }
    
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        let documentRef = db.collection(collection).document(id)
        
        try await documentRef.updateData([
            "currentStock": newStock,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        guard let updatedMedicine = try await getMedicine(id: id) else {
            throw NSError(domain: "MedicineRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Medicine not found after update"])
        }
        
        return updatedMedicine
    }
    
    func deleteMedicine(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
    
    // MARK: - Reactive Operations
    
    func observeMedicines() -> AnyPublisher<[Medicine], Error> {
        return Future { promise in
            let listener = self.db.collection(self.collection)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        promise(.failure(NSError(domain: "MedicineRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"])))
                        return
                    }
                    
                    let medicines = snapshot.documents.compactMap { document in
                        try? document.data(as: MedicineDTO.self).toDomain()
                    }
                    
                    promise(.success(medicines))
                }
            
            // Note: Dans une implémentation plus complète, nous devrions gérer la suppression du listener
        }
        .eraseToAnyPublisher()
    }
    
    func observeMedicine(id: String) -> AnyPublisher<Medicine?, Error> {
        return Future { promise in
            let listener = self.db.collection(self.collection).document(id)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        promise(.success(nil))
                        return
                    }
                    
                    if !snapshot.exists {
                        promise(.success(nil))
                        return
                    }
                    
                    do {
                        let medicineDTO = try snapshot.data(as: MedicineDTO.self)
                        let medicine = medicineDTO.toDomain()
                        promise(.success(medicine))
                    } catch {
                        promise(.failure(error))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
}