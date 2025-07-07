import Foundation

class UpdateMedicineStockUseCase: UpdateMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol, historyRepository: HistoryRepositoryProtocol) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
    }
    
    func execute(medicine: Medicine) async throws {
        
    }
}
