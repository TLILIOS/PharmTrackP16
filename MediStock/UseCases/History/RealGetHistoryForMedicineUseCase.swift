import Foundation

class RealGetHistoryForMedicineUseCase: GetHistoryForMedicineUseCaseProtocol {
    private let historyRepository: HistoryRepositoryProtocol
    
    init(historyRepository: HistoryRepositoryProtocol) {
        self.historyRepository = historyRepository
    }
    
    func execute(medicineId: String) async throws -> [HistoryEntry] {
        guard !medicineId.isEmpty else {
            throw NSError(domain: "HistoryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Medicine ID cannot be empty"])
        }
        
        return try await historyRepository.getHistoryForMedicine(medicineId: medicineId)
    }
}