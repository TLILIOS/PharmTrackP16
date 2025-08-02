import XCTest
import Combine
@testable import MediStock

@MainActor
class AuthViewModelTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    var mockRepository: MockAuthRepository!
    var cancellables: Set<AnyCancellable>!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockRepository = MockAuthRepository()
        viewModel = AuthViewModel(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Sign In Tests
    
    func testSignInSuccess() async {
        // Given
        let email = "test@example.com"
        let password = "password123"
        let expectation = XCTestExpectation(description: "Auth state updated")
        
        // Observer l'authentification
        viewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.signIn(email: email, password: password)
        
        // Attendre que le publisher propage les changements
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(mockRepository.signInCallCount, 1)
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.email, email)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSignInError() async {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        await viewModel.signIn(email: "test@example.com", password: "wrong")
        
        // Then
        XCTAssertEqual(mockRepository.signInCallCount, 1)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Invalid credentials")
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpSuccess() async {
        // Given
        let email = "new@example.com"
        let password = "newPassword123"
        let displayName = "New User"
        let expectation = XCTestExpectation(description: "Auth state updated")
        
        // Observer l'authentification
        viewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.signUp(email: email, password: password, displayName: displayName)
        
        // Attendre que le publisher propage les changements
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.email, email)
        XCTAssertEqual(viewModel.currentUser?.displayName, displayName)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSignUpError() async {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        await viewModel.signUp(email: "test@example.com", password: "pass", displayName: "Test")
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOutSuccess() async {
        // Given - Sign in first
        let signInExpectation = XCTestExpectation(description: "Sign in completed")
        
        viewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    signInExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.signIn(email: "test@example.com", password: "password")
        await fulfillment(of: [signInExpectation], timeout: 1.0)
        
        XCTAssertTrue(viewModel.isAuthenticated)
        
        // When
        let signOutExpectation = XCTestExpectation(description: "Sign out completed")
        
        viewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if !isAuthenticated {
                    signOutExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.signOut()
        await fulfillment(of: [signOutExpectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(mockRepository.signOutCallCount, 1)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
    }
    
    func testSignOutError() async {
        // Given - Sign in first
        let signInExpectation = XCTestExpectation(description: "Sign in completed")
        
        viewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    signInExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.signIn(email: "test@example.com", password: "password")
        await fulfillment(of: [signInExpectation], timeout: 1.0)
        
        // Verify user is signed in
        XCTAssertTrue(viewModel.isAuthenticated)
        
        // Configure error for sign out
        mockRepository.shouldThrowError = true
        
        // When
        await viewModel.signOut()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        // User should still be signed in if sign out failed
        XCTAssertTrue(viewModel.isAuthenticated)
    }
    
    // MARK: - Authentication State Observer Tests
    
    func testAuthenticationStateObserver() async {
        // Given
        let expectation = XCTestExpectation(description: "Auth state changed")
        
        viewModel.$isAuthenticated
            .dropFirst() // Skip initial value
            .sink { isAuthenticated in
                XCTAssertTrue(isAuthenticated)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        mockRepository.currentUser = User.mock()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateDuringSignIn() async {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changed")
        var loadingStates: [Bool] = []
        
        viewModel.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count == 3 { // initial false, true, false
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.signIn(email: "test@example.com", password: "password")
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates, [false, true, false])
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() {
        // Given
        viewModel.errorMessage = "Some error"
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
}