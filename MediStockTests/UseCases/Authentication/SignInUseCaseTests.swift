import XCTest
@testable import MediStock

final class SignInUseCaseTests: XCTestCase {
    
    var mockAuthRepository: MockAuthRepository!
    var signInUseCase: SignInUseCase!
    
    override func setUp() {
        super.setUp()
        mockAuthRepository = MockAuthRepository()
        signInUseCase = SignInUseCase(authRepository: mockAuthRepository)
    }
    
    override func tearDown() {
        mockAuthRepository = nil
        signInUseCase = nil
        super.tearDown()
    }
    
    func testExecuteSuccess() async throws {
        mockAuthRepository.shouldThrowOnSignIn = false
        
        try await signInUseCase.execute(email: "test@example.com", password: "password123")
        
        // If no exception is thrown, the test passes
        XCTAssertTrue(true)
    }
    
    func testExecuteThrowsError() async {
        mockAuthRepository.shouldThrowOnSignIn = true
        
        do {
            try await signInUseCase.execute(email: "test@example.com", password: "wrongpassword")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual(error as? AuthError, AuthError.wrongPassword)
        }
    }
    
    func testExecuteWithValidCredentials() async throws {
        let validEmail = "user@example.com"
        let validPassword = "strongPassword123"
        
        mockAuthRepository.shouldThrowOnSignIn = false
        
        try await signInUseCase.execute(email: validEmail, password: validPassword)
        
        // Verify that execute completes without throwing
        XCTAssertTrue(true)
    }
    
    func testExecuteWithEmptyEmail() async throws {
        mockAuthRepository.shouldThrowOnSignIn = false
        
        try await signInUseCase.execute(email: "", password: "password123")
        
        // The use case should still call the repository even with empty email
        // Repository validation is handled at repository level
        XCTAssertTrue(true)
    }
    
    func testExecuteWithEmptyPassword() async throws {
        mockAuthRepository.shouldThrowOnSignIn = false
        
        try await signInUseCase.execute(email: "test@example.com", password: "")
        
        // The use case should still call the repository even with empty password
        // Repository validation is handled at repository level
        XCTAssertTrue(true)
    }
    
    func testExecuteWithBothEmptyCredentials() async throws {
        mockAuthRepository.shouldThrowOnSignIn = false
        
        try await signInUseCase.execute(email: "", password: "")
        
        // The use case should still call the repository
        XCTAssertTrue(true)
    }
    
    func testInitialization() {
        XCTAssertNotNil(signInUseCase)
        XCTAssertTrue(signInUseCase is SignInUseCaseProtocol)
    }
    
    func testExecuteMultipleTimes() async throws {
        mockAuthRepository.shouldThrowOnSignIn = false
        
        for i in 0..<3 {
            try await signInUseCase.execute(
                email: "user\(i)@example.com",
                password: "password\(i)"
            )
        }
        
        XCTAssertTrue(true)
    }
    
    func testExecuteWithSpecialCharactersInEmail() async throws {
        mockAuthRepository.shouldThrowOnSignIn = false
        
        let specialEmails = [
            "user+tag@example.com",
            "user.name@example.com",
            "user_name@example.com",
            "user-name@example.com"
        ]
        
        for email in specialEmails {
            try await signInUseCase.execute(email: email, password: "password123")
        }
        
        XCTAssertTrue(true)
    }
    
    func testExecuteWithLongCredentials() async throws {
        mockAuthRepository.shouldThrowOnSignIn = false
        
        let longEmail = String(repeating: "a", count: 100) + "@example.com"
        let longPassword = String(repeating: "b", count: 200)
        
        try await signInUseCase.execute(email: longEmail, password: longPassword)
        
        XCTAssertTrue(true)
    }
}