import Foundation
import SwiftUI
import Combine

// MARK: - Auth ViewModel

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    private let repository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: AuthRepositoryProtocol) {
        self.repository = repository

        // Synchroniser l'état initial
        self.currentUser = repository.getCurrentUser()
        self.isAuthenticated = self.currentUser != nil

        // Observer l'état d'authentification
        repository.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
            .store(in: &cancellables)
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.signIn(email: email, password: password)
            // Synchroniser immédiatement après l'authentification
            currentUser = repository.getCurrentUser()
            isAuthenticated = currentUser != nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.signUp(email: email, password: password, displayName: displayName)
            // Synchroniser immédiatement après l'authentification
            currentUser = repository.getCurrentUser()
            isAuthenticated = currentUser != nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func signOut() async {
        do {
            try await repository.signOut()
            // Synchroniser immédiatement après la déconnexion
            currentUser = repository.getCurrentUser()
            isAuthenticated = currentUser != nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
