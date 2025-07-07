import Foundation

struct HistoryEntry: Identifiable, Codable {
    let id: String
    let medicineId: String
    let userId: String
    let action: String
    let details: String
    let timestamp: Date
}
