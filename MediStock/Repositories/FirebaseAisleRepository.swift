import Foundation
import Firebase
import FirebaseFirestore
import Combine

class FirebaseAisleRepository: AisleRepositoryProtocol {
    private let db = Firestore.firestore()
    private let collection = "aisles"
    private let medicinesCollection = "medicines"
    
    // MARK: - Basic CRUD Operations
    
    func getAisles() async throws -> [Aisle] {
        let snapshot = try await db.collection(collection).getDocuments(source: .cache)
        
        if !snapshot.isEmpty {
            return snapshot.documents.compactMap { document in
                try? document.data(as: AisleDTO.self).toDomain()
            }
        }
        
        let serverSnapshot = try await db.collection(collection).getDocuments(source: .server)
        return serverSnapshot.documents.compactMap { document in
            try? document.data(as: AisleDTO.self).toDomain()
        }
    }
    
    func getAisle(id: String) async throws -> Aisle? {
        // Validation de l'ID
        guard !id.isEmpty else {
            return nil
        }
        
        let document = try await db.collection(collection).document(id).getDocument(source: .cache)
        
        if document.exists, let aisleDTO = try? document.data(as: AisleDTO.self) {
            return aisleDTO.toDomain()
        }
        
        let serverDocument = try await db.collection(collection).document(id).getDocument(source: .server)
        guard serverDocument.exists,
              let aisleDTO = try? serverDocument.data(as: AisleDTO.self) else {
            return nil
        }
        
        return aisleDTO.toDomain()
    }
    
    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        let _ = AisleDTO.fromDomain(aisle)
        
        if aisle.id.isEmpty {
            // Créer un nouveau rayon avec un ID généré
            let documentRef = db.collection(collection).document()
            let newAisle = Aisle(
                 id: documentRef.documentID,
                 name: aisle.name,
                 description: aisle.description,
                 colorHex: aisle.colorHex,
                 icon: aisle.icon
             )

            
            let newAisleDTO = AisleDTO.fromDomain(newAisle)
            try documentRef.setData(from: newAisleDTO)
            return newAisle
        } else {
            // Mettre à jour un rayon existant
            let updatedAisle = Aisle(
                  id: aisle.id,
                  name: aisle.name,
                  description: aisle.description,
                  colorHex: aisle.colorHex,
                  icon: aisle.icon
              )

            
            let updatedAisleDTO = AisleDTO.fromDomain(updatedAisle)
            try db.collection(collection).document(aisle.id).setData(from: updatedAisleDTO)
            return updatedAisle
        }
    }
    
    func deleteAisle(id: String) async throws {
        // Validation de l'ID
        guard !id.isEmpty else {
            throw NSError(
                domain: "AisleRepository",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Cannot delete aisle: ID cannot be empty"]
            )
        }
        
        // Vérifier s'il y a des médicaments dans ce rayon
        let medicinesInAisle = try await db.collection(medicinesCollection)
            .whereField("aisleId", isEqualTo: id)
            .getDocuments()
        
        if !medicinesInAisle.documents.isEmpty {
            throw NSError(
                domain: "AisleRepository",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Cannot delete aisle: it contains medicines"]
            )
        }
        
        try await db.collection(collection).document(id).delete()
    }
    
    func getMedicineCountByAisle(aisleId: String) async throws -> Int {
        // Validation de l'ID
        guard !aisleId.isEmpty else {
            return 0
        }
        
        let snapshot = try await db.collection(medicinesCollection)
            .whereField("aisleId", isEqualTo: aisleId)
            .getDocuments(source: .cache)
            
        if !snapshot.isEmpty {
            return snapshot.documents.count
        }
        
        let serverSnapshot = try await db.collection(medicinesCollection)
            .whereField("aisleId", isEqualTo: aisleId)
            .getDocuments(source: .server)
        
        return serverSnapshot.documents.count
    }
    
    // MARK: - Reactive Operations
    
    func observeAisles() -> AnyPublisher<[Aisle], Error> {
        return Future { promise in
            let _ = self.db.collection(self.collection)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        promise(.failure(NSError(domain: "AisleRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"])))
                        return
                    }
                    
                    let aisles = snapshot.documents.compactMap { document in
                        try? document.data(as: AisleDTO.self).toDomain()
                    }
                    
                    promise(.success(aisles))
                }
        }
        .eraseToAnyPublisher()
    }
    
    func observeAisle(id: String) -> AnyPublisher<Aisle?, Error> {
        // Validation de l'ID
        guard !id.isEmpty else {
            return Just(nil)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return Future { promise in
            let _ = self.db.collection(self.collection).document(id)
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
                        let aisleDTO = try snapshot.data(as: AisleDTO.self)
                        let aisle = aisleDTO.toDomain()
                        promise(.success(aisle))
                    } catch {
                        promise(.failure(error))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
}
