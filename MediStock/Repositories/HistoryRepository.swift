import Foundation

// MARK: - History Repository

class HistoryRepository: HistoryRepositoryProtocol {
    func fetchHistoryForMedicine(_ medicineId: String) async throws -> [HistoryEntry] {
        return [HistoryEntry]()
    }
    
    private let dataService: DataServiceRefactored
    
    init(dataService: DataServiceRefactored = DataServiceRefactored()) {
        self.dataService = dataService
    }
    
    func fetchHistory() async throws -> [HistoryEntry] {
        return try await dataService.getHistory()
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        try await dataService.addHistoryEntry(entry)
    }
}
