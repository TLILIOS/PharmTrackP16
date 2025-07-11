import Foundation

struct HistoryEntry: Identifiable, Codable, Hashable {
    let id: String
    let medicineId: String
    let userId: String
    let action: String
    let details: String
    let timestamp: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
