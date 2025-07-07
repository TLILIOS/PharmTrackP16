import Foundation

class RealGetAislesUseCase: GetAislesUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    
    init(aisleRepository: AisleRepositoryProtocol) {
        self.aisleRepository = aisleRepository
    }
    
    func execute() async throws -> [Aisle] {
        return try await aisleRepository.getAisles()
    }
}