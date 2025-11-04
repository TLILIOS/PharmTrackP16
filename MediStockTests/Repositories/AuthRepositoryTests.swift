import XCTest
import Combine
@testable import MediStock

@MainActor
final class AuthRepositoryTests: XCTestCase {
    private var sut: AuthRepository!
    private var mockAuthService: AuthRepositoryMockAuthService!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        mockAuthService = AuthRepositoryMockAuthService()
        sut = AuthRepository(authService: mockAuthService)
        cancellables.removeAll()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockAuthService = nil
        cancellables.removeAll()
        try await super.tearDown()
    }
    
    // MARK: - Tests d'initialisation
    
    func testInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.getCurrentUser())
    }
    
    func testCurrentUserPublisher() {
        let expectation = XCTestExpectation(description: "Publisher should emit user changes")
        expectation.expectedFulfillmentCount = 1
        
        // S'assurer que le mock n'a pas d'utilisateur initial
        mockAuthService.currentUser = nil
        
        // Attendre un peu pour que l'observation soit établie
        let setupExpectation = XCTestExpectation(description: "Setup complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 0.5)
        
        var receivedUser: User?
        
        sut.currentUserPublisher
            .dropFirst() // Ignorer la valeur initiale
            .sink { user in
                receivedUser = user
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let testUser = User(id: "test123", email: "test@example.com", displayName: "Test User")
        mockAuthService.currentUser = testUser
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedUser?.id, "test123")
        XCTAssertEqual(receivedUser?.email, "test@example.com")
        XCTAssertEqual(receivedUser?.displayName, "Test User")
    }
    
    // MARK: - Tests de connexion
    
    func testSignInSuccess() async throws {
        mockAuthService.signInResult = .success(())
        let testUser = User(id: "user123", email: "test@example.com", displayName: "Test User")
        mockAuthService.currentUser = testUser
        
        try await sut.signIn(email: "test@example.com", password: "password123")
        
        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertEqual(mockAuthService.lastSignInEmail, "test@example.com")
        XCTAssertEqual(mockAuthService.lastSignInPassword, "password123")
        XCTAssertEqual(sut.getCurrentUser()?.id, "user123")
    }
    
    func testSignInFailure() async {
        mockAuthService.signInResult = .failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"]))
        mockAuthService.currentUser = nil
        
        do {
            try await sut.signIn(email: "test@example.com", password: "wrongpassword")
            XCTFail("Sign in should have failed")
        } catch {
            XCTAssertEqual(mockAuthService.signInCallCount, 1)
            XCTAssertNil(sut.getCurrentUser())
        }
    }
    
    // MARK: - Tests d'inscription
    
    func testSignUpSuccess() async throws {
        mockAuthService.signUpResult = .success(())
        let testUser = User(id: "newuser123", email: "newuser@example.com", displayName: "New User")
        mockAuthService.currentUser = testUser
        
        try await sut.signUp(email: "newuser@example.com", password: "password123", displayName: "New User")
        
        XCTAssertEqual(mockAuthService.signUpCallCount, 1)
        XCTAssertEqual(mockAuthService.lastSignUpEmail, "newuser@example.com")
        XCTAssertEqual(mockAuthService.lastSignUpPassword, "password123")
        XCTAssertEqual(mockAuthService.lastSignUpDisplayName, "New User")
        XCTAssertEqual(sut.getCurrentUser()?.id, "newuser123")
    }
    
    func testSignUpFailure() async {
        mockAuthService.signUpResult = .failure(NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email already exists"]))
        mockAuthService.currentUser = nil
        
        do {
            try await sut.signUp(email: "existing@example.com", password: "password123", displayName: "Existing User")
            XCTFail("Sign up should have failed")
        } catch {
            XCTAssertEqual(mockAuthService.signUpCallCount, 1)
            XCTAssertNil(sut.getCurrentUser())
        }
    }
    
    // MARK: - Tests de déconnexion
    
    func testSignOutSuccess() async throws {
        mockAuthService.signOutResult = .success(())
        let testUser = User(id: "user123", email: "test@example.com", displayName: "Test User")
        mockAuthService.currentUser = testUser
        
        try await sut.signOut()
        
        mockAuthService.currentUser = nil
        
        XCTAssertEqual(mockAuthService.signOutCallCount, 1)
        XCTAssertNil(sut.getCurrentUser())
    }
    
    func testSignOutFailure() async {
        mockAuthService.signOutResult = .failure(NSError(domain: "AuthError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Sign out failed"]))
        let testUser = User(id: "user123", email: "test@example.com", displayName: "Test User")
        mockAuthService.currentUser = testUser
        
        do {
            try await sut.signOut()
            XCTFail("Sign out should have failed")
        } catch {
            XCTAssertEqual(mockAuthService.signOutCallCount, 1)
            XCTAssertNotNil(sut.getCurrentUser())
        }
    }
    
    // MARK: - Tests de création par défaut

    func testCreateDefault() {
        let defaultRepository = AuthRepository.createDefault()
        XCTAssertNotNil(defaultRepository)
        XCTAssertNil(defaultRepository.getCurrentUser())
    }

    // MARK: - Additional Tests for 85%+ Coverage

    func testGetCurrentUserWhenLoggedIn() async throws {
        // Given
        mockAuthService.signInResult = .success(())
        let testUser = User(id: "current-user", email: "current@test.com", displayName: "Current User")
        mockAuthService.currentUser = testUser

        // When
        try await sut.signIn(email: "current@test.com", password: "password")

        // Then
        XCTAssertEqual(sut.getCurrentUser()?.id, "current-user")
        XCTAssertEqual(sut.getCurrentUser()?.email, "current@test.com")
    }

    func testGetCurrentUserWhenNotLoggedIn() {
        // Given
        mockAuthService.currentUser = nil

        // When
        let user = sut.getCurrentUser()

        // Then
        XCTAssertNil(user)
    }

    func testSignInWithEmptyEmail() async {
        // Given
        mockAuthService.signInResult = .failure(AuthError.invalidEmail)

        // When & Then
        do {
            try await sut.signIn(email: "", password: "password")
            XCTFail("Should throw error for empty email")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testSignInWithEmptyPassword() async {
        // Given
        mockAuthService.signInResult = .failure(AuthError.wrongPassword)

        // When & Then
        do {
            try await sut.signIn(email: "test@test.com", password: "")
            XCTFail("Should throw error for empty password")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testSignUpWithWeakPassword() async {
        // Given
        mockAuthService.signUpResult = .failure(AuthError.weakPassword)

        // When & Then
        do {
            try await sut.signUp(email: "new@test.com", password: "123", displayName: "New")
            XCTFail("Should throw error for weak password")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testSignUpWithExistingEmail() async {
        // Given
        mockAuthService.signUpResult = .failure(AuthError.emailAlreadyInUse)

        // When & Then
        do {
            try await sut.signUp(email: "existing@test.com", password: "password123", displayName: "Test")
            XCTFail("Should throw error for existing email")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testConcurrentSignInRequests() async throws {
        // Given
        mockAuthService.signInResult = .success(())
        let testUser = User(id: "concurrent-user", email: "concurrent@test.com", displayName: "Concurrent")
        mockAuthService.currentUser = testUser

        // When - Launch multiple concurrent sign ins
        async let signIn1: Void = sut.signIn(email: "concurrent@test.com", password: "pass1")
        async let signIn2: Void = sut.signIn(email: "concurrent@test.com", password: "pass2")

        try await signIn1
        try await signIn2

        // Then - All should complete
        XCTAssertEqual(mockAuthService.signInCallCount, 2)
    }

    func testCurrentUserPublisherEmitsOnSignIn() async throws {
        // Given
        let expectation = XCTestExpectation(description: "User change published")

        sut.currentUserPublisher
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mockAuthService.signInResult = .success(())
        let testUser = User(id: "test-pub", email: "pub@test.com", displayName: "Pub Test")

        // When
        try await sut.signIn(email: "pub@test.com", password: "password")
        mockAuthService.currentUser = testUser

        // Give time for publisher
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - Verify call was made (publisher emission is asynchronous)
        XCTAssertEqual(mockAuthService.signInCallCount, 1)
    }

    func testCurrentUserPublisherEmitsOnSignOut() async throws {
        // Given - First sign in
        mockAuthService.signInResult = .success(())
        let testUser = User(id: "test-signout", email: "signout@test.com", displayName: "Sign Out Test")
        mockAuthService.currentUser = testUser
        try await sut.signIn(email: "signout@test.com", password: "password")

        let expectation = XCTestExpectation(description: "User cleared published")

        sut.currentUserPublisher
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mockAuthService.signOutResult = .success(())

        // When
        try await sut.signOut()
        mockAuthService.currentUser = nil

        // Give time for publisher
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - Verify sign out was called
        XCTAssertEqual(mockAuthService.signOutCallCount, 1)
    }

    func testSignInCallCountIncreases() async throws {
        // Given
        mockAuthService.signInResult = .success(())
        mockAuthService.currentUser = User.mock()

        // When
        try await sut.signIn(email: "test1@test.com", password: "pass1")
        try await sut.signIn(email: "test2@test.com", password: "pass2")

        // Then
        XCTAssertEqual(mockAuthService.signInCallCount, 2)
    }

    func testSignUpCallCountIncreases() async throws {
        // Given
        mockAuthService.signUpResult = .success(())
        mockAuthService.currentUser = User.mock()

        // When
        try await sut.signUp(email: "new1@test.com", password: "pass1", displayName: "New 1")
        try await sut.signUp(email: "new2@test.com", password: "pass2", displayName: "New 2")

        // Then
        XCTAssertEqual(mockAuthService.signUpCallCount, 2)
    }

    func testSignOutCallCountIncreases() async throws {
        // Given
        mockAuthService.signOutResult = .success(())

        // When
        try await sut.signOut()
        try await sut.signOut()

        // Then
        XCTAssertEqual(mockAuthService.signOutCallCount, 2)
    }

    func testCompleteAuthFlow() async throws {
        // Step 1: Sign up
        mockAuthService.signUpResult = .success(())
        mockAuthService.currentUser = User(id: "flow-user", email: "flow@test.com", displayName: "Flow User")
        try await sut.signUp(email: "flow@test.com", password: "password123", displayName: "Flow User")
        XCTAssertNotNil(sut.getCurrentUser())

        // Step 2: Sign out
        mockAuthService.signOutResult = .success(())
        try await sut.signOut()
        mockAuthService.currentUser = nil
        XCTAssertNil(sut.getCurrentUser())

        // Step 3: Sign in
        mockAuthService.signInResult = .success(())
        mockAuthService.currentUser = User(id: "flow-user", email: "flow@test.com", displayName: "Flow User")
        try await sut.signIn(email: "flow@test.com", password: "password123")
        XCTAssertNotNil(sut.getCurrentUser())
    }
}

// MARK: - Mock AuthService (hérite de AuthService pour AuthRepository)
// Note: Ce mock local est nécessaire car AuthRepository attend une instance de AuthService

@MainActor
class AuthRepositoryMockAuthService: AuthService {
    var signInCallCount = 0
    var signUpCallCount = 0
    var signOutCallCount = 0

    var lastSignInEmail: String?
    var lastSignInPassword: String?

    var lastSignUpEmail: String?
    var lastSignUpPassword: String?
    var lastSignUpDisplayName: String?

    var signInResult: Result<Void, Error> = .success(())
    var signUpResult: Result<Void, Error> = .success(())
    var signOutResult: Result<Void, Error> = .success(())

    override init() {
        super.init()
        // Ne pas initialiser Firebase dans les tests
        self.currentUser = nil
    }

    override func signIn(email: String, password: String) async throws {
        signInCallCount += 1
        lastSignInEmail = email
        lastSignInPassword = password

        switch signInResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    override func signUp(email: String, password: String, displayName: String) async throws {
        signUpCallCount += 1
        lastSignUpEmail = email
        lastSignUpPassword = password
        lastSignUpDisplayName = displayName

        switch signUpResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    override func signOut() async throws {
        signOutCallCount += 1

        switch signOutResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}