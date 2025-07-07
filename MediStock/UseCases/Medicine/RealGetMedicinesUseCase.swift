import Foundation

class RealGetMedicinesUseCase: GetMedicinesUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol) {
        self.medicineRepository = medicineRepository
    }
    
    func execute() async throws -> [Medicine] {
        return try await medicineRepository.getMedicines()
    }
}