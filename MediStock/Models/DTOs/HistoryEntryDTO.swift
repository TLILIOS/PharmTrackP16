import Foundation
import FirebaseFirestore

struct HistoryEntryDTO: Codable {
    @DocumentID var id: String?
    var medicineId: String
    var userId: String
    var action: String
    var details: String
    var timestamp: Date
    
    func toDomain() -> HistoryEntry {
        return HistoryEntry(
            id: id ?? UUID().uuidString,
            medicineId: medicineId,
            userId: userId,
            action: action,
            details: details,
            timestamp: timestamp
        )
    }
    
    static func fromDomain(_ historyEntry: HistoryEntry) -> HistoryEntryDTO {
        return HistoryEntryDTO(
            id: historyEntry.id,
            medicineId: historyEntry.medicineId,
            userId: historyEntry.userId,
            action: historyEntry.action,
            details: historyEntry.details,
            timestamp: historyEntry.timestamp
        )
    }
}
