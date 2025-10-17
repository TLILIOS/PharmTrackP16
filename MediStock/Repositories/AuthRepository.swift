import Foundation
import Combine

// MARK: - Auth Repository

@MainActor
class AuthRepository: AuthRepositoryProtocol {
    private let authService: any AuthServiceProtocol
    @Published private var currentUser: User?

    var currentUserPublisher: Published<User?>.Publisher {
        $currentUser
    }

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
        setupObservers()
    }

    convenience init() {
        self.init(authService: FirebaseAuthService())
    }
    
    private func setupObservers() {
        authService.currentUserPublisher
            .assign(to: &$currentUser)
    }
    
    @MainActor
    static func createDefault() -> AuthRepository {
        return AuthRepository(authService: FirebaseAuthService())
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
