import Foundation

struct Medicine: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let dosage: String?
    let form: String?
    let reference: String?
    let unit: String
    let currentQuantity: Int
    let maxQuantity: Int
    let warningThreshold: Int
    let criticalThreshold: Int
    let expiryDate: Date?
    let aisleId: String
    let createdAt: Date
    let updatedAt: Date
    
    var stockStatus: StockStatus {
        if currentQuantity <= criticalThreshold {
            return .critical
        } else if currentQuantity <= warningThreshold {
            return .warning
        } else {
            return .normal
        }
    }
    
    var isExpiringSoon: Bool {
        guard let expiryDate = expiryDate else { return false }
        let calendar = Calendar.current
        let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expiryDate <= thirtyDaysFromNow
    }
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return expiryDate <= Date()
    }
    
    // Legacy compatibility with Firebase model
    var stock: Int { currentQuantity }
    var aisle: String { aisleId }
}

enum StockStatus: String, CaseIterable {
    case normal = "normal"
    case warning = "warning"
    case critical = "critical"
}

enum ExpiryStatus: String, CaseIterable {
    case good = "good"
    case soon = "soon"
    case expired = "expired"
}