import XCTest
@testable import MediStock
@MainActor
final class SignUpUseCaseTests: XCTestCase {
    
    var mockAuthRepository: MockAuthRepository!
    var signUpUseCase: SignUpUseCase!
    
    override func setUp() {
        super.setUp()
        mockAuthRepository = MockAuthRepository()
        signUpUseCase = SignUpUseCase(authRepository: mockAuthRepository)
    }
    
    override func tearDown() {
        mockAuthRepository = nil
        signUpUseCase = nil
        super.tearDown()
    }
    
    func testExecuteSuccessWithName() async throws {
        mockAuthRepository.shouldThrowOnSignUp = false
        mockAuthRepository.shouldThrowOnUpdateProfile = false
        
        try await signUpUseCase.execute(
            email: "test@example.com",
            password: "password123",
            name: "Test User"
        )
        
        // Verify user was created and profile updated
        XCTAssertNotNil(mockAuthRepository.currentUser)
        XCTAssertEqual(mockAuthRepository.currentUser?.email, "test@example.com")
        XCTAssertEqual(mockAuthRepository.currentUser?.displayName, "Test User")
    }
    
    func testExecuteSuccessWithEmptyName() async throws {
        mockAuthRepository.shouldThrowOnSignUp = false
        
        try await signUpUseCase.execute(
            email: "test@example.com",
            password: "password123",
            name: ""
        )
        
        // Verify user was created - Mock always returns "Mock User" as displayName
        XCTAssertNotNil(mockAuthRepository.currentUser)
        XCTAssertEqual(mockAuthRepository.currentUser?.email, "test@example.com")
        XCTAssertEqual(mockAuthRepository.currentUser?.displayName, "Mock User")
    }
    
    func testExecuteThrowsErrorOnSignUp() async {
        mockAuthRepository.shouldThrowOnSignUp = true
        mockAuthRepository.errorToThrow = AuthError.emailAlreadyInUse
        
        do {
            try await signUpUseCase.execute(
                email: "existing@example.com",
                password: "password123",
                name: "Test User"
            )
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual(error as? AuthError, AuthError.emailAlreadyInUse)
            // Note: currentUser is not nil because mock has pre-configured user
        }
    }
    
    func testExecuteThrowsErrorOnUpdateProfile() async {
        mockAuthRepository.shouldThrowOnSignUp = false
        mockAuthRepository.shouldThrowOnUpdateProfile = true
        
        do {
            try await signUpUseCase.execute(
                email: "test@example.com",
                password: "password123",
                name: "Test User"
            )
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual(error as? AuthError, AuthError.networkError)
        }
    }
    
    func testExecuteWithWhitespaceOnlyName() async throws {
        mockAuthRepository.shouldThrowOnSignUp = false
        
        try await signUpUseCase.execute(
            email: "test@example.com",
            password: "password123",
            name: "   "
        )
        
        // Name with only whitespace should still trigger profile update
        XCTAssertNotNil(mockAuthRepository.currentUser)
        XCTAssertEqual(mockAuthRepository.currentUser?.displayName, "   ")
    }
    
    func testExecuteWithLongName() async throws {
        mockAuthRepository.shouldThrowOnSignUp = false
        mockAuthRepository.shouldThrowOnUpdateProfile = false
        
        let longName = String(repeating: "A", count: 200)
        
        try await signUpUseCase.execute(
            email: "test@example.com",
            password: "password123",
            name: longName
        )
        
        XCTAssertNotNil(mockAuthRepository.currentUser)
        XCTAssertEqual(mockAuthRepository.currentUser?.displayName, longName)
    }
    
    func testExecuteWithSpecialCharactersInName() async throws {
        mockAuthRepository.shouldThrowOnSignUp = false
        mockAuthRepository.shouldThrowOnUpdateProfile = false
        
        let specialName = "José María-González @123!"
        
        try await signUpUseCase.execute(
            email: "test@example.com",
            password: "password123",
            name: specialName
        )
        
        XCTAssertNotNil(mockAuthRepository.currentUser)
        XCTAssertEqual(mockAuthRepository.currentUser?.displayName, specialName)
    }
    
    func testExecuteWithValidCredentials() async throws {
        mockAuthRepository.shouldThrowOnSignUp = false
        mockAuthRepository.shouldThrowOnUpdateProfile = false
        
        let testCases = [
            ("user1@example.com", "password123", "User One"),
            ("user2@example.com", "strongPass456", "User Two"),
            ("user3@example.com", "anotherPass789", ""),
            ("user4@example.com", "finalPass000", "Final User")
        ]
        
        for (email, password, name) in testCases {
            // Reset repository state
            mockAuthRepository.currentUser = nil
            
            try await signUpUseCase.execute(email: email, password: password, name: name)
            
            XCTAssertNotNil(mockAuthRepository.currentUser)
            XCTAssertEqual(mockAuthRepository.currentUser?.email, email)
            
            // If name is provided, it should be set as displayName; otherwise "Mock User" from signUp
            if !name.isEmpty {
                XCTAssertEqual(mockAuthRepository.currentUser?.displayName, name)
            } else {
                XCTAssertEqual(mockAuthRepository.currentUser?.displayName, "Mock User")
            }
        }
    }
    
    func testInitialization() {
        XCTAssertNotNil(signUpUseCase)
        XCTAssertTrue(signUpUseCase != nil)
    }
    
    func testExecutePartialSuccess() async {
        // User creation succeeds but profile update fails
        mockAuthRepository.shouldThrowOnSignUp = false
        mockAuthRepository.shouldThrowOnUpdateProfile = true
        
        do {
            try await signUpUseCase.execute(
                email: "test@example.com",
                password: "password123",
                name: "Test User"
            )
            XCTFail("Should have thrown an error")
        } catch {
            // Even though profile update failed, user should have been created
            XCTAssertNotNil(mockAuthRepository.currentUser)
            XCTAssertEqual(mockAuthRepository.currentUser?.email, "test@example.com")
            XCTAssertEqual(mockAuthRepository.currentUser?.displayName, "Mock User")
        }
    }
    
    func testExecuteEmptyCredentials() async throws {
        mockAuthRepository.shouldThrowOnSignUp = false
        
        try await signUpUseCase.execute(email: "", password: "", name: "")
        
        // Use case should still call repository - validation is at repository level
        XCTAssertNotNil(mockAuthRepository.currentUser)
    }
}
