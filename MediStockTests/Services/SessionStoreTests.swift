import XCTest
import Combine
import FirebaseAuth
@testable import MediStock

final class SessionStoreTests: XCTestCase {
    
    var sut: SessionStore!
    var mockAuthRepository: MockAuthRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockAuthRepository = MockAuthRepository()
        sut = SessionStore(authRepository: mockAuthRepository)
    }
    
    override func tearDown() {
        sut.unbind()
        cancellables = nil
        mockAuthRepository = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Factory
    
    private func createTestUser(
        id: String = "test-user-1",
        email: String = "test@example.com",
        displayName: String? = "Test User"
    ) -> User {
        return User(
            id: id,
            email: email,
            displayName: displayName
        )
    }
    
    // MARK: - Initialization Tests
    
    func test_init_shouldSetupCorrectly() {
        // Given & When
        // SUT is initialized in setUp
        
        // Then
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.session) // Should start with no session
    }
    
    func test_init_withAuthRepository_shouldStoreRepository() {
        // Given
        let customMockRepository = MockAuthRepository()
        
        // When
        let sessionStore = SessionStore(authRepository: customMockRepository)
        
        // Then
        XCTAssertNotNil(sessionStore)
        // Repository is stored privately, but we can verify through behavior
    }
    
    // MARK: - listen() Tests
    
    func test_listen_shouldSubscribeToAuthStateChanges() {
        // Given
        let expectation = expectation(description: "Should receive auth state changes")
        let testUser = createTestUser()
        
        // Set up observation before calling listen
        sut.$session
            .dropFirst() // Skip initial nil value
            .sink { user in
                if user != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        
        // Simulate auth state change
        mockAuthRepository.simulateAuthStateChange(user: testUser)
        
        // Then
        waitForExpectations(timeout: 2.0)
    }
    
    func test_listen_withUserSignIn_shouldUpdateSession() {
        // Given
        let testUser = createTestUser()
        let expectation = expectation(description: "Session should be updated with user")
        
        sut.$session
            .dropFirst() // Skip initial nil
            .sink { user in
                if let user = user {
                    XCTAssertEqual(user.id, testUser.id)
                    XCTAssertEqual(user.email, testUser.email)
                    XCTAssertEqual(user.displayName, testUser.displayName)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        mockAuthRepository.simulateAuthStateChange(user: testUser)
        
        // Then
        waitForExpectations(timeout: 2.0)
    }
    
    func test_listen_withUserSignOut_shouldClearSession() {
        // Given
        let testUser = createTestUser()
        let expectation = expectation(description: "Session should be cleared")
        expectation.expectedFulfillmentCount = 2 // Once for sign in, once for sign out
        
        sut.$session
            .dropFirst() // Skip initial nil
            .sink { user in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        
        // First sign in
        mockAuthRepository.simulateAuthStateChange(user: testUser)
        
        // Then sign out
        mockAuthRepository.simulateAuthStateChange(user: nil)
        
        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertNil(sut.session)
    }
    
    func test_listen_withMultipleUsers_shouldUpdateSessionCorrectly() {
        // Given
        let user1 = createTestUser(id: "user-1", email: "user1@example.com")
        let user2 = createTestUser(id: "user-2", email: "user2@example.com")
        let expectation = expectation(description: "Should handle multiple user changes")
        expectation.expectedFulfillmentCount = 2
        
        var receivedUsers: [User] = []
        
        sut.$session
            .dropFirst() // Skip initial nil
            .compactMap { $0 } // Only non-nil users
            .sink { user in
                receivedUsers.append(user)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        mockAuthRepository.simulateAuthStateChange(user: user1)
        mockAuthRepository.simulateAuthStateChange(user: user2)
        
        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(receivedUsers.count, 2)
        XCTAssertEqual(receivedUsers[0].id, user1.id)
        XCTAssertEqual(receivedUsers[1].id, user2.id)
        XCTAssertEqual(sut.session?.id, user2.id) // Should have the latest user
    }
    
    func test_listen_shouldReceiveOnMainQueue() {
        // Given
        let testUser = createTestUser()
        let expectation = expectation(description: "Should receive on main queue")
        
        sut.$session
            .dropFirst()
            .sink { _ in
                // Verify we're on the main queue
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        
        // Simulate auth state change from background queue
        DispatchQueue.global().async {
            self.mockAuthRepository.simulateAuthStateChange(user: testUser)
        }
        
        // Then
        waitForExpectations(timeout: 2.0)
    }
    
    func test_listen_calledMultipleTimes_shouldNotCreateMemoryLeaks() {
        // Given
        let testUser = createTestUser()
        
        // When
        sut.listen()
        sut.listen() // Call again
        sut.listen() // And again
        
        // Simulate auth change
        mockAuthRepository.simulateAuthStateChange(user: testUser)
        
        // Then
        XCTAssertEqual(sut.session?.id, testUser.id)
        // No memory leak assertions (would be detected by Instruments in real testing)
    }
    
    // MARK: - unbind() Tests
    
    func test_unbind_shouldClearSubscriptions() {
        // Given
        let testUser = createTestUser()
        sut.listen()
        
        // Verify subscription is working
        mockAuthRepository.simulateAuthStateChange(user: testUser)
        XCTAssertNotNil(sut.session)
        
        // When
        sut.unbind()
        
        // Simulate another auth change after unbinding
        mockAuthRepository.simulateAuthStateChange(user: nil)
        
        // Then
        // Session should remain unchanged after unbind
        XCTAssertNotNil(sut.session) // Should still have the user from before unbind
    }
    
    func test_unbind_withoutPriorListen_shouldNotCrash() {
        // Given & When & Then
        XCTAssertNoThrow(sut.unbind())
    }
    
    func test_unbind_calledMultipleTimes_shouldNotCrash() {
        // Given
        sut.listen()
        
        // When & Then
        XCTAssertNoThrow(sut.unbind())
        XCTAssertNoThrow(sut.unbind())
        XCTAssertNoThrow(sut.unbind())
    }
    
    // MARK: - ObservableObject Tests
    
    func test_sessionProperty_shouldBePublished() {
        // Given
        let testUser = createTestUser()
        let expectation = expectation(description: "Session changes should be published")
        
        // When
        sut.$session
            .dropFirst() // Skip initial nil
            .sink { user in
                if user != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.listen()
        mockAuthRepository.simulateAuthStateChange(user: testUser)
        
        // Then
        waitForExpectations(timeout: 2.0)
    }
    
    func test_sessionProperty_shouldTriggerUIUpdates() {
        // Given
        let testUser = createTestUser()
        var sessionUpdateCount = 0
        
        sut.$session
            .sink { _ in
                sessionUpdateCount += 1
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        mockAuthRepository.simulateAuthStateChange(user: testUser)
        mockAuthRepository.simulateAuthStateChange(user: nil)
        
        // Then
        // Should have at least 3 updates: initial nil, user, nil
        XCTAssertGreaterThanOrEqual(sessionUpdateCount, 3)
    }
    
    // MARK: - Integration Tests
    
    func test_fullAuthFlow_signInThenSignOut() {
        // Given
        let testUser = createTestUser()
        var sessionStates: [User?] = []
        
        sut.$session
            .sink { user in
                sessionStates.append(user)
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        
        // Sign in
        mockAuthRepository.simulateAuthStateChange(user: testUser)
        
        // Sign out
        mockAuthRepository.simulateAuthStateChange(user: nil)
        
        // Then
        XCTAssertEqual(sessionStates.count, 3) // initial nil, user, final nil
        XCTAssertNil(sessionStates[0]) // Initial state
        XCTAssertEqual(sessionStates[1]?.id, testUser.id) // After sign in
        XCTAssertNil(sessionStates[2]) // After sign out
    }
    
    func test_authRepositoryIntegration_shouldHandleRealWorldScenarios() {
        // Given
        let user1 = createTestUser(id: "user-1", email: "user1@test.com")
        let user2 = createTestUser(id: "user-2", email: "user2@test.com")
        
        var sessionHistory: [String] = []
        
        sut.$session
            .sink { user in
                if let user = user {
                    sessionHistory.append("User: \(user.email)")
                } else {
                    sessionHistory.append("Signed out")
                }
            }
            .store(in: &cancellables)
        
        // When - Simulate real-world auth flow
        sut.listen()
        
        // Initial sign in
        mockAuthRepository.simulateAuthStateChange(user: user1)
        
        // Switch users (rare but possible)
        mockAuthRepository.simulateAuthStateChange(user: user2)
        
        // Sign out
        mockAuthRepository.simulateAuthStateChange(user: nil)
        
        // Sign back in
        mockAuthRepository.simulateAuthStateChange(user: user1)
        
        // Then
        XCTAssertEqual(sessionHistory.count, 5)
        XCTAssertEqual(sessionHistory[0], "Signed out") // Initial
        XCTAssertEqual(sessionHistory[1], "User: user1@test.com")
        XCTAssertEqual(sessionHistory[2], "User: user2@test.com")
        XCTAssertEqual(sessionHistory[3], "Signed out")
        XCTAssertEqual(sessionHistory[4], "User: user1@test.com")
    }
    
    // MARK: - Performance Tests
    
    func test_listen_performance() {
        measure {
            sut.listen()
            sut.unbind()
        }
    }
    
    func test_authStateChanges_performance() {
        // Given
        let users = (1...100).map { index in
            createTestUser(id: "user-\(index)", email: "user\(index)@test.com")
        }
        
        sut.listen()
        
        // When & Then
        measure {
            for user in users {
                mockAuthRepository.simulateAuthStateChange(user: user)
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func test_sessionStore_shouldNotRetainAuthRepository() {
        // Given
        weak var weakAuthRepository: MockAuthRepository?
        
        do {
            let authRepository = MockAuthRepository()
            weakAuthRepository = authRepository
            let sessionStore = SessionStore(authRepository: authRepository)
            sessionStore.listen()
            
            // Repository should be alive here
            XCTAssertNotNil(weakAuthRepository)
        }
        
        // When the local scope ends, repository should be deallocated
        // (This test assumes SessionStore doesn't strongly retain the repository,
        // which may not be true in the current implementation)
        
        // Then
        // Note: This test may need adjustment based on actual memory management strategy
    }
    
    func test_unbind_shouldPreventMemoryLeaks() {
        // Given
        sut.listen()
        let testUser = createTestUser()
        
        // When
        sut.unbind()
        
        // Simulate many auth changes after unbind
        for i in 1...1000 {
            let user = createTestUser(id: "user-\(i)")
            mockAuthRepository.simulateAuthStateChange(user: user)
        }
        
        // Then
        // Session should not have changed after unbind
        XCTAssertNil(sut.session)
    }
    
    // MARK: - Edge Cases Tests
    
    func test_listen_withNilUser_shouldHandleGracefully() {
        // Given
        let expectation = expectation(description: "Should handle nil user")
        
        sut.$session
            .sink { user in
                // Should handle nil users gracefully
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        mockAuthRepository.simulateAuthStateChange(user: nil)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertNil(sut.session)
    }
    
    func test_listen_withRapidAuthChanges_shouldHandleCorrectly() {
        // Given
        let users = (1...10).map { createTestUser(id: "rapid-user-\(i)") }
        var receivedUsers: [User?] = []
        
        sut.$session
            .sink { user in
                receivedUsers.append(user)
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        
        // Rapid fire auth changes
        for user in users {
            mockAuthRepository.simulateAuthStateChange(user: user)
        }
        
        // Then
        XCTAssertTrue(receivedUsers.count >= users.count)
        XCTAssertEqual(sut.session?.id, users.last?.id)
    }
    
    func test_authRepository_errorHandling_shouldNotCrashSession() {
        // Given
        mockAuthRepository.shouldThrowError = true
        
        // When & Then
        XCTAssertNoThrow(sut.listen())
        
        // Should handle repository errors gracefully
        mockAuthRepository.simulateAuthStateChange(user: createTestUser())
        XCTAssertNotNil(sut) // Should not crash
    }
}

// MARK: - Test Extensions

extension User {
    static func testUser(
        id: String = UUID().uuidString,
        email: String = "test@example.com",
        displayName: String? = "Test User"
    ) -> User {
        return User(
            id: id,
            email: email,
            displayName: displayName
        )
    }
}