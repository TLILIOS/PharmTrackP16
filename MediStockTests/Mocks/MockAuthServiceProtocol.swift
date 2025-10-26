import Foundation
import Combine
@testable import MediStock

// MARK: - Mock Auth Service complet pour tous les tests
/// Mock qui implémente AuthServiceProtocol sans dépendre de Firebase
/// Utilisable pour tous les tests unitaires et d'intégration

@MainActor
final class MockAuthServiceProtocol: ObservableObject, AuthServiceProtocol {
    // MARK: - Published Properties

    @Published var currentUser: User?

    var currentUserPublisher: AnyPublisher<User?, Never> {
        $currentUser.eraseToAnyPublisher()
    }

    // MARK: - Test Configuration

    var shouldFailSignIn = false
    var shouldFailSignUp = false
    var shouldFailSignOut = false
    var shouldFailResetPassword = false
    var shouldFailGetToken = false

    var signInCallCount = 0
    var signUpCallCount = 0
    var signOutCallCount = 0
    var resetPasswordCallCount = 0
    var getAuthTokenCallCount = 0

    var lastSignInEmail: String?
    var lastSignInPassword: String?
    var lastSignUpEmail: String?
    var lastSignUpPassword: String?
    var lastSignUpDisplayName: String?
    var lastResetPasswordEmail: String?

    var mockAuthToken: String?
    var errorToThrow: Error?

    // MARK: - Simulation Settings

    /// Délai de simulation réseau (en nanosecondes)
    var networkDelayNanoseconds: UInt64 = 100_000_000 // 0.1 seconde par défaut

    /// Active/désactive le délai réseau simulé
    var simulateNetworkDelay = true

    // MARK: - Errors

    enum MockAuthError: LocalizedError {
        case signInFailed
        case signUpFailed
        case signOutFailed
        case resetPasswordFailed
        case tokenRetrievalFailed
        case invalidCredentials
        case networkError
        case userNotFound
        case emailAlreadyInUse
        case weakPassword
        case invalidEmail

        var errorDescription: String? {
            switch self {
            case .signInFailed: return "Mock sign in failed"
            case .signUpFailed: return "Mock sign up failed"
            case .signOutFailed: return "Mock sign out failed"
            case .resetPasswordFailed: return "Mock reset password failed"
            case .tokenRetrievalFailed: return "Mock token retrieval failed"
            case .invalidCredentials: return "Invalid email or password"
            case .networkError: return "Network error occurred"
            case .userNotFound: return "User not found"
            case .emailAlreadyInUse: return "Email already in use"
            case .weakPassword: return "Password is too weak"
            case .invalidEmail: return "Invalid email format"
            }
        }
    }

    // MARK: - Initialization

    init() {
        self.currentUser = nil
        self.mockAuthToken = "mock-jwt-token-12345"
    }

    // MARK: - AuthServiceProtocol Implementation

    func signIn(email: String, password: String) async throws {
        signInCallCount += 1
        lastSignInEmail = email
        lastSignInPassword = password

        // Simulate network delay
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: networkDelayNanoseconds)
        }

        guard !shouldFailSignIn else {
            throw errorToThrow ?? MockAuthError.signInFailed
        }

        // Validation basique
        guard !email.isEmpty else {
            throw MockAuthError.invalidEmail
        }

        guard !password.isEmpty else {
            throw MockAuthError.invalidCredentials
        }

        guard email.contains("@") else {
            throw MockAuthError.invalidEmail
        }

        // Simuler une connexion réussie
        currentUser = User(
            id: "mock-user-\(UUID().uuidString)",
            email: email,
            displayName: "Mock User"
        )
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        signUpCallCount += 1
        lastSignUpEmail = email
        lastSignUpPassword = password
        lastSignUpDisplayName = displayName

        // Simulate network delay
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: networkDelayNanoseconds)
        }

        guard !shouldFailSignUp else {
            throw errorToThrow ?? MockAuthError.signUpFailed
        }

        // Validation basique
        guard !email.isEmpty else {
            throw MockAuthError.invalidEmail
        }

        guard !password.isEmpty else {
            throw MockAuthError.weakPassword
        }

        guard password.count >= 6 else {
            throw MockAuthError.weakPassword
        }

        guard !displayName.isEmpty else {
            throw MockAuthError.invalidCredentials
        }

        guard email.contains("@") else {
            throw MockAuthError.invalidEmail
        }

        // Simuler une inscription réussie
        currentUser = User(
            id: "mock-new-user-\(UUID().uuidString)",
            email: email,
            displayName: displayName
        )
    }

    func signOut() async throws {
        signOutCallCount += 1

        // Simulate network delay
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: networkDelayNanoseconds / 2)
        }

        guard !shouldFailSignOut else {
            throw errorToThrow ?? MockAuthError.signOutFailed
        }

        currentUser = nil
    }

    func resetPassword(email: String) async throws {
        resetPasswordCallCount += 1
        lastResetPasswordEmail = email

        // Simulate network delay
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: networkDelayNanoseconds)
        }

        guard !shouldFailResetPassword else {
            throw errorToThrow ?? MockAuthError.resetPasswordFailed
        }

        guard !email.isEmpty else {
            throw MockAuthError.invalidEmail
        }

        guard email.contains("@") else {
            throw MockAuthError.invalidEmail
        }

        // Pas d'action visible, juste pas d'erreur
    }

    func getAuthToken() async throws -> String? {
        getAuthTokenCallCount += 1

        // Simulate network delay
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: networkDelayNanoseconds / 2)
        }

        guard !shouldFailGetToken else {
            throw errorToThrow ?? MockAuthError.tokenRetrievalFailed
        }

        return mockAuthToken
    }

    // MARK: - Test Helpers

    /// Réinitialise tous les compteurs et états
    func reset() {
        currentUser = nil
        shouldFailSignIn = false
        shouldFailSignUp = false
        shouldFailSignOut = false
        shouldFailResetPassword = false
        shouldFailGetToken = false
        signInCallCount = 0
        signUpCallCount = 0
        signOutCallCount = 0
        resetPasswordCallCount = 0
        getAuthTokenCallCount = 0
        lastSignInEmail = nil
        lastSignInPassword = nil
        lastSignUpEmail = nil
        lastSignUpPassword = nil
        lastSignUpDisplayName = nil
        lastResetPasswordEmail = nil
        mockAuthToken = "mock-jwt-token-12345"
        errorToThrow = nil
        networkDelayNanoseconds = 100_000_000
        simulateNetworkDelay = true
    }

    /// Configure un utilisateur connecté pour les tests
    func setMockUser(_ user: User?) {
        currentUser = user
    }

    /// Configure les erreurs pour tester les cas d'échec
    func configureFailures(
        signIn: Bool = false,
        signUp: Bool = false,
        signOut: Bool = false,
        resetPassword: Bool = false,
        getToken: Bool = false,
        customError: Error? = nil
    ) {
        shouldFailSignIn = signIn
        shouldFailSignUp = signUp
        shouldFailSignOut = signOut
        shouldFailResetPassword = resetPassword
        shouldFailGetToken = getToken
        errorToThrow = customError
    }

    /// Désactive les délais réseau pour des tests plus rapides
    func disableNetworkDelay() {
        simulateNetworkDelay = false
    }

    /// Configure un délai réseau personnalisé
    func setNetworkDelay(milliseconds: Int) {
        networkDelayNanoseconds = UInt64(milliseconds) * 1_000_000
    }

    /// Helper pour créer un utilisateur de test
    static func createTestUser(
        id: String = "test-user-id",
        email: String = "test@example.com",
        displayName: String = "Test User"
    ) -> User {
        User(id: id, email: email, displayName: displayName)
    }
}

// MARK: - Extensions pour faciliter les tests

extension MockAuthServiceProtocol {
    /// Configure un scénario de connexion réussie
    func setupSuccessfulSignIn(email: String = "test@example.com") {
        shouldFailSignIn = false
        currentUser = Self.createTestUser(email: email)
    }

    /// Configure un scénario d'échec de connexion
    func setupFailedSignIn(error: Error? = nil) {
        shouldFailSignIn = true
        errorToThrow = error ?? MockAuthError.invalidCredentials
    }

    /// Configure un scénario d'inscription réussie
    func setupSuccessfulSignUp(email: String = "newuser@example.com", displayName: String = "New User") {
        shouldFailSignUp = false
        currentUser = User(id: "new-user-id", email: email, displayName: displayName)
    }

    /// Configure un scénario d'échec d'inscription
    func setupFailedSignUp(error: Error? = nil) {
        shouldFailSignUp = true
        errorToThrow = error ?? MockAuthError.emailAlreadyInUse
    }
}
