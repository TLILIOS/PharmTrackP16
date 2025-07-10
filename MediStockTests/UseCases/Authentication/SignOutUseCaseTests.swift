import XCTest
@testable import MediStock

final class SignOutUseCaseTests: XCTestCase {
    
    var mockAuthRepository: MockAuthRepository!
    var signOutUseCase: SignOutUseCase!
    
    override func setUp() {
        super.setUp()
        mockAuthRepository = MockAuthRepository()
        signOutUseCase = SignOutUseCase(authRepository: mockAuthRepository)
    }
    
    override func tearDown() {
        mockAuthRepository = nil
        signOutUseCase = nil
        super.tearDown()
    }
    
    func testExecuteSuccess() async throws {
        mockAuthRepository.shouldThrowOnSignOut = false
        mockAuthRepository.currentUser = User(id: "user-123", email: "test@example.com", displayName: "Test User")
        
        try await signOutUseCase.execute()
        
        // Verify user is signed out
        XCTAssertNil(mockAuthRepository.currentUser)
    }
    
    func testExecuteThrowsError() async {
        mockAuthRepository.shouldThrowOnSignOut = true
        
        do {
            try await signOutUseCase.execute()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual(error as? AuthError, AuthError.networkError)
        }
    }
    
    func testExecuteWhenNoUserSignedIn() async throws {
        mockAuthRepository.shouldThrowOnSignOut = false
        mockAuthRepository.currentUser = nil
        
        try await signOutUseCase.execute()
        
        // Should not throw error even if no user is signed in
        XCTAssertNil(mockAuthRepository.currentUser)
    }
    
    func testExecuteMultipleTimes() async throws {
        mockAuthRepository.shouldThrowOnSignOut = false
        mockAuthRepository.currentUser = User(id: "user-123", email: "test@example.com", displayName: "Test User")
        
        // First sign out
        try await signOutUseCase.execute()
        XCTAssertNil(mockAuthRepository.currentUser)
        
        // Second sign out (should not throw error)
        try await signOutUseCase.execute()
        XCTAssertNil(mockAuthRepository.currentUser)
        
        // Third sign out
        try await signOutUseCase.execute()
        XCTAssertNil(mockAuthRepository.currentUser)
    }
    
    func testInitialization() {
        XCTAssertNotNil(signOutUseCase)
        XCTAssertTrue(signOutUseCase is SignOutUseCaseProtocol)
    }
    
    func testExecuteWithDifferentUsers() async throws {
        mockAuthRepository.shouldThrowOnSignOut = false
        
        let users = [
            User(id: "user-1", email: "user1@example.com", displayName: "User One"),
            User(id: "user-2", email: "user2@example.com", displayName: "User Two"),
            User(id: "user-3", email: nil, displayName: nil)
        ]
        
        for user in users {
            mockAuthRepository.currentUser = user
            try await signOutUseCase.execute()
            XCTAssertNil(mockAuthRepository.currentUser)
        }
    }
    
    func testExecuteErrorHandling() async {
        mockAuthRepository.shouldThrowOnSignOut = true
        mockAuthRepository.currentUser = User(id: "user-123", email: "test@example.com", displayName: "Test User")
        
        do {
            try await signOutUseCase.execute()
            XCTFail("Should have thrown an error")
        } catch let error as AuthError {
            XCTAssertEqual(error, AuthError.networkError)
            // User should still be signed in if sign out failed
            XCTAssertNotNil(mockAuthRepository.currentUser)
        } catch {
            XCTFail("Should have thrown AuthError")
        }
    }
    
    func testExecuteAfterSuccessfulSignOut() async throws {
        mockAuthRepository.shouldThrowOnSignOut = false
        mockAuthRepository.currentUser = User(id: "user-123", email: "test@example.com", displayName: "Test User")
        
        // Sign out successfully
        try await signOutUseCase.execute()
        XCTAssertNil(mockAuthRepository.currentUser)
        
        // Verify can execute again without issues
        try await signOutUseCase.execute()
        XCTAssertNil(mockAuthRepository.currentUser)
    }
    
    func testExecuteConcurrency() async throws {
        mockAuthRepository.shouldThrowOnSignOut = false
        mockAuthRepository.currentUser = User(id: "user-123", email: "test@example.com", displayName: "Test User")
        
        // Execute multiple sign out operations concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    do {
                        try await self.signOutUseCase.execute()
                    } catch {
                        // Ignore errors in concurrent execution
                    }
                }
            }
        }
        
        XCTAssertNil(mockAuthRepository.currentUser)
    }
}