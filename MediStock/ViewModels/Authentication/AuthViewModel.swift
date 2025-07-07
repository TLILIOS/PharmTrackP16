import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Dependencies
    private let signInUseCase: SignInUseCaseProtocol
    private let signUpUseCase: SignUpUseCaseProtocol
    private let authRepository: AuthRepositoryProtocol
    
    // MARK: - State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    
    // Email/Password fields
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""
    
    // Password reset
    @Published var resetEmailSent = false
    
    // Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        signInUseCase: SignInUseCaseProtocol,
        signUpUseCase: SignUpUseCaseProtocol,
        authRepository: AuthRepositoryProtocol
    ) {
        self.signInUseCase = signInUseCase
        self.signUpUseCase = signUpUseCase
        self.authRepository = authRepository
        
        // Observer l'état d'authentification
        authRepository.authStateDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    @MainActor
    func signIn() async {
        guard validate(email: email, password: password) else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await signInUseCase.execute(email: email, password: password)
            resetFields()
        } catch {
            if let authError = error as? AuthError {
                errorMessage = authError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    @MainActor
    func signUp() async {
        guard validate(email: email, password: password) else { return }
        guard validateSignUp() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await signUpUseCase.execute(email: email, password: password, name: displayName)
            resetFields()
        } catch {
            if let authError = error as? AuthError {
                errorMessage = authError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authRepository.signOut()
        } catch {
            if let authError = error as? AuthError {
                errorMessage = authError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    @MainActor
    func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Veuillez entrer votre adresse e-mail."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authRepository.resetPassword(email: email)
            resetEmailSent = true
        } catch {
            if let authError = error as? AuthError {
                errorMessage = authError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func validate(email: String, password: String) -> Bool {
        guard !email.isEmpty else {
            errorMessage = "Veuillez entrer votre adresse e-mail."
            return false
        }
        
        guard !password.isEmpty else {
            errorMessage = "Veuillez entrer votre mot de passe."
            return false
        }
        
        return true
    }
    
    private func validateSignUp() -> Bool {
        guard password == confirmPassword else {
            errorMessage = "Les mots de passe ne correspondent pas."
            return false
        }
        
        guard password.count >= 6 else {
            errorMessage = "Le mot de passe doit contenir au moins 6 caractères."
            return false
        }
        
        return true
    }
    
    private func resetFields() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        errorMessage = nil
    }
}
