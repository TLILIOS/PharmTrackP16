import Foundation

class SignUpUseCase: SignUpUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func execute(email: String, password: String, name: String) async throws {
        // Use signUpWithName if name is provided, otherwise use regular signUp
        if !name.isEmpty {
            _ = try await authRepository.signUpWithName(email: email, password: password, displayName: name)
        } else {
            _ = try await authRepository.signUp(email: email, password: password)
        }
    }
}