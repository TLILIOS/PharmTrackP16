import Foundation

class RealSearchAisleUseCase: SearchAisleUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    
    init(aisleRepository: AisleRepositoryProtocol) {
        self.aisleRepository = aisleRepository
    }
    
    func execute(query: String) async throws -> [Aisle] {
        return try await aisleRepository.searchAisles(query: query)
    }
}