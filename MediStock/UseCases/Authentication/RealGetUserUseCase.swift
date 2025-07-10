import Foundation

class RealGetUserUseCase: GetUserUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func execute() async throws -> User {
        return try await authRepository.getCurrentUser()
    }
}