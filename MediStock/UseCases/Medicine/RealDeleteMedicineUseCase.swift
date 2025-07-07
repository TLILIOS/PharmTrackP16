import Foundation

class RealDeleteMedicineUseCase: DeleteMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol) {
        self.medicineRepository = medicineRepository
    }
    
    func execute(id: String) async throws {
        try await medicineRepository.deleteMedicine(id: id)
    }
}