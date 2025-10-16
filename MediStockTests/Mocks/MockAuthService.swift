import Foundation
import Combine
@testable import MediStock

// MARK: - Mock Auth Service pour les tests unitaires

@MainActor
final class MockAuthService: AuthServiceProtocol {
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
    var lastResetPasswordEmail: String?

    var mockAuthToken: String?

    // MARK: - Errors

    enum MockAuthError: LocalizedError {
        case signInFailed
        case signUpFailed
        case signOutFailed
        case resetPasswordFailed
        case tokenRetrievalFailed
        case invalidCredentials
        case networkError

        var errorDescription: String? {
            switch self {
            case .signInFailed: return "Mock sign in failed"
            case .signUpFailed: return "Mock sign up failed"
            case .signOutFailed: return "Mock sign out failed"
            case .resetPasswordFailed: return "Mock reset password failed"
            case .tokenRetrievalFailed: return "Mock token retrieval failed"
            case .invalidCredentials: return "Invalid email or password"
            case .networkError: return "Network error occurred"
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
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailSignIn else {
            throw MockAuthError.signInFailed
        }

        // Validation basique
        guard !email.isEmpty, !password.isEmpty else {
            throw MockAuthError.invalidCredentials
        }

        // Simuler une connexion réussie
        currentUser = User(
            id: "mock-user-id",
            email: email,
            displayName: "Mock User"
        )
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        signUpCallCount += 1
        lastSignUpEmail = email

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailSignUp else {
            throw MockAuthError.signUpFailed
        }

        // Validation basique
        guard !email.isEmpty, !password.isEmpty, !displayName.isEmpty else {
            throw MockAuthError.invalidCredentials
        }

        // Simuler une inscription réussie
        currentUser = User(
            id: "mock-new-user-id",
            email: email,
            displayName: displayName
        )
    }

    func signOut() async throws {
        signOutCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

        guard !shouldFailSignOut else {
            throw MockAuthError.signOutFailed
        }

        currentUser = nil
    }

    func resetPassword(email: String) async throws {
        resetPasswordCallCount += 1
        lastResetPasswordEmail = email

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailResetPassword else {
            throw MockAuthError.resetPasswordFailed
        }

        guard !email.isEmpty else {
            throw MockAuthError.invalidCredentials
        }

        // Pas d'action visible, juste pas d'erreur
    }

    func getAuthToken() async throws -> String? {
        getAuthTokenCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

        guard !shouldFailGetToken else {
            throw MockAuthError.tokenRetrievalFailed
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
        lastResetPasswordEmail = nil
        mockAuthToken = "mock-jwt-token-12345"
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
        getToken: Bool = false
    ) {
        shouldFailSignIn = signIn
        shouldFailSignUp = signUp
        shouldFailSignOut = signOut
        shouldFailResetPassword = resetPassword
        shouldFailGetToken = getToken
    }
}
