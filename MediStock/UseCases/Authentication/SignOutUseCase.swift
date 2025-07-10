import Foundation

public class SignOutUseCase: SignOutUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    public func execute() async throws {
        try await authRepository.signOut()
    }
}