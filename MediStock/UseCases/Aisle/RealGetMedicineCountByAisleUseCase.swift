import Foundation

class RealGetMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    
    init(aisleRepository: AisleRepositoryProtocol) {
        self.aisleRepository = aisleRepository
    }
    
    func execute(aisleId: String) async throws -> Int {
        return try await aisleRepository.getMedicineCountByAisle(aisleId: aisleId)
    }
}