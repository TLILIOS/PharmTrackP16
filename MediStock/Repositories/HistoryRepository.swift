import Foundation

// MARK: - History Repository

class HistoryRepository: HistoryRepositoryProtocol {
    func fetchHistoryForMedicine(_ medicineId: String) async throws -> [HistoryEntry] {
        return try await dataService.getHistory(for: medicineId)
    }
    
    private let dataService: DataServiceAdapter
    
    init(dataService: DataServiceAdapter = DataServiceAdapter()) {
        self.dataService = dataService
    }
    
    func fetchHistory() async throws -> [HistoryEntry] {
        return try await dataService.getHistory()
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        try await dataService.addHistoryEntry(entry)
    }
}
