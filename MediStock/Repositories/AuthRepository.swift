import Foundation
import Combine

// MARK: - Auth Repository

@MainActor
class AuthRepository: AuthRepositoryProtocol {
    private let authService: AuthService
    @Published private var currentUser: User?
    
    var currentUserPublisher: Published<User?>.Publisher {
        $currentUser
    }
    
    nonisolated init(authService: AuthService) {
        self.authService = authService
        
        // Observer l'état d'authentification
        Task { @MainActor [weak self] in
            self?.setupObservers()
        }
    }
    
    private func setupObservers() {
        authService.$currentUser
            .assign(to: &$currentUser)
    }
    
    @MainActor
    static func createDefault() -> AuthRepository {
        return AuthRepository(authService: AuthService())
    }
    
    func signIn(email: String, password: String) async throws {
        try await authService.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        try await authService.signUp(email: email, password: password, displayName: displayName)
    }
    
    func signOut() async throws {
        try await authService.signOut()
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
}
