import Foundation
import Firebase
import FirebaseAuth
import Combine
@testable import MediStock

// MARK: - Mock Firebase Auth Components

class MockFirebaseUser: NSObject {
    let uid: String
    let email: String?
    let displayName: String?
    
    init(uid: String, email: String?, displayName: String?) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        super.init()
    }
}

class MockAuth {
    static let shared = MockAuth()
    
    private(set) var currentUser: MockFirebaseUser?
    private var authStateDidChangeCallbacks: [(MockFirebaseUser?) -> Void] = []
    private var shouldSucceed = true
    private var errorToThrow: Error?
    
    // Configuration methods for tests
    func setCurrentUser(_ user: MockFirebaseUser?) {
        currentUser = user
        notifyAuthStateChanged()
    }
    
    func setShouldSucceed(_ shouldSucceed: Bool) {
        self.shouldSucceed = shouldSucceed
    }
    
    func setErrorToThrow(_ error: Error?) {
        self.errorToThrow = error
    }
    
    func reset() {
        currentUser = nil
        authStateDidChangeCallbacks.removeAll()
        shouldSucceed = true
        errorToThrow = nil
    }
    
    // Mock Firebase Auth methods
    func signIn(withEmail email: String, password: String) async throws -> MockFirebaseUser {
        if !shouldSucceed {
            throw errorToThrow ?? createAuthError(.wrongPassword)
        }
        
        if email.isEmpty {
            throw createAuthError(.invalidEmail)
        }
        
        if password.isEmpty {
            throw createAuthError(.wrongPassword)
        }
        
        let user = MockFirebaseUser(uid: "mock-uid", email: email, displayName: nil)
        setCurrentUser(user)
        return user
    }
    
    func createUser(withEmail email: String, password: String) async throws -> MockFirebaseUser {
        if !shouldSucceed {
            throw errorToThrow ?? createAuthError(.emailAlreadyInUse)
        }
        
        if email.isEmpty {
            throw createAuthError(.invalidEmail)
        }
        
        if password.count < 6 {
            throw createAuthError(.weakPassword)
        }
        
        let user = MockFirebaseUser(uid: "mock-uid-new", email: email, displayName: nil)
        setCurrentUser(user)
        return user
    }
    
    func sendPasswordReset(withEmail email: String) async throws {
        if !shouldSucceed {
            throw errorToThrow ?? createAuthError(.userNotFound)
        }
        
        if email.isEmpty {
            throw createAuthError(.invalidEmail)
        }
    }
    
    func signOut() throws {
        if !shouldSucceed {
            throw errorToThrow ?? createAuthError(.networkError)
        }
        
        setCurrentUser(nil)
    }
    
    func addStateDidChangeListener(_ callback: @escaping (MockFirebaseUser?) -> Void) -> NSObjectProtocol {
        authStateDidChangeCallbacks.append(callback)
        callback(currentUser) // Immediately call with current state
        return MockAuthStateHandle()
    }
    
    private func notifyAuthStateChanged() {
        for callback in authStateDidChangeCallbacks {
            callback(currentUser)
        }
    }
    
    private func createAuthError(_ code: AuthErrorCode) -> NSError {
        return NSError(domain: AuthErrorDomain, code: code.rawValue, userInfo: [
            NSLocalizedDescriptionKey: "Mock Firebase Auth Error"
        ])
    }
}

class MockAuthStateHandle: NSObject {
    // Empty implementation - just for type compatibility
}

// MARK: - Mock Firebase Auth Repository

class MockFirebaseAuthRepository: AuthRepositoryProtocol {
    private let mockAuth = MockAuth.shared
    private let authStateSubject = PassthroughSubject<User?, Never>()
    
    var currentUser: User? {
        guard let mockUser = mockAuth.currentUser else { return nil }
        return User(id: mockUser.uid, email: mockUser.email, displayName: mockUser.displayName)
    }
    
    var authStateDidChange: AnyPublisher<User?, Never> {
        return authStateSubject.eraseToAnyPublisher()
    }
    
    private var authStateHandle: NSObjectProtocol?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            // In real implementation, would remove listener
            authStateHandle = nil
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandle = mockAuth.addStateDidChangeListener { [weak self] mockUser in
            let user = mockUser.map { User(id: $0.uid, email: $0.email, displayName: $0.displayName) }
            self?.authStateSubject.send(user)
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let mockUser = try await mockAuth.signIn(withEmail: email, password: password)
        return User(id: mockUser.uid, email: mockUser.email, displayName: mockUser.displayName)
    }
    
    func signUp(email: String, password: String) async throws -> User {
        let mockUser = try await mockAuth.createUser(withEmail: email, password: password)
        return User(id: mockUser.uid, email: mockUser.email, displayName: mockUser.displayName)
    }
    
    func signOut() async throws {
        try mockAuth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await mockAuth.sendPasswordReset(withEmail: email)
    }
    
    func updateUserProfile(user: User) async throws {
        guard mockAuth.currentUser != nil else {
            throw mapFirebaseError(createAuthError(.userNotFound))
        }
        
        // Mock implementation - just verify user is signed in
    }
    
    // MARK: - Test Configuration Methods
    
    func setMockUser(_ user: User?) {
        let mockUser = user.map { MockFirebaseUser(uid: $0.id, email: $0.email, displayName: $0.displayName) }
        mockAuth.setCurrentUser(mockUser)
    }
    
    func setShouldSucceed(_ shouldSucceed: Bool) {
        mockAuth.setShouldSucceed(shouldSucceed)
    }
    
    func setErrorToThrow(_ error: Error) {
        mockAuth.setErrorToThrow(error)
    }
    
    func reset() {
        mockAuth.reset()
    }
    
    // MARK: - Error Mapping
    
    private func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        
        if nsError.domain == AuthErrorDomain {
            switch nsError.code {
            case AuthErrorCode.invalidEmail.rawValue:
                return .invalidEmail
            case AuthErrorCode.wrongPassword.rawValue:
                return .wrongPassword
            case AuthErrorCode.userNotFound.rawValue:
                return .userNotFound
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return .emailAlreadyInUse
            case AuthErrorCode.weakPassword.rawValue:
                return .weakPassword
            case AuthErrorCode.networkError.rawValue:
                return .networkError
            default:
                return .unknownError(error)
            }
        }
        
        return .unknownError(error)
    }
    
    private func createAuthError(_ code: AuthErrorCode) -> NSError {
        return NSError(domain: AuthErrorDomain, code: code.rawValue, userInfo: [
            NSLocalizedDescriptionKey: "Mock Firebase Auth Error"
        ])
    }
}