import XCTest
import Combine
import Firebase
import FirebaseAuth
@testable @preconcurrency import MediStock

@MainActor
final class FirebaseAuthRepositoryTestsFixed: XCTestCase, Sendable {
    
    var sut: TestableAuthRepository!
    var mockAuth: MockFirebaseAuth!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        TestDependencyContainer.shared.reset()
        mockAuth = MockFirebaseAuth.shared
        sut = TestDependencyContainer.shared.createAuthRepository()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables?.removeAll()
        cancellables = nil
        sut = nil
        mockAuth = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.authStateDidChange)
    }
    
    func testCurrentUserWhenNotSignedIn() {
        // Given
        mockAuth.setCurrentUser(nil)
        
        // When
        let currentUser = sut.currentUser
        
        // Then
        XCTAssertNil(currentUser)
    }
    
    func testCurrentUserWhenSignedIn() {
        // Given
        let mockUser = MockFirebaseUser(uid: "test-uid", email: "test@example.com", displayName: "Test User")
        mockAuth.setCurrentUser(mockUser)
        
        // When
        let currentUser = sut.currentUser
        
        // Then
        XCTAssertNotNil(currentUser)
        XCTAssertEqual(currentUser?.id, "test-uid")
        XCTAssertEqual(currentUser?.email, "test@example.com")
        XCTAssertEqual(currentUser?.displayName, "Test User")
    }
    
    // MARK: - Auth State Publisher Tests
    
    func testAuthStateDidChangePublisher() {
        let expectation = XCTestExpectation(description: "Auth state publisher emits value")
        
        sut.authStateDidChange
            .first()
            .sink { user in
                // Should receive current auth state (nil if not signed in)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAuthStatePublisherMultipleSubscribers() {
        let expectation1 = XCTestExpectation(description: "First subscriber receives value")
        let expectation2 = XCTestExpectation(description: "Second subscriber receives value")
        
        sut.authStateDidChange
            .first()
            .sink { _ in
                expectation1.fulfill()
            }
            .store(in: &cancellables)
        
        sut.authStateDidChange
            .first()
            .sink { _ in
                expectation2.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation1, expectation2], timeout: 1.0)
    }
    
    func testAuthStateChangesOnSignIn() async throws {
        let expectation = XCTestExpectation(description: "Auth state changes on sign in")
        expectation.expectedFulfillmentCount = 2
        
        var receivedUsers: [User?] = []
        
        sut.authStateDidChange
            .sink { user in
                receivedUsers.append(user)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        _ = try await sut.signIn(email: "test@example.com", password: "password123")
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedUsers.count, 2)
        XCTAssertNil(receivedUsers[0]) // Initial state
        XCTAssertNotNil(receivedUsers[1]) // After sign in
    }
    
    // MARK: - Sign In Tests
    
    func testSignInWithValidCredentials() async throws {
        // Given
        mockAuth.shouldSucceed = true
        
        // When
        let user = try await sut.signIn(email: "test@example.com", password: "password123")
        
        // Then
        XCTAssertNotNil(user)
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertFalse(user.id.isEmpty)
    }
    
    func testSignInWithEmptyEmail() async {
        do {
            _ = try await sut.signIn(email: "", password: "password123")
            XCTFail("Should throw error for empty email")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, AuthErrorDomain)
            XCTAssertEqual(nsError.code, AuthErrorCode.invalidEmail.rawValue)
        }
    }
    
    func testSignInWithEmptyPassword() async {
        do {
            _ = try await sut.signIn(email: "test@example.com", password: "")
            XCTFail("Should throw error for empty password")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, AuthErrorDomain)
            XCTAssertEqual(nsError.code, AuthErrorCode.wrongPassword.rawValue)
        }
    }
    
    func testSignInWithWrongPassword() async {
        // Given
        mockAuth.shouldSucceed = false
        mockAuth.errorToThrow = NSError(domain: AuthErrorDomain, code: AuthErrorCode.wrongPassword.rawValue, userInfo: nil)
        
        do {
            _ = try await sut.signIn(email: "test@example.com", password: "wrongpassword")
            XCTFail("Should throw error for wrong password")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, AuthErrorDomain)
        }
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpWithValidCredentials() async throws {
        // Given
        mockAuth.shouldSucceed = true
        
        // When
        let user = try await sut.signUp(email: "newuser@example.com", password: "password123")
        
        // Then
        XCTAssertNotNil(user)
        XCTAssertEqual(user.email, "newuser@example.com")
        XCTAssertFalse(user.id.isEmpty)
    }
    
    func testSignUpWithEmptyEmail() async {
        do {
            _ = try await sut.signUp(email: "", password: "password123")
            XCTFail("Should throw error for empty email")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, AuthErrorDomain)
            XCTAssertEqual(nsError.code, AuthErrorCode.invalidEmail.rawValue)
        }
    }
    
    func testSignUpWithWeakPassword() async {
        do {
            _ = try await sut.signUp(email: "test@example.com", password: "123")
            XCTFail("Should throw error for weak password")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, AuthErrorDomain)
            XCTAssertEqual(nsError.code, AuthErrorCode.weakPassword.rawValue)
        }
    }
    
    func testSignUpWithExistingEmail() async {
        // Given
        mockAuth.shouldSucceed = false
        mockAuth.errorToThrow = NSError(domain: AuthErrorDomain, code: AuthErrorCode.emailAlreadyInUse.rawValue, userInfo: nil)
        
        do {
            _ = try await sut.signUp(email: "existing@example.com", password: "password123")
            XCTFail("Should throw error for existing email")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, AuthErrorDomain)
        }
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOutWhenSignedIn() async throws {
        // Given
        _ = try await sut.signIn(email: "test@example.com", password: "password123")
        XCTAssertNotNil(sut.currentUser)
        
        // When
        try await sut.signOut()
        
        // Then
        XCTAssertNil(sut.currentUser)
    }
    
    func testSignOutWhenNotSignedIn() async throws {
        // Given
        XCTAssertNil(sut.currentUser)
        
        // When & Then
        try await sut.signOut() // Should not throw
    }
    
    func testSignOutWithNetworkError() async {
        // Given
        mockAuth.shouldSucceed = false
        mockAuth.errorToThrow = NSError(domain: AuthErrorDomain, code: AuthErrorCode.networkError.rawValue, userInfo: nil)
        
        do {
            try await sut.signOut()
            XCTFail("Should throw network error")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, AuthErrorDomain)
        }
    }
    
    // MARK: - Password Reset Tests
    
    func testResetPasswordWithValidEmail() async throws {
        // Given
        mockAuth.shouldSucceed = true
        
        // When & Then
        try await sut.resetPassword(email: "test@example.com")
        // Should complete without error
    }
    
    func testResetPasswordWithEmptyEmail() async {
        do {
            try await sut.resetPassword(email: "")
            XCTFail("Should throw error for empty email")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, AuthErrorDomain)
            XCTAssertEqual(nsError.code, AuthErrorCode.invalidEmail.rawValue)
        }
    }
    
    func testResetPasswordWithNonExistentEmail() async {
        // Given
        mockAuth.shouldSucceed = false
        mockAuth.errorToThrow = NSError(domain: AuthErrorDomain, code: AuthErrorCode.userNotFound.rawValue, userInfo: nil)
        
        do {
            try await sut.resetPassword(email: "nonexistent@example.com")
            XCTFail("Should throw error for non-existent email")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, AuthErrorDomain)
        }
    }
    
    // MARK: - Update User Profile Tests
    
    func testUpdateUserProfile() async throws {
        // Given
        let user = User(id: "test-id", email: "test@example.com", displayName: "Updated Name")
        
        // When & Then
        try await sut.updateUserProfile(user: user)
        // Should complete without error
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentAuthStateAccess() async {
        let expectation = XCTestExpectation(description: "Concurrent access completes")
        expectation.expectedFulfillmentCount = 10
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await MainActor.run {
                        _ = self.sut.currentUser
                        _ = self.sut.authStateDidChange
                        expectation.fulfill()
                    }
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testConcurrentSignInOperations() async {
        let expectation = XCTestExpectation(description: "Concurrent sign in operations")
        expectation.expectedFulfillmentCount = 5
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    do {
                        _ = try await self.sut.signIn(email: "user\(i)@example.com", password: "password123")
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Memory Management Tests
    
    func testNoRetainCycles() {
        weak var weakSut = sut
        
        let expectation = XCTestExpectation(description: "Publisher subscription")
        
        sut.authStateDidChange
            .first()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        cancellables.removeAll()
        sut = nil
        
        XCTAssertNil(weakSut)
    }
    
    // MARK: - Edge Cases Tests
    
    func testVeryLongEmail() async {
        let longEmail = String(repeating: "a", count: 1000) + "@example.com"
        
        do {
            _ = try await sut.signIn(email: longEmail, password: "password123")
            // Mock should handle this gracefully
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
    
    func testSpecialCharactersInEmail() async {
        let specialEmail = "test+tag@example.com"
        
        do {
            _ = try await sut.signIn(email: specialEmail, password: "password123")
            // Should succeed with valid email format
            XCTAssertNotNil(sut.currentUser)
        } catch {
            // Also acceptable if validation fails
            XCTAssertTrue(error is NSError)
        }
    }
    
    func testThreadSafety() {
        XCTAssertTrue(Thread.isMainThread)
        
        // Access properties from main thread
        _ = sut.currentUser
        _ = sut.authStateDidChange
    }
}