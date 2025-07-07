import Foundation

class SignUpUseCase: SignUpUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func execute(email: String, password: String, name: String) async throws {
        let user = try await authRepository.signUp(email: email, password: password)
        
        // Update user profile with display name if provided
        if !name.isEmpty {
            let updatedUser = User(
                id: user.id,
                email: user.email,
                displayName: name
            )
            try await authRepository.updateUserProfile(user: updatedUser)
        }
    }
}