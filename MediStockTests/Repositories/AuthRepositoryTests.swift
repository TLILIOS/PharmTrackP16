import XCTest
import Combine
@testable import MediStock

@MainActor
final class AuthRepositoryTests: XCTestCase {
    private var sut: AuthRepository!
    private var mockAuthService: MockAuthService!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        mockAuthService = MockAuthService()
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
}

// MARK: - Mock AuthService (hérite de AuthService pour AuthRepository)
// Note: Ce mock local est nécessaire car AuthRepository attend une instance de AuthService

@MainActor
class MockAuthService: AuthService {
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