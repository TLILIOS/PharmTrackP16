import XCTest
import Combine
@testable import MediStock

// MARK: - ViewModelBase Tests
/// Tests complets pour ViewModelBase (Protocol et BaseViewModel)
/// Teste la gestion centralisée des erreurs et du loading
/// Auteur: TLILI HAMDI

@MainActor
final class ViewModelBaseTests: XCTestCase {

    // MARK: - Test ViewModel Implementation

    /// Test ViewModel concret qui implémente ViewModelBase
    class TestViewModel: BaseViewModel {
        var operationExecuted = false
        var shouldThrowError = false
        var errorToThrow: Error?

        func testOperation() async throws {
            operationExecuted = true
            if shouldThrowError {
                throw errorToThrow ?? TestError.genericError
            }
        }

        func testOperationWithResult() async throws -> String {
            operationExecuted = true
            if shouldThrowError {
                throw errorToThrow ?? TestError.genericError
            }
            return "Success"
        }
    }

    enum TestError: LocalizedError {
        case genericError
        case validationFailed
        case authFailed

        var errorDescription: String? {
            switch self {
            case .genericError:
                return "Generic error occurred"
            case .validationFailed:
                return "Validation failed"
            case .authFailed:
                return "Authentication failed"
            }
        }
    }

    // MARK: - Properties

    private var sut: TestViewModel!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = TestViewModel()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        sut = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.operationExecuted)
    }

    // MARK: - performOperation (with return value) Tests

    func testPerformOperationWithResultSuccess() async {
        // When
        let result = await sut.performOperation {
            try await self.sut.testOperationWithResult()
        }

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "Success")
        XCTAssertTrue(sut.operationExecuted)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testPerformOperationWithResultFailure() async {
        // Given
        sut.shouldThrowError = true
        sut.errorToThrow = TestError.genericError

        // When
        let result = await sut.performOperation {
            try await self.sut.testOperationWithResult()
        }

        // Then
        XCTAssertNil(result)
        XCTAssertTrue(sut.operationExecuted)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Generic error") ?? false)
    }

    func testPerformOperationWithResultLoadingState() async {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []

        let cancellable = sut.$isLoading.sink { isLoading in
            loadingStates.append(isLoading)
            if loadingStates.count == 3 {
                expectation.fulfill()
            }
        }

        // When
        _ = await sut.performOperation {
            try await self.sut.testOperationWithResult()
        }

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(loadingStates, [false, true, false])
        cancellable.cancel()
    }

    func testPerformOperationWithResultValidationError() async {
        // Given
        let validationError = ValidationError.emptyName
        sut.shouldThrowError = true
        sut.errorToThrow = validationError

        // When
        let result = await sut.performOperation {
            try await self.sut.testOperationWithResult()
        }

        // Then
        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, validationError.localizedDescription)
    }

    func testPerformOperationWithResultAuthError() async {
        // Given
        let authError = AuthError.userNotFound
        sut.shouldThrowError = true
        sut.errorToThrow = authError

        // When
        let result = await sut.performOperation {
            try await self.sut.testOperationWithResult()
        }

        // Then
        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, authError.localizedDescription)
    }

    // MARK: - performOperation (void) Tests

    func testPerformOperationVoidSuccess() async {
        // When
        await sut.performOperation {
            try await self.sut.testOperation()
        }

        // Then
        XCTAssertTrue(sut.operationExecuted)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testPerformOperationVoidFailure() async {
        // Given
        sut.shouldThrowError = true
        sut.errorToThrow = TestError.genericError

        // When
        await sut.performOperation {
            try await self.sut.testOperation()
        }

        // Then
        XCTAssertTrue(sut.operationExecuted)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Generic error") ?? false)
    }

    func testPerformOperationVoidLoadingState() async {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []

        let cancellable = sut.$isLoading.sink { isLoading in
            loadingStates.append(isLoading)
            if loadingStates.count == 3 {
                expectation.fulfill()
            }
        }

        // When
        await sut.performOperation {
            try await self.sut.testOperation()
        }

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(loadingStates, [false, true, false])
        cancellable.cancel()
    }

    // MARK: - handleError Tests

    func testHandleErrorGenericError() {
        // Given
        let error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        // When
        sut.handleError(error)

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Test error") ?? false)
    }

    func testHandleErrorValidationError() {
        // Given
        let error = ValidationError.missingRequiredField(field: "email")

        // When
        sut.handleError(error)

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, error.localizedDescription)
    }

    func testHandleErrorAuthError() {
        // Given
        let error = AuthError.userNotFound

        // When
        sut.handleError(error)

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, error.localizedDescription)
    }

    func testHandleErrorClearsOnSuccess() async {
        // Given - First operation fails
        sut.shouldThrowError = true
        await sut.performOperation {
            try await self.sut.testOperation()
        }
        XCTAssertNotNil(sut.errorMessage)

        // When - Second operation succeeds
        sut.shouldThrowError = false
        await sut.performOperation {
            try await self.sut.testOperation()
        }

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - clearError Tests

    func testClearError() {
        // Given
        sut.errorMessage = "Test error"

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    func testClearErrorWhenNil() {
        // Given
        sut.errorMessage = nil

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Error Message Observable Tests

    func testErrorMessagePublisher() {
        // Given
        let expectation = XCTestExpectation(description: "Error message published")
        var receivedMessages: [String?] = []

        let cancellable = sut.$errorMessage.sink { message in
            receivedMessages.append(message)
            if receivedMessages.count == 3 {
                expectation.fulfill()
            }
        }

        // When
        sut.errorMessage = "Error 1"
        sut.errorMessage = "Error 2"

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedMessages.count, 3) // nil, "Error 1", "Error 2"
        cancellable.cancel()
    }

    // MARK: - Multiple Operations Tests

    func testMultipleOperationsSequential() async {
        // When
        await sut.performOperation {
            try await self.sut.testOperation()
        }

        await sut.performOperation {
            try await self.sut.testOperation()
        }

        // Then
        XCTAssertTrue(sut.operationExecuted)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testMultipleOperationsMixedResults() async {
        // When - First succeeds
        let result1 = await sut.performOperation {
            try await self.sut.testOperationWithResult()
        }

        // Then
        XCTAssertNotNil(result1)
        XCTAssertNil(sut.errorMessage)

        // When - Second fails
        sut.shouldThrowError = true
        let result2 = await sut.performOperation {
            try await self.sut.testOperationWithResult()
        }

        // Then
        XCTAssertNil(result2)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Defer Tests

    func testLoadingStateAlwaysResetOnSuccess() async {
        // When
        _ = await sut.performOperation {
            try await self.sut.testOperationWithResult()
        }

        // Then - Loading should be false even after success
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadingStateAlwaysResetOnFailure() async {
        // Given
        sut.shouldThrowError = true

        // When
        _ = await sut.performOperation {
            try await self.sut.testOperationWithResult()
        }

        // Then - Loading should be false even after failure
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - BaseViewModel Class Tests

    func testBaseViewModelInitialization() {
        // Given
        let baseViewModel = BaseViewModel()

        // Then
        XCTAssertFalse(baseViewModel.isLoading)
        XCTAssertNil(baseViewModel.errorMessage)
    }

    func testBaseViewModelInheritance() {
        // Then
        XCTAssertTrue(sut is BaseViewModel)
        XCTAssertTrue(sut is ViewModelBase)
        XCTAssertTrue(sut is ObservableObject)
    }

    // MARK: - Protocol Conformance Tests

    func testViewModelBaseProtocolConformance() {
        // Given
        let viewModel: any ViewModelBase = sut

        // Then - Should be able to access protocol properties
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testViewModelBaseProtocolMethods() async {
        // Given
        let viewModel: any ViewModelBase = sut

        // When
        let result = await viewModel.performOperation {
            return "Test"
        }

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "Test")
    }

    // MARK: - Error Recovery Tests

    func testErrorRecoveryAfterMultipleFailures() async {
        // Given
        sut.shouldThrowError = true

        // When - Multiple failures
        await sut.performOperation { try await self.sut.testOperation() }
        XCTAssertNotNil(sut.errorMessage)

        await sut.performOperation { try await self.sut.testOperation() }
        XCTAssertNotNil(sut.errorMessage)

        // When - Success after failures
        sut.shouldThrowError = false
        await sut.performOperation { try await self.sut.testOperation() }

        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentOperations() async {
        // When - Launch multiple operations concurrently
        async let op1 = sut.performOperation { try await self.sut.testOperation() }
        async let op2 = sut.performOperation { try await self.sut.testOperation() }
        async let op3 = sut.performOperation { try await self.sut.testOperation() }

        await op1
        await op2
        await op3

        // Then
        XCTAssertTrue(sut.operationExecuted)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Performance Tests

    func testPerformOperationPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Operation complete")
            Task {
                await sut.performOperation {
                    try await self.sut.testOperation()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }

    func testHandleErrorPerformance() {
        let error = NSError(domain: "Test", code: 1)

        measure {
            sut.handleError(error)
            sut.clearError()
        }
    }
}
