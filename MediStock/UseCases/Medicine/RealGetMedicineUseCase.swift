import Foundation

class RealGetMedicineUseCase: GetMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol) {
        self.medicineRepository = medicineRepository
    }
    
    func execute(id: String) async throws -> Medicine {
        guard let medicine = try await medicineRepository.getMedicine(id: id) else {
            throw NSError(domain: "MedicineUseCase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Medicine not found"])
        }
        return medicine
    }
}