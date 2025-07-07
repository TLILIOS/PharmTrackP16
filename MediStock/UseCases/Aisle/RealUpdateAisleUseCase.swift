import Foundation

class RealUpdateAisleUseCase: UpdateAisleUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    
    init(aisleRepository: AisleRepositoryProtocol) {
        self.aisleRepository = aisleRepository
    }
    
    func execute(aisle: Aisle) async throws {
        _ = try await aisleRepository.saveAisle(aisle)
    }
}