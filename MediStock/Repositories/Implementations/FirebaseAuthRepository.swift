import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseAuthRepository: AuthRepositoryProtocol {
    // MARK: - Properties
    private let auth = Auth.auth()
    private var authStateSubject = CurrentValueSubject<User?, Never>(nil)
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - AuthRepositoryProtocol Properties
    var currentUser: User? {
        if let firebaseUser = auth.currentUser {
            return User(
                id: firebaseUser.uid,
                email: firebaseUser.email,
                displayName: firebaseUser.displayName
            )
        }
        return nil
    }
    
    var authStateDidChange: AnyPublisher<User?, Never> {
        return authStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Private Methods
    private func setupAuthStateListener() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] (_, firebaseUser) in
            guard let self = self else { return }
            
            if let firebaseUser = firebaseUser {
                let user = User(
                    id: firebaseUser.uid,
                    email: firebaseUser.email,
                    displayName: firebaseUser.displayName
                )
                self.authStateSubject.send(user)
            } else {
                self.authStateSubject.send(nil)
            }
        }
    }
    
        // Testing helper method
    func mapFirebaseErrorForTesting(_ error: Error) -> AuthError {
        return mapFirebaseError(error)
    }

private func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        let authErrorCode = AuthErrorCode(_bridgedNSError: nsError)
        
        switch authErrorCode?.code {
        case .invalidEmail:
            return .invalidEmail
        case .wrongPassword:
            return .wrongPassword
        case .userNotFound:
            return .userNotFound
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkError
        default:
            return .unknownError(error)
        }
    }
    
    // MARK: - AuthRepositoryProtocol Methods
    func signIn(email: String, password: String) async throws -> User {
        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            return User(
                id: authResult.user.uid,
                email: authResult.user.email,
                displayName: authResult.user.displayName
            )
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    func signUp(email: String, password: String) async throws -> User {
        do {
            let authResult = try await auth.createUser(withEmail: email, password: password)
            return User(
                id: authResult.user.uid,
                email: authResult.user.email,
                displayName: authResult.user.displayName
            )
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    func signUpWithName(email: String, password: String, displayName: String) async throws -> User {
        do {
            let authResult = try await auth.createUser(withEmail: email, password: password)
            
            // Mettre à jour le profil avec le nom
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            return User(
                id: authResult.user.uid,
                email: authResult.user.email,
                displayName: displayName
            )
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    func signOut() async throws {
        do {
            try auth.signOut()
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    func updateUserProfile(user: User) async throws {
        guard let currentFirebaseUser = auth.currentUser else {
            throw AuthError.userNotFound
        }
        
        let changeRequest = currentFirebaseUser.createProfileChangeRequest()
        
        if let displayName = user.displayName {
            changeRequest.displayName = displayName
        }
        
        do {
            try await changeRequest.commitChanges()
            // Mettre à jour d'autres informations si nécessaire dans Firestore
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    func getCurrentUser() async throws -> User? {
        return currentUser
    }
}
