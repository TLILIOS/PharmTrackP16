import XCTest
@testable import MediStock

@MainActor
class AuthServiceTests: XCTestCase {
    var mockAuthService: MockAuthServiceStandalone!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthServiceStandalone()
    }

    override func tearDown() {
        mockAuthService = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        // Assert
        XCTAssertNil(mockAuthService.currentUser)
        XCTAssertEqual(mockAuthService.signInCallCount, 0)
        XCTAssertEqual(mockAuthService.signUpCallCount, 0)
        XCTAssertEqual(mockAuthService.signOutCallCount, 0)
    }

    // MARK: - Sign In Tests

    func testSignInSuccess() async throws {
        // Arrange
        let email = "test@example.com"
        let password = "password123"

        // Act
        try await mockAuthService.signIn(email: email, password: password)

        // Assert
        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertNotNil(mockAuthService.currentUser)
        XCTAssertEqual(mockAuthService.currentUser?.email, email)
    }

    func testSignInWithEmptyEmail() async {
        // Arrange
        let email = ""
        let password = "password123"

        // Act & Assert
        do {
            try await mockAuthService.signIn(email: email, password: password)
            XCTFail("Should throw error for empty email")
        } catch {
            XCTAssertEqual(mockAuthService.signInCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testSignInWithEmptyPassword() async {
        // Arrange
        let email = "test@example.com"
        let password = ""

        // Act & Assert
        do {
            try await mockAuthService.signIn(email: email, password: password)
            XCTFail("Should throw error for empty password")
        } catch {
            XCTAssertEqual(mockAuthService.signInCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testSignInWithInvalidEmailFormat() async {
        // Arrange
        let email = "invalid-email"
        let password = "password123"

        // Act & Assert
        do {
            try await mockAuthService.signIn(email: email, password: password)
            XCTFail("Should throw error for invalid email format")
        } catch {
            XCTAssertEqual(mockAuthService.signInCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testSignInFailure() async {
        // Arrange
        mockAuthService.shouldThrowError = true
        mockAuthService.errorToThrow = AuthError.wrongPassword
        let email = "test@example.com"
        let password = "wrongpassword"

        // Act & Assert
        do {
            try await mockAuthService.signIn(email: email, password: password)
            XCTFail("Should throw error when shouldThrowError is true")
        } catch {
            XCTAssertEqual(mockAuthService.signInCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Sign Up Tests

    func testSignUpSuccess() async throws {
        // Arrange
        let email = "newuser@example.com"
        let password = "password123"
        let displayName = "New User"

        // Act
        try await mockAuthService.signUp(email: email, password: password, displayName: displayName)

        // Assert
        XCTAssertEqual(mockAuthService.signUpCallCount, 1)
        XCTAssertNotNil(mockAuthService.currentUser)
        XCTAssertEqual(mockAuthService.currentUser?.email, email)
        XCTAssertEqual(mockAuthService.currentUser?.displayName, displayName)
    }

    func testSignUpWithEmptyEmail() async {
        // Arrange
        let email = ""
        let password = "password123"
        let displayName = "Test User"

        // Act & Assert
        do {
            try await mockAuthService.signUp(email: email, password: password, displayName: displayName)
            XCTFail("Should throw error for empty email")
        } catch {
            XCTAssertEqual(mockAuthService.signUpCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testSignUpWithWeakPassword() async {
        // Arrange
        let email = "test@example.com"
        let password = "123" // Mot de passe trop court
        let displayName = "Test User"

        // Act & Assert
        do {
            try await mockAuthService.signUp(email: email, password: password, displayName: displayName)
            XCTFail("Should throw error for weak password")
        } catch {
            XCTAssertEqual(mockAuthService.signUpCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testSignUpWithEmptyPassword() async {
        // Arrange
        let email = "test@example.com"
        let password = ""
        let displayName = "Test User"

        // Act & Assert
        do {
            try await mockAuthService.signUp(email: email, password: password, displayName: displayName)
            XCTFail("Should throw error for empty password")
        } catch {
            XCTAssertEqual(mockAuthService.signUpCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Sign Out Tests

    func testSignOutSuccess() async throws {
        // Arrange - Sign in first
        try await mockAuthService.signIn(email: "test@example.com", password: "password123")
        XCTAssertNotNil(mockAuthService.currentUser)

        // Act
        try await mockAuthService.signOut()

        // Assert
        XCTAssertEqual(mockAuthService.signOutCallCount, 1)
        XCTAssertNil(mockAuthService.currentUser)
    }

    func testSignOutFailure() async {
        // Arrange
        mockAuthService.shouldThrowError = true
        mockAuthService.errorToThrow = AuthError.networkError

        // Act & Assert
        do {
            try await mockAuthService.signOut()
            XCTFail("Should throw error when shouldThrowError is true")
        } catch {
            XCTAssertEqual(mockAuthService.signOutCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Password Reset Tests

    func testResetPasswordSuccess() async throws {
        // Arrange
        let email = "test@example.com"

        // Act
        try await mockAuthService.resetPassword(email: email)

        // Assert
        XCTAssertEqual(mockAuthService.resetPasswordCallCount, 1)
    }

    func testResetPasswordWithEmptyEmail() async {
        // Arrange
        let email = ""

        // Act & Assert
        do {
            try await mockAuthService.resetPassword(email: email)
            XCTFail("Should throw error for empty email")
        } catch {
            XCTAssertEqual(mockAuthService.resetPasswordCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testResetPasswordWithInvalidEmail() async {
        // Arrange
        let email = "invalid-email"

        // Act & Assert
        do {
            try await mockAuthService.resetPassword(email: email)
            XCTFail("Should throw error for invalid email")
        } catch {
            XCTAssertEqual(mockAuthService.resetPasswordCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testResetPasswordFailure() async {
        // Arrange
        mockAuthService.shouldThrowError = true
        mockAuthService.errorToThrow = AuthError.userNotFound

        // Act & Assert
        do {
            try await mockAuthService.resetPassword(email: "test@example.com")
            XCTFail("Should throw error when shouldThrowError is true")
        } catch {
            XCTAssertEqual(mockAuthService.resetPasswordCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    // MARK: - User State Tests

    func testGetCurrentUserWhenNil() {
        // Assert
        XCTAssertNil(mockAuthService.getCurrentUser())
    }

    func testGetCurrentUserWhenSet() async throws {
        // Arrange & Act
        try await mockAuthService.signIn(email: "test@example.com", password: "password123")

        // Assert
        let user = mockAuthService.getCurrentUser()
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.email, "test@example.com")
    }

    func testCurrentUserUpdate() async throws {
        // Arrange & Act
        try await mockAuthService.signIn(email: "test@example.com", password: "password123")

        // Assert
        XCTAssertNotNil(mockAuthService.currentUser)
        XCTAssertEqual(mockAuthService.currentUser?.email, "test@example.com")
        XCTAssertEqual(mockAuthService.currentUser?.displayName, "Mock User")
    }

    func testCurrentUserClear() async throws {
        // Arrange
        try await mockAuthService.signIn(email: "test@example.com", password: "password123")
        XCTAssertNotNil(mockAuthService.currentUser)

        // Act
        try await mockAuthService.signOut()

        // Assert
        XCTAssertNil(mockAuthService.currentUser)
    }
}
