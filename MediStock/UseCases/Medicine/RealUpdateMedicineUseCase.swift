import Foundation

class RealUpdateMedicineUseCase: UpdateMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol) {
        self.medicineRepository = medicineRepository
    }
    
    func execute(medicine: Medicine) async throws {
        _ = try await medicineRepository.saveMedicine(medicine)
    }
}