import Foundation

class RealGetHistoryUseCase: GetHistoryUseCaseProtocol {
    private let historyRepository: HistoryRepositoryProtocol
    
    init(historyRepository: HistoryRepositoryProtocol) {
        self.historyRepository = historyRepository
    }
    
    func execute() async throws -> [HistoryEntry] {
        return try await historyRepository.getAllHistory()
    }
}