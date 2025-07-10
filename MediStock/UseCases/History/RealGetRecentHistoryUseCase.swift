import Foundation

class RealGetRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol {
    private let historyRepository: HistoryRepositoryProtocol
    
    init(historyRepository: HistoryRepositoryProtocol) {
        self.historyRepository = historyRepository
    }
    
    func execute(limit: Int) async throws -> [HistoryEntry] {
        return try await historyRepository.getRecentHistory(limit: limit)
    }
}