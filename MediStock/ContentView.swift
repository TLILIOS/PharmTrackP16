import SwiftUI
import Combine
import Foundation

struct ContentView: View {
    @StateObject private var session: SessionStore
    
    // Shared auth repository instance
    private static let sharedAuthRepository = FirebaseAuthRepository()
    
    @StateObject private var authViewModel: AuthViewModel = {
        let authRepository = ContentView.sharedAuthRepository
        let signInUseCase = SignInUseCase(authRepository: authRepository)
        let signUpUseCase = SignUpUseCase(authRepository: authRepository)
        return AuthViewModel(
            signInUseCase: signInUseCase,
            signUpUseCase: signUpUseCase,
            authRepository: authRepository
        )
    }()
    
    init() {
        self._session = StateObject(wrappedValue: SessionStore(authRepository: ContentView.sharedAuthRepository))
    }

    var body: some View {
        ZStack {
            if session.session != nil {
                MainTabView()
            } else {
                LoginView(authViewModel: authViewModel)
            }
        }
        .onAppear {
            session.listen()
        }
    }
}

// MARK: - Mock Classes for ContentView
class MockSignInUseCase: SignInUseCaseProtocol {
    func execute(email: String, password: String) async throws {}
}

class MockSignUpUseCase: SignUpUseCaseProtocol {
    func execute(email: String, password: String, name: String) async throws {}
}

class MockAuthRepository: AuthRepositoryProtocol {
    var currentUser: User? = nil
    
    var authStateDidChange: AnyPublisher<User?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }
    
    func signIn(email: String, password: String) async throws -> User {
        return User(id: "mock-user", email: email, displayName: "Mock User")
    }
    
    func signUp(email: String, password: String) async throws -> User {
        return User(id: "mock-user", email: email, displayName: "Mock User")
    }
    
    func signUpWithName(email: String, password: String, displayName: String) async throws -> User {
        return User(id: "mock-user", email: email, displayName: displayName)
    }
    
    func signOut() async throws {}
    func resetPassword(email: String) async throws {}
    func updateUserProfile(user: User) async throws {}
    
    func getCurrentUser() async throws -> User? {
        return currentUser
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
