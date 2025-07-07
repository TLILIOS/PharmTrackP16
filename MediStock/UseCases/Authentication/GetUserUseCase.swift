import Foundation

class GetUserUseCase: GetUserUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func execute() async throws -> User {
        guard let currentUser = authRepository.currentUser else {
            throw AuthError.userNotFound
        }
        return currentUser
    }
}