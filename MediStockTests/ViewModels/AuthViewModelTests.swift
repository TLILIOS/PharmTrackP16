import XCTest
@testable import MediStock

@MainActor
final class AuthViewModelTests: XCTestCase {
    
    var sut: AuthViewModel!
    var mockSignInUseCase: MockSignInUseCase!
    var mockSignUpUseCase: MockSignUpUseCase!
    var mockAuthRepository: MockAuthRepository!
    
    override func setUp() {
        super.setUp()
        mockSignInUseCase = MockSignInUseCase()
        mockSignUpUseCase = MockSignUpUseCase()
        mockAuthRepository = MockAuthRepository()
        
        sut = AuthViewModel(
            signInUseCase: mockSignInUseCase,
            signUpUseCase: mockSignUpUseCase,
            authRepository: mockAuthRepository
        )
    }
    
    override func tearDown() {
        sut = nil
        mockSignInUseCase = nil
        mockSignUpUseCase = nil
        mockAuthRepository = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(sut.email, "")
        XCTAssertEqual(sut.password, "")
        XCTAssertEqual(sut.confirmPassword, "")
        XCTAssertEqual(sut.displayName, "")
        XCTAssertFalse(sut.resetEmailSent)
    }
    
    // MARK: - Authentication State Tests
    
    func testIsAuthenticated_WithUser() {
        // Given
        let user = TestDataFactory.createTestUser()
        
        // When
        sut.currentUser = user
        
        // Then
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    func testIsAuthenticated_WithoutUser() {
        // Given
        sut.currentUser = nil
        
        // When & Then
        XCTAssertFalse(sut.isAuthenticated)
    }
    
    // MARK: - Sign In Tests
    
    func testSignIn_Success() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        
        // When
        await sut.signIn()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockSignInUseCase.lastCredentials?.email, "test@example.com")
        XCTAssertEqual(mockSignInUseCase.lastCredentials?.password, "password123")
        XCTAssertEqual(sut.email, "")
        XCTAssertEqual(sut.password, "")
    }
    
    func testSignIn_Failure() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        mockSignInUseCase.shouldThrowError = true
        let expectedError = AuthError.invalidCredentials
        mockSignInUseCase.errorToThrow = expectedError
        
        // When
        await sut.signIn()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, expectedError.errorDescription)
        XCTAssertEqual(sut.email, "test@example.com") // Fields not reset on error
        XCTAssertEqual(sut.password, "password123")
    }
    
    func testSignIn_EmptyEmail() async {
        // Given
        sut.email = ""
        sut.password = "password123"
        
        // When
        await sut.signIn()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Veuillez entrer votre adresse e-mail.")
        XCTAssertEqual(mockSignInUseCase.callCount, 0)
    }
    
    func testSignIn_EmptyPassword() async {
        // Given
        sut.email = "test@example.com"
        sut.password = ""
        
        // When
        await sut.signIn()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Veuillez entrer votre mot de passe.")
        XCTAssertEqual(mockSignInUseCase.callCount, 0)
    }
    
    func testSignIn_LoadingState() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        mockSignInUseCase.delayNanoseconds = 50_000_000 // 50ms delay
        
        // When
        let task = Task {
            await sut.signIn()
        }
        
        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Check loading state
        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        
        await task.value
        
        // Then
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUp_Success() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.confirmPassword = "password123"
        sut.displayName = "Test User"
        
        // When
        await sut.signUp()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockSignUpUseCase.lastCredentials?.email, "test@example.com")
        XCTAssertEqual(mockSignUpUseCase.lastCredentials?.password, "password123")
        XCTAssertEqual(mockSignUpUseCase.lastCredentials?.name, "Test User")
        XCTAssertEqual(sut.email, "")
        XCTAssertEqual(sut.password, "")
        XCTAssertEqual(sut.confirmPassword, "")
        XCTAssertEqual(sut.displayName, "")
    }
    
    func testSignUp_Failure() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.confirmPassword = "password123"
        sut.displayName = "Test User"
        mockSignUpUseCase.shouldThrowError = true
        let expectedError = AuthError.emailAlreadyInUse
        mockSignUpUseCase.errorToThrow = expectedError
        
        // When
        await sut.signUp()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, expectedError.errorDescription)
        XCTAssertEqual(sut.email, "test@example.com") // Fields not reset on error
    }
    
    func testSignUp_PasswordMismatch() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.confirmPassword = "differentpassword"
        sut.displayName = "Test User"
        
        // When
        await sut.signUp()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Les mots de passe ne correspondent pas.")
        XCTAssertEqual(mockSignUpUseCase.callCount, 0)
    }
    
    func testSignUp_PasswordTooShort() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "123"
        sut.confirmPassword = "123"
        sut.displayName = "Test User"
        
        // When
        await sut.signUp()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Le mot de passe doit contenir au moins 6 caractères.")
        XCTAssertEqual(mockSignUpUseCase.callCount, 0)
    }
    
    func testSignUp_EmptyFields() async {
        // Given
        sut.email = ""
        sut.password = ""
        
        // When
        await sut.signUp()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Veuillez entrer votre adresse e-mail.")
        XCTAssertEqual(mockSignUpUseCase.callCount, 0)
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut_Success() async {
        // Given
        sut.currentUser = TestDataFactory.createTestUser()
        
        // When
        await sut.signOut()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockAuthRepository.signOutCallCount, 1)
    }
    
    func testSignOut_Failure() async {
        // Given
        sut.currentUser = TestDataFactory.createTestUser()
        mockAuthRepository.shouldThrowErrorOnSignOut = true
        let expectedError = AuthError.unknownError
        mockAuthRepository.signOutError = expectedError
        
        // When
        await sut.signOut()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, expectedError.errorDescription)
    }
    
    // MARK: - Reset Password Tests
    
    func testResetPassword_Success() async {
        // Given
        sut.email = "test@example.com"
        
        // When
        await sut.resetPassword()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.resetEmailSent)
        XCTAssertEqual(mockAuthRepository.lastResetEmail, "test@example.com")
    }
    
    func testResetPassword_EmptyEmail() async {
        // Given
        sut.email = ""
        
        // When
        await sut.resetPassword()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Veuillez entrer votre adresse e-mail.")
        XCTAssertFalse(sut.resetEmailSent)
        XCTAssertEqual(mockAuthRepository.resetPasswordCallCount, 0)
    }
    
    func testResetPassword_Failure() async {
        // Given
        sut.email = "test@example.com"
        mockAuthRepository.shouldThrowErrorOnResetPassword = true
        let expectedError = AuthError.userNotFound
        mockAuthRepository.resetPasswordError = expectedError
        
        // When
        await sut.resetPassword()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, expectedError.errorDescription)
        XCTAssertFalse(sut.resetEmailSent)
    }
    
    // MARK: - Auth State Observer Tests
    
    func testAuthStateObserver() {
        // Given
        let user = TestDataFactory.createTestUser()
        
        // When
        mockAuthRepository.simulateAuthStateChange(user: user)
        
        // Then
        XCTAssertEqual(sut.currentUser?.id, user.id)
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    func testAuthStateObserver_SignOut() {
        // Given
        sut.currentUser = TestDataFactory.createTestUser()
        
        // When
        mockAuthRepository.simulateAuthStateChange(user: nil)
        
        // Then
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isAuthenticated)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_NonAuthError() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        mockSignInUseCase.shouldThrowError = true
        let expectedError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Generic error"])
        mockSignInUseCase.errorToThrow = expectedError
        
        // When
        await sut.signIn()
        
        // Then
        XCTAssertEqual(sut.errorMessage, "Generic error")
    }
    
    // MARK: - Field Validation Edge Cases
    
    func testValidation_WhitespaceFields() async {
        // Given
        sut.email = "   "
        sut.password = "   "
        
        // When
        await sut.signIn()
        
        // Then
        XCTAssertEqual(sut.errorMessage, "Veuillez entrer votre adresse e-mail.")
    }
    
    func testSignUp_ExactMinimumPasswordLength() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "123456" // Exactly 6 characters
        sut.confirmPassword = "123456"
        sut.displayName = "Test User"
        
        // When
        await sut.signUp()
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockSignUpUseCase.callCount, 1)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentSignInAttempts() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        mockSignInUseCase.delayNanoseconds = 50_000_000
        
        // When - Start multiple sign in attempts
        let task1 = Task { await sut.signIn() }
        let task2 = Task { await sut.signIn() }
        
        await task1.value
        await task2.value
        
        // Then - Should handle concurrent requests gracefully
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(mockSignInUseCase.callCount, 2)
    }
}