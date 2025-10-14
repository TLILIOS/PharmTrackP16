import Foundation

// MARK: - History Repository

class HistoryRepository: HistoryRepositoryProtocol {
    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol = FirebaseDataService()) {
        self.dataService = dataService
    }

    func fetchHistoryForMedicine(_ medicineId: String) async throws -> [HistoryEntry] {
        // Note: DataServiceProtocol getHistory() returns all history
        // We filter client-side for specific medicineId
        let allHistory = try await dataService.getHistory()
        return allHistory.filter { $0.medicineId == medicineId }
    }
    
    func fetchHistory() async throws -> [HistoryEntry] {
        return try await dataService.getHistory()
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        try await dataService.addHistoryEntry(entry)
    }
}
