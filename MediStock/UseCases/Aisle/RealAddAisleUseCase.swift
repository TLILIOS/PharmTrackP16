import Foundation

class RealAddAisleUseCase: AddAisleUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    
    init(aisleRepository: AisleRepositoryProtocol) {
        self.aisleRepository = aisleRepository
    }
    
    func execute(aisle: Aisle) async throws {
        _ = try await aisleRepository.saveAisle(aisle)
    }
}