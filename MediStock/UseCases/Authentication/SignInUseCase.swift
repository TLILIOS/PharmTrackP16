import Foundation

class SignInUseCase: SignInUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func execute(email: String, password: String) async throws {
        try await authRepository.signIn(email: email, password: password)
    }
}