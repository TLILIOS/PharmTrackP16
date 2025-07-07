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
                try await docRef.setData(from: dto)
            } else {
                docRef = try await db.collection(historyCollection).addDocument(from: dto)
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
                .getDocuments()
            
            return querySnapshot.documents.compactMap { document in
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
                .getDocuments()
            
            return querySnapshot.documents.compactMap { document in
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
    
    func exportHistory(format: String, medicineId: String?) async throws -> Data {
        // Récupérer les données de l'historique
        let historyEntries: [HistoryEntry]
        
        if let medicineId = medicineId {
            historyEntries = try await getHistoryForMedicine(medicineId: medicineId)
        } else {
            historyEntries = try await getAllHistory()
        }
        
        // Exporter selon le format demandé
        switch format.lowercased() {
        case "csv":
            return try exportToCSV(historyEntries: historyEntries)
        case "json":
            return try exportToJSON(historyEntries: historyEntries)
        default:
            throw ExportError.unsupportedFormat
        }
    }
    
    // MARK: - Private Methods
    
    private func exportToCSV(historyEntries: [HistoryEntry]) throws -> Data {
        var csvString = "ID,MedicineID,UserID,Action,Details,Timestamp\n"
        
        for entry in historyEntries {
            let timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
            let row = "\"\(entry.id)\",\"\(entry.medicineId)\",\"\(entry.userId)\",\"\(entry.action)\",\"\(entry.details)\",\"\(timestamp)\"\n"
            csvString.append(row)
        }
        
        guard let data = csvString.data(using: .utf8) else {
            throw ExportError.conversionFailed
        }
        
        return data
    }
    
    private func exportToJSON(historyEntries: [HistoryEntry]) throws -> Data {
        struct HistoryEntryExport: Codable {
            let id: String
            let medicineId: String
            let userId: String
            let action: String
            let details: String
            let timestamp: String
        }
        
        let exportEntries = historyEntries.map { entry in
            HistoryEntryExport(
                id: entry.id,
                medicineId: entry.medicineId,
                userId: entry.userId,
                action: entry.action,
                details: entry.details,
                timestamp: ISO8601DateFormatter().string(from: entry.timestamp)
            )
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            return try encoder.encode(exportEntries)
        } catch {
            throw ExportError.conversionFailed
        }
    }
}
