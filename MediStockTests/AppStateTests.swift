import XCTest
@testable import MediStock

@MainActor
final class AppStateTests: XCTestCase {
    var sut: AppState!

    override func setUp() async throws {
        try await super.setUp()
        sut = AppState()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        // Test that AppState initializes with correct default values
        XCTAssertNil(sut.currentUser, "Current user should be nil initially")
        XCTAssertEqual(sut.selectedTab, 0, "Selected tab should be 0 initially")
        XCTAssertNil(sut.errorMessage, "Error message should be nil initially")
        XCTAssertFalse(sut.isLoading, "Loading should be false initially")
        XCTAssertFalse(sut.isAuthenticated, "Should not be authenticated initially")
    }

    func testInitializationWithDependencies() {
        // Test that AppState can be initialized with custom dependencies
        let mockMedicineRepo = MockMedicineRepository()
        let mockAisleRepo = MockAisleRepository()
        let mockHistoryRepo = MockHistoryRepository()

        let customAppState = AppState(
            medicineRepository: mockMedicineRepo,
            aisleRepository: mockAisleRepo,
            historyRepository: mockHistoryRepo
        )

        XCTAssertNotNil(customAppState.medicineRepository)
        XCTAssertNotNil(customAppState.aisleRepository)
        XCTAssertNotNil(customAppState.historyRepository)
    }

    // MARK: - Error Handling Tests

    func testClearError() {
        // Given
        sut.errorMessage = "Test error"

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage, "Error message should be cleared")
    }

    func testErrorMessagePersistsUntilCleared() {
        // Given
        sut.errorMessage = "Test error"

        // Then
        XCTAssertEqual(sut.errorMessage, "Test error")

        // When clearing
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Navigation Tests

    func testSelectedTabChanges() {
        // Given
        XCTAssertEqual(sut.selectedTab, 0)

        // When
        sut.selectedTab = 1

        // Then
        XCTAssertEqual(sut.selectedTab, 1)

        // When
        sut.selectedTab = 2

        // Then
        XCTAssertEqual(sut.selectedTab, 2)
    }

    // MARK: - Authentication State Tests

    func testIsAuthenticatedWhenUserIsNil() {
        // Given
        sut.currentUser = nil

        // Then
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testIsAuthenticatedWhenUserIsSet() {
        // Given
        sut.currentUser = User.mock(id: "test-user", email: "test@example.com", displayName: "Test User")

        // Then
        XCTAssertTrue(sut.isAuthenticated)
    }

    // MARK: - Mock Factory Tests

    func testMockFactoryCreatesStateWithUser() {
        // Given
        let mockUser = User.mock(id: "mock-id", email: "mock@example.com", displayName: "Mock User")

        // When
        let mockState = AppState.mock(user: mockUser)

        // Then
        XCTAssertNotNil(mockState.currentUser)
        XCTAssertEqual(mockState.currentUser?.id, "mock-id")
        XCTAssertEqual(mockState.currentUser?.email, "mock@example.com")
        XCTAssertTrue(mockState.isAuthenticated)
    }

    func testMockFactoryCreatesStateWithCustomRepository() {
        // Given
        let mockRepo = MockMedicineRepository()

        // When
        let mockState = AppState.mock(medicineRepository: mockRepo)

        // Then
        XCTAssertNotNil(mockState.medicineRepository)
    }
}
