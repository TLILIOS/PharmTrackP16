import Foundation

// MARK: - Extension de HistoryEntry pour HistoryDataService
// Cette extension ajoute le support des metadata pour le nouveau HistoryDataService

struct HistoryEntryExtended: Identifiable, Codable, Hashable {
    let id: String
    let medicineId: String
    let userId: String
    let action: String
    let details: String
    let timestamp: Date
    let metadata: [String: String]?
    
    // Convertir vers le HistoryEntry de base
    var baseEntry: HistoryEntry {
        HistoryEntry(
            id: id,
            medicineId: medicineId,
            userId: userId,
            action: action,
            details: details,
            timestamp: timestamp
        )
    }
    
    // Créer depuis un HistoryEntry de base
    init(from entry: HistoryEntry, metadata: [String: String]? = nil) {
        self.id = entry.id
        self.medicineId = entry.medicineId
        self.userId = entry.userId
        self.action = entry.action
        self.details = entry.details
        self.timestamp = entry.timestamp
        self.metadata = metadata
    }
    
    // Init complet
    init(
        id: String,
        medicineId: String,
        userId: String,
        action: String,
        details: String,
        timestamp: Date,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.medicineId = medicineId
        self.userId = userId
        self.action = action
        self.details = details
        self.timestamp = timestamp
        self.metadata = metadata
    }
}