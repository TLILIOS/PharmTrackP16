import Foundation

class RealSearchMedicineUseCase: SearchMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol) {
        self.medicineRepository = medicineRepository
    }
    
    func execute(query: String) async throws -> [Medicine] {
        return try await medicineRepository.searchMedicines(query: query)
    }
}