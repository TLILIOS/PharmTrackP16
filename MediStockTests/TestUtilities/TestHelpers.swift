import Foundation
@testable import MediStock

// MARK: - Test Data Factory

struct TestDataFactory {
    
    static func createTestMedicine(
        id: String = "test-medicine-1",
        name: String = "Test Medicine",
        description: String = "Test Description",
        dosage: String = "500mg",
        form: String = "Tablet",
        reference: String = "TEST-001",
        unit: String = "tablet",
        currentQuantity: Int = 50,
        maxQuantity: Int = 100,
        warningThreshold: Int = 20,
        criticalThreshold: Int = 10,
        expiryDate: Date? = nil,
        aisleId: String = "test-aisle-1"
    ) -> Medicine {
        Medicine(
            id: id,
            name: name,
            description: description,
            dosage: dosage,
            form: form,
            reference: reference,
            unit: unit,
            currentQuantity: currentQuantity,
            maxQuantity: maxQuantity,
            warningThreshold: warningThreshold,
            criticalThreshold: criticalThreshold,
            expiryDate: expiryDate ?? Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            aisleId: aisleId,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static func createTestAisle(
        id: String = "test-aisle-1",
        name: String = "Test Aisle",
        description: String = "Test Aisle Description",
        colorHex: String = "#007AFF",
        icon: String = "pills"
    ) -> Aisle {
        Aisle(
            id: id,
            name: name,
            description: description,
            colorHex: colorHex,
            icon: icon
        )
    }
    
    static func createTestHistoryEntry(
        id: String = "test-history-1",
        medicineId: String = "test-medicine-1",
        userId: String = "test-user-1",
        action: String = "Test Action",
        details: String = "Test Details",
        timestamp: Date = Date()
    ) -> HistoryEntry {
        HistoryEntry(
            id: id,
            medicineId: medicineId,
            userId: userId,
            action: action,
            details: details,
            timestamp: timestamp
        )
    }
    
    static func createTestUser(
        id: String = "test-user-1",
        email: String = "test@example.com",
        displayName: String? = "Test User"
    ) -> User {
        User(
            id: id,
            email: email,
            displayName: displayName
        )
    }
    
    // MARK: - Bulk Test Data
    
    static func createMultipleMedicines(count: Int = 5) -> [Medicine] {
        (1...count).map { index in
            createTestMedicine(
                id: "test-medicine-\(index)",
                name: "Medicine \(index)",
                currentQuantity: Int.random(in: 0...100),
                aisleId: "test-aisle-\((index % 3) + 1)"
            )
        }
    }
    
    static func createMultipleAisles(count: Int = 3) -> [Aisle] {
        let colors = ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE"]
        let icons = ["pills", "cross.fill", "heart", "bandage", "syringe"]
        
        return (1...count).map { index in
            createTestAisle(
                id: "test-aisle-\(index)",
                name: "Aisle \(index)",
                colorHex: colors[index % colors.count],
                icon: icons[index % icons.count]
            )
        }
    }
    
    static func createMultipleHistoryEntries(count: Int = 10) -> [HistoryEntry] {
        let actions = ["Added", "Updated", "Stock Increased", "Stock Decreased", "Deleted"]
        
        return (1...count).map { index in
            createTestHistoryEntry(
                id: "test-history-\(index)",
                medicineId: "test-medicine-\((index % 5) + 1)",
                action: actions[index % actions.count],
                details: "Test action \(index)",
                timestamp: Calendar.current.date(byAdding: .hour, value: -index, to: Date()) ?? Date()
            )
        }
    }
    
    // MARK: - Scenario-based Test Data
    
    static func createLowStockMedicine() -> Medicine {
        createTestMedicine(
            id: "low-stock-medicine",
            name: "Low Stock Medicine",
            currentQuantity: 5,
            warningThreshold: 20,
            criticalThreshold: 10
        )
    }
    
    static func createCriticalStockMedicine() -> Medicine {
        createTestMedicine(
            id: "critical-stock-medicine",
            name: "Critical Stock Medicine",
            currentQuantity: 2,
            warningThreshold: 20,
            criticalThreshold: 10
        )
    }
    
    static func createExpiredMedicine() -> Medicine {
        createTestMedicine(
            id: "expired-medicine",
            name: "Expired Medicine",
            expiryDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())
        )
    }
    
    static func createExpiringSoonMedicine() -> Medicine {
        createTestMedicine(
            id: "expiring-soon-medicine",
            name: "Expiring Soon Medicine",
            expiryDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())
        )
    }
    
    static func createFullStockMedicine() -> Medicine {
        createTestMedicine(
            id: "full-stock-medicine",
            name: "Full Stock Medicine",
            currentQuantity: 100,
            maxQuantity: 100
        )
    }
}

// MARK: - Test Assertion Helpers

extension Medicine {
    var isLowStock: Bool {
        currentQuantity <= warningThreshold && currentQuantity > criticalThreshold
    }
    
    var isCriticalStock: Bool {
        currentQuantity <= criticalThreshold
    }
    
    var isExpiringSoon: Bool {
        guard let expiryDate = expiryDate else { return false }
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expiryDate <= thirtyDaysFromNow
    }
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return expiryDate <= Date()
    }
}

// MARK: - Test Expectations

public struct TestExpectations {
    public static let defaultTimeout: TimeInterval = 2.0
    public static let longTimeout: TimeInterval = 5.0
}