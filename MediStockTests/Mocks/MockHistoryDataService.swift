import Foundation
@testable import MediStock

// MARK: - Mock History Data Service pour les tests unitaires
/// Mock qui simule HistoryDataService sans dépendre de Firebase

final class MockHistoryDataService {
    // MARK: - In-Memory Storage

    var history: [HistoryEntry] = []

    // MARK: - Test Configuration

    var shouldFailGetHistory = false
    var shouldFailRecordAction = false
    var shouldFailCleanOldHistory = false

    var getHistoryCallCount = 0
    var recordMedicineActionCallCount = 0
    var recordAisleActionCallCount = 0
    var recordStockAdjustmentCallCount = 0
    var recordDeletionCallCount = 0
    var cleanOldHistoryCallCount = 0
    var getHistoryStatsCallCount = 0

    // MARK: - Errors

    enum MockDataError: LocalizedError {
        case operationFailed
        case networkError

        var errorDescription: String? {
            switch self {
            case .operationFailed: return "Mock operation failed"
            case .networkError: return "Network error occurred"
            }
        }
    }

    // MARK: - Public Methods

    func getHistory(
        medicineId: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 100
    ) async throws -> [HistoryEntry] {
        getHistoryCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

        guard !shouldFailGetHistory else {
            throw MockDataError.operationFailed
        }

        var filtered = history

        // Apply filters
        if let medicineId = medicineId {
            filtered = filtered.filter { $0.medicineId == medicineId }
        }

        if let startDate = startDate {
            filtered = filtered.filter { $0.timestamp >= startDate }
        }

        if let endDate = endDate {
            filtered = filtered.filter { $0.timestamp <= endDate }
        }

        // Sort by timestamp descending and limit
        return Array(filtered.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }

    func recordMedicineAction(
        medicineId: String,
        medicineName: String,
        action: String,
        details: String
    ) async throws {
        recordMedicineActionCallCount += 1

        guard !shouldFailRecordAction else {
            throw MockDataError.operationFailed
        }

        let entry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: "mock-user-id",
            action: action,
            details: details,
            timestamp: Date()
        )

        history.append(entry)
    }

    func recordAisleAction(
        aisleId: String,
        aisleName: String,
        action: String,
        details: String
    ) async throws {
        recordAisleActionCallCount += 1

        guard !shouldFailRecordAction else {
            throw MockDataError.operationFailed
        }

        let entry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: "", // No medicine associated
            userId: "mock-user-id",
            action: action,
            details: details,
            timestamp: Date()
        )

        history.append(entry)
    }

    func recordStockAdjustment(
        medicineId: String,
        medicineName: String,
        adjustment: Int,
        newStock: Int,
        details: String
    ) async throws {
        recordStockAdjustmentCallCount += 1

        guard !shouldFailRecordAction else {
            throw MockDataError.operationFailed
        }

        let entry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: "mock-user-id",
            action: "Ajustement stock",
            details: details,
            timestamp: Date()
        )

        history.append(entry)
    }

    func recordDeletion(
        itemType: String,
        itemId: String,
        itemName: String,
        details: String
    ) async throws {
        recordDeletionCallCount += 1

        guard !shouldFailRecordAction else {
            throw MockDataError.operationFailed
        }

        let entry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: itemType == "medicine" ? itemId : "",
            userId: "mock-user-id",
            action: "Suppression",
            details: details,
            timestamp: Date()
        )

        history.append(entry)
    }

    func cleanOldHistory(olderThan date: Date) async throws {
        cleanOldHistoryCallCount += 1

        guard !shouldFailCleanOldHistory else {
            throw MockDataError.operationFailed
        }

        history.removeAll { $0.timestamp < date }
    }

    // MARK: - Statistics

    struct HistoryStats {
        let totalActions: Int
        let actionsByType: [String: Int]
        let recentActivity: [Date: Int]
    }

    func getHistoryStats(days: Int = 30) async throws -> HistoryStats {
        getHistoryStatsCallCount += 1

        guard !shouldFailGetHistory else {
            throw MockDataError.operationFailed
        }

        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let recentEntries = history.filter { $0.timestamp >= startDate }

        // Calculate statistics
        var actionsByType: [String: Int] = [:]
        var recentActivity: [Date: Int] = [:]

        for entry in recentEntries {
            // Actions by type
            actionsByType[entry.action, default: 0] += 1

            // Activity by day
            let dayStart = Calendar.current.startOfDay(for: entry.timestamp)
            recentActivity[dayStart, default: 0] += 1
        }

        return HistoryStats(
            totalActions: recentEntries.count,
            actionsByType: actionsByType,
            recentActivity: recentActivity
        )
    }

    // MARK: - Test Helpers

    /// Réinitialise toutes les données et compteurs
    func reset() {
        history = []
        shouldFailGetHistory = false
        shouldFailRecordAction = false
        shouldFailCleanOldHistory = false
        getHistoryCallCount = 0
        recordMedicineActionCallCount = 0
        recordAisleActionCallCount = 0
        recordStockAdjustmentCallCount = 0
        recordDeletionCallCount = 0
        cleanOldHistoryCallCount = 0
        getHistoryStatsCallCount = 0
    }

    /// Ajoute des données de test
    func seedTestData() {
        history = [
            HistoryEntry(
                id: "history-1",
                medicineId: "med-1",
                userId: "mock-user-id",
                action: "Création",
                details: "Ajout du médicament Doliprane 500mg avec un stock initial de 100",
                timestamp: Date().addingTimeInterval(-3600) // 1 hour ago
            ),
            HistoryEntry(
                id: "history-2",
                medicineId: "med-1",
                userId: "mock-user-id",
                action: "Mise à jour stock",
                details: "Stock mis à jour: 75",
                timestamp: Date().addingTimeInterval(-1800) // 30 minutes ago
            )
        ]
    }

    /// Configure les erreurs pour tester les cas d'échec
    func configureFailures(
        getHistory: Bool = false,
        recordAction: Bool = false,
        cleanOldHistory: Bool = false
    ) {
        shouldFailGetHistory = getHistory
        shouldFailRecordAction = recordAction
        shouldFailCleanOldHistory = cleanOldHistory
    }
}
