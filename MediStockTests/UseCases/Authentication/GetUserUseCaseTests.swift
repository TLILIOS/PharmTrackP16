import XCTest
@testable import MediStock
@MainActor
final class GetUserUseCaseTests: XCTestCase {
    
    var mockAuthRepository: MockAuthRepository!
    var getUserUseCase: RealGetUserUseCase!
    
    override func setUp() {
        super.setUp()
        mockAuthRepository = MockAuthRepository()
        getUserUseCase = RealGetUserUseCase(authRepository: mockAuthRepository)
    }
    
    override func tearDown() {
        mockAuthRepository = nil
        getUserUseCase = nil
        super.tearDown()
    }
    
    func testExecuteSuccess() async throws {
        let expectedUser = User(id: "user-123", email: "test@example.com", displayName: "Test User")
        mockAuthRepository.currentUser = expectedUser
        
        let result = try await getUserUseCase.execute()
        
        XCTAssertEqual(result.id, expectedUser.id)
        XCTAssertEqual(result.email, expectedUser.email)
        XCTAssertEqual(result.displayName, expectedUser.displayName)
    }
    
    func testExecuteThrowsUserNotFoundWhenCurrentUserIsNil() async {
        mockAuthRepository.currentUser = nil
        
        do {
            _ = try await getUserUseCase.execute()
            XCTFail("Should have thrown AuthError.userNotFound")
        } catch {
            XCTAssertEqual(error as? AuthError, AuthError.userNotFound)
        }
    }
    
    func testExecuteWithDifferentUsers() async throws {
        let users = [
            User(id: "user-1", email: "user1@example.com", displayName: "User One"),
            User(id: "user-2", email: "user2@example.com", displayName: "User Two"),
            User(id: "user-3", email: nil, displayName: nil)
        ]
        
        for user in users {
            mockAuthRepository.currentUser = user
            let result = try await getUserUseCase.execute()
            XCTAssertEqual(result.id, user.id)
            XCTAssertEqual(result.email, user.email)
            XCTAssertEqual(result.displayName, user.displayName)
        }
    }
    
    func testInitialization() {
        XCTAssertNotNil(getUserUseCase)
        XCTAssertTrue(getUserUseCase != nil)
    }
    
    func testExecuteMultipleTimes() async throws {
        let user = User(id: "user-123", email: "test@example.com", displayName: "Test User")
        mockAuthRepository.currentUser = user
        
        for _ in 0..<5 {
            let result = try await getUserUseCase.execute()
            XCTAssertEqual(result.id, user.id)
        }
    }
    
    func testExecuteAfterUserChanges() async throws {
        let user1 = User(id: "user-1", email: "user1@example.com", displayName: "User One")
        let user2 = User(id: "user-2", email: "user2@example.com", displayName: "User Two")
        
        mockAuthRepository.currentUser = user1
        let result1 = try await getUserUseCase.execute()
        XCTAssertEqual(result1.id, user1.id)
        
        mockAuthRepository.currentUser = user2
        let result2 = try await getUserUseCase.execute()
        XCTAssertEqual(result2.id, user2.id)
    }
}
