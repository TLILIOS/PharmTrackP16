import Foundation

class RealDeleteAisleUseCase: DeleteAisleUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    
    init(aisleRepository: AisleRepositoryProtocol) {
        self.aisleRepository = aisleRepository
    }
    
    func execute(id: String) async throws {
        try await aisleRepository.deleteAisle(id: id)
    }
}