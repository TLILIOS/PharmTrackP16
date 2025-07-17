import Foundation

class RealGetUserUseCase: GetUserUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func execute() async throws -> User {
        guard let user = try await authRepository.getCurrentUser() else {
            throw AuthError.userNotFound
        }
        return user
    }
}