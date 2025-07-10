import Foundation

class RealAddMedicineUseCase: AddMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol, historyRepository: HistoryRepositoryProtocol) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
    }
    
    func execute(medicine: Medicine) async throws {
        _ = try await medicineRepository.saveMedicine(medicine)
    }
}