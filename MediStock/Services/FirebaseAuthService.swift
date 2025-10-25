import Foundation
import FirebaseAuth
import Combine

// MARK: - Service d'authentification Firebase

@MainActor
class FirebaseAuthService: AuthServiceProtocol {
    @Published var currentUser: User?

    var currentUserPublisher: AnyPublisher<User?, Never> {
        $currentUser.eraseToAnyPublisher()
    }

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let keychain = KeychainService.shared

    init() {
        // Observer les changements d'état d'authentification
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            self?.currentUser = firebaseUser.map { user in
                User(
                    id: user.uid,
                    email: user.email,
                    displayName: user.displayName
                )
            }

            // Gérer le token d'authentification
            if let firebaseUser = firebaseUser {
                Task {
                    do {
                        let token = try await firebaseUser.getIDToken()
                        try self?.keychain.saveAuthToken(token)
                    } catch {
                        print("Erreur lors de la sauvegarde du token: \(error)")
                    }
                }
            } else {
                self?.keychain.deleteAuthToken()
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Méthodes d'authentification

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        currentUser = User(
            id: result.user.uid,
            email: result.user.email,
            displayName: result.user.displayName
        )
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        // Mettre à jour le profil
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        currentUser = User(
            id: result.user.uid,
            email: result.user.email,
            displayName: displayName
        )
    }

    func signOut() async throws {
        try Auth.auth().signOut()
        currentUser = nil
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func getAuthToken() async throws -> String? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        return try await firebaseUser.getIDToken()
    }
}

// MARK: - Rétrocompatibilité

/// Typealias pour maintenir la compatibilité avec le code existant
typealias AuthService = FirebaseAuthService
