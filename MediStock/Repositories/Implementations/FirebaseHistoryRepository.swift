import Foundation
import Firebase
import FirebaseFirestore
import Combine

class FirebaseHistoryRepository: HistoryRepositoryProtocol {
    private let db = Firestore.firestore()
    private let historyCollection = "history"
    
    // MARK: - HistoryRepositoryProtocol
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws -> HistoryEntry {
        do {
            let dto = HistoryEntryDTO.fromDomain(entry)
            let docRef: DocumentReference
            
            if let id = dto.id, !id.isEmpty {
                docRef = db.collection(historyCollection).document(id)
                try docRef.setData(from: dto)
            } else {
                docRef = try db.collection(historyCollection).addDocument(from: dto)
            }
            
            // Récupérer l'entrée mise à jour pour obtenir l'ID attribué
            let snapshot = try await docRef.getDocument()
            guard let historyDTO = try? snapshot.data(as: HistoryEntryDTO.self) else {
                throw MedicineError.invalidData
            }
            
            return historyDTO.toDomain()
        } catch {
            throw MedicineError.saveFailed
        }
    }
    
    func getHistoryForMedicine(medicineId: String) async throws -> [HistoryEntry] {
        do {
            let querySnapshot = try await db.collection(historyCollection)
                .whereField("medicineId", isEqualTo: medicineId)
                .order(by: "timestamp", descending: true)
                .getDocuments(source: .cache)
                
            if !querySnapshot.isEmpty {
                return querySnapshot.documents.compactMap { document in
                    try? document.data(as: HistoryEntryDTO.self).toDomain()
                }
            }
            
            let serverSnapshot = try await db.collection(historyCollection)
                .whereField("medicineId", isEqualTo: medicineId)
                .order(by: "timestamp", descending: true)
                .getDocuments(source: .server)
            
            return serverSnapshot.documents.compactMap { document in
                try? document.data(as: HistoryEntryDTO.self).toDomain()
            }
        } catch {
            throw MedicineError.unknownError(error)
        }
    }
    
    func getAllHistory() async throws -> [HistoryEntry] {
        do {
            let querySnapshot = try await db.collection(historyCollection)
                .order(by: "timestamp", descending: true)
                .getDocuments(source: .cache)
                
            if !querySnapshot.isEmpty {
                return querySnapshot.documents.compactMap { document in
                    try? document.data(as: HistoryEntryDTO.self).toDomain()
                }
            }
            
            let serverSnapshot = try await db.collection(historyCollection)
                .order(by: "timestamp", descending: true)
                .getDocuments(source: .server)
            
            return serverSnapshot.documents.compactMap { document in
                try? document.data(as: HistoryEntryDTO.self).toDomain()
            }
        } catch {
            throw MedicineError.unknownError(error)
        }
    }
    
    func getRecentHistory(limit: Int) async throws -> [HistoryEntry] {
        do {
            let querySnapshot = try await db.collection(historyCollection)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments(source: .cache)
                
            if !querySnapshot.isEmpty {
                return querySnapshot.documents.compactMap { document in
                    try? document.data(as: HistoryEntryDTO.self).toDomain()
                }
            }
            
            let serverSnapshot = try await db.collection(historyCollection)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments(source: .server)
            
            return serverSnapshot.documents.compactMap { document in
                try? document.data(as: HistoryEntryDTO.self).toDomain()
            }
        } catch {
            throw MedicineError.unknownError(error)
        }
    }
    
    func observeHistoryForMedicine(medicineId: String) -> AnyPublisher<[HistoryEntry], Error> {
        let publisher = PassthroughSubject<[HistoryEntry], Error>()
        
        db.collection(historyCollection)
            .whereField("medicineId", isEqualTo: medicineId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    publisher.send(completion: .failure(MedicineError.unknownError(error)))
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    publisher.send([])
                    return
                }
                
                let historyEntries = documents.compactMap { document -> HistoryEntry? in
                    try? document.data(as: HistoryEntryDTO.self).toDomain()
                }
                
                publisher.send(historyEntries)
            }
        
        return publisher.eraseToAnyPublisher()
    }
    
}
