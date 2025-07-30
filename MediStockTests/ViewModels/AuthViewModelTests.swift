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
        
        // When
        await viewModel.signIn(email: email, password: password)
        
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
        
        // When
        await viewModel.signUp(email: email, password: password, displayName: displayName)
        
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
        await viewModel.signIn(email: "test@example.com", password: "password")
        XCTAssertTrue(viewModel.isAuthenticated)
        
        // When
        await viewModel.signOut()
        
        // Then
        XCTAssertEqual(mockRepository.signOutCallCount, 1)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
    }
    
    func testSignOutError() async {
        // Given - Sign in first
        await viewModel.signIn(email: "test@example.com", password: "password")
        mockRepository.shouldThrowError = true
        
        // When
        await viewModel.signOut()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        // User should still be signed in if sign out failed
        XCTAssertTrue(viewModel.isAuthenticated)
    }
    
    // MARK: - Authentication State Observer Tests
    
    func testAuthenticationStateObserver() {
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
        wait(for: [expectation], timeout: 1.0)
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
        wait(for: [expectation], timeout: 1.0)
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