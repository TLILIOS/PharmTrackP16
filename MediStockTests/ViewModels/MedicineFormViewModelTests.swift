import XCTest
import Combine
@testable @preconcurrency import MediStock

@MainActor
final class MedicineFormViewModelTests: XCTestCase, Sendable {
    
    var sut: MedicineFormViewModel!
    var mockGetMedicineUseCase: MockGetMedicineUseCase!
    var mockGetAislesUseCase: MockGetAislesUseCase!
    var mockAddMedicineUseCase: MockAddMedicineUseCase!
    var mockUpdateMedicineUseCase: MockUpdateMedicineUseCase!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        mockGetMedicineUseCase = MockGetMedicineUseCase()
        mockGetAislesUseCase = MockGetAislesUseCase()
        mockAddMedicineUseCase = MockAddMedicineUseCase()
        mockUpdateMedicineUseCase = MockUpdateMedicineUseCase()
        
        sut = MedicineFormViewModel(
            getMedicineUseCase: mockGetMedicineUseCase,
            getAislesUseCase: mockGetAislesUseCase,
            addMedicineUseCase: mockAddMedicineUseCase,
            updateMedicineUseCase: mockUpdateMedicineUseCase
        )
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockGetMedicineUseCase = nil
        mockGetAislesUseCase = nil
        mockAddMedicineUseCase = nil
        mockUpdateMedicineUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_WithoutMedicine() {
        XCTAssertNil(sut.medicine)
        XCTAssertEqual(sut.aisles.count, 0)
        XCTAssertEqual(sut.state, .idle)
    }
    
    func testInitialization_WithMedicine() {
        // Given
        let testMedicine = TestHelpers.createTestMedicine(
            id: "test-med",
            name: "Test Medicine"
        )
        
        // When
        sut = MedicineFormViewModel(
            getMedicineUseCase: mockGetMedicineUseCase,
            getAislesUseCase: mockGetAislesUseCase,
            addMedicineUseCase: mockAddMedicineUseCase,
            updateMedicineUseCase: mockUpdateMedicineUseCase,
            medicine: testMedicine
        )
        
        // Then
        XCTAssertNotNil(sut.medicine)
        XCTAssertEqual(sut.medicine?.id, "test-med")
        XCTAssertEqual(sut.medicine?.name, "Test Medicine")
        XCTAssertEqual(sut.state, .idle)
    }
    
    // MARK: - Published Properties Tests
    
    func testMedicinePropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Medicine change through add")
        
        let testMedicine = TestHelpers.createTestMedicine(
            name: "Added Medicine"
        )
        
        sut.$medicine
            .dropFirst()
            .sink { medicine in
                if medicine?.name == "Added Medicine" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.addMedicine(testMedicine)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testAislesPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Aisles change through fetch")
        
        let testAisles = [
            TestHelpers.createTestAisle(id: "aisle1", name: "Aisle 1", colorHex: "#007AFF"),
            TestHelpers.createTestAisle(id: "aisle2", name: "Aisle 2", colorHex: "#007AFF")
        ]
        mockGetAislesUseCase.returnAisles = testAisles
        
        sut.$aisles
            .dropFirst()
            .sink { aisles in
                if aisles.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.fetchAisles()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testStatePropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "State change through fetch")
        
        mockGetAislesUseCase.returnAisles = []
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                if case .loading = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.fetchAisles()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Reset State Tests
    
    func testResetState() async {
        // Given - First trigger a state change
        mockGetAislesUseCase.shouldThrowError = true
        mockGetAislesUseCase.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        await sut.fetchAisles()
        
        // Verify we're in error state
        if case .error = sut.state {
            // Expected
        } else {
            XCTFail("Expected error state")
        }
        
        // When
        sut.resetState()
        
        // Then
        XCTAssertEqual(sut.state, .idle)
    }
    
    // MARK: - Fetch Aisles Tests
    
    func testFetchAisles_Success() async {
        // Given
        let testAisles = [
            TestHelpers.createTestAisle(id: "aisle1", name: "Pharmacy", colorHex: "#007AFF"),
            TestHelpers.createTestAisle(id: "aisle2", name: "Emergency", colorHex: "#FF0000"),
            TestHelpers.createTestAisle(id: "aisle3", name: "Storage", colorHex: "#00FF00")
        ]
        mockGetAislesUseCase.returnAisles = testAisles
        
        // When
        await sut.fetchAisles()
        
        // Then
        XCTAssertEqual(sut.state, .idle) // Should return to idle after successful fetch
        XCTAssertEqual(sut.aisles.count, 3)
        XCTAssertEqual(sut.aisles[0].name, "Pharmacy")
        XCTAssertEqual(sut.aisles[1].name, "Emergency")
        XCTAssertEqual(sut.aisles[2].name, "Storage")
        XCTAssertEqual(mockGetAislesUseCase.callCount, 1)
    }
    
    func testFetchAisles_WithError_ShowsError() async {
        // Given
        mockGetAislesUseCase.shouldThrowError = true
        mockGetAislesUseCase.errorToThrow = NSError(
            domain: "AisleError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to load aisles"]
        )
        
        // When
        await sut.fetchAisles()
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Failed to load aisles"))
        } else {
            XCTFail("Expected error state")
        }
        XCTAssertEqual(sut.aisles.count, 0)
    }
    
    func testFetchAisles_LoadingStates() async {
        // Given
        mockGetAislesUseCase.returnAisles = []
        
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        loadingExpectation.expectedFulfillmentCount = 2 // loading then idle
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                loadingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.fetchAisles()
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 2.0)
        XCTAssertEqual(sut.state, .idle)
    }
    
    func testFetchAisles_EmptyResult() async {
        // Given
        mockGetAislesUseCase.returnAisles = []
        
        // When
        await sut.fetchAisles()
        
        // Then
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.aisles.count, 0)
        XCTAssertEqual(mockGetAislesUseCase.callCount, 1)
    }
    
    // MARK: - Add Medicine Tests
    
    func testAddMedicine_Success() async {
        // Given
        let testMedicine = TestHelpers.createTestMedicine(
            id: "new-medicine",
            name: "New Medicine",
            description: "Test Description",
            dosage: "250mg"
        )
        
        // When
        await sut.addMedicine(testMedicine)
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertNotNil(sut.medicine)
        XCTAssertEqual(sut.medicine?.id, "new-medicine")
        XCTAssertEqual(sut.medicine?.name, "New Medicine")
        XCTAssertEqual(sut.medicine?.dosage, "250mg")
        
        // Verify use case was called
        XCTAssertEqual(mockAddMedicineUseCase.addedMedicines.count, 1)
        XCTAssertEqual(mockAddMedicineUseCase.addedMedicines[0].name, "New Medicine")
    }
    
    func testAddMedicine_WithError_ShowsError() async {
        // Given
        let testMedicine = TestHelpers.createTestMedicine(name: "Test Medicine")
        
        mockAddMedicineUseCase.shouldThrowError = true
        mockAddMedicineUseCase.errorToThrow = NSError(
            domain: "AddError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to add medicine"]
        )
        
        // When
        await sut.addMedicine(testMedicine)
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Failed to add medicine"))
        } else {
            XCTFail("Expected error state")
        }
        
        // Medicine is reset on error
        XCTAssertNil(sut.medicine)
        XCTAssertEqual(mockAddMedicineUseCase.addedMedicines.count, 0)
    }
    
    func testAddMedicine_LoadingStates() async {
        // Given
        let testMedicine = TestHelpers.createTestMedicine(name: "Test Medicine")
        
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        loadingExpectation.expectedFulfillmentCount = 2 // loading then success
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                loadingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.addMedicine(testMedicine)
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 2.0)
        XCTAssertEqual(sut.state, .success)
    }
    
    func testAddMedicine_WithComplexData() async {
        // Given
        let complexMedicine = TestHelpers.createTestMedicine(
            id: "complex-med",
            name: "Complex Medicine",
            description: "A very detailed description of this medicine",
            dosage: "500mg twice daily",
            form: "Extended Release Tablet",
            reference: "COMP-001",
            unit: "tablet",
            currentQuantity: 100,
            maxQuantity: 200,
            warningThreshold: 50,
            criticalThreshold: 20
        )
        
        // When
        await sut.addMedicine(complexMedicine)
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.medicine?.name, "Complex Medicine")
        XCTAssertEqual(sut.medicine?.description, "A very detailed description of this medicine")
        XCTAssertEqual(sut.medicine?.dosage, "500mg twice daily")
        XCTAssertEqual(sut.medicine?.form, "Extended Release Tablet")
        XCTAssertEqual(sut.medicine?.currentQuantity, 100)
        XCTAssertEqual(sut.medicine?.maxQuantity, 200)
    }
    
    // MARK: - Update Medicine Tests
    
    func testUpdateMedicine_Success() async {
        // Given
        let originalMedicine = TestHelpers.createTestMedicine(
            id: "existing-med",
            name: "Original Medicine",
            dosage: "100mg"
        )
        
        let updatedMedicine = TestHelpers.createTestMedicine(
            id: "existing-med",
            name: "Updated Medicine",
            dosage: "200mg"
        )
        
        // Set initial medicine
        sut = MedicineFormViewModel(
            getMedicineUseCase: mockGetMedicineUseCase,
            getAislesUseCase: mockGetAislesUseCase,
            addMedicineUseCase: mockAddMedicineUseCase,
            updateMedicineUseCase: mockUpdateMedicineUseCase,
            medicine: originalMedicine
        )
        
        // When
        await sut.updateMedicine(updatedMedicine)
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.medicine?.name, "Updated Medicine")
        XCTAssertEqual(sut.medicine?.dosage, "200mg")
        
        // Verify use case was called
        XCTAssertEqual(mockUpdateMedicineUseCase.updatedMedicines.count, 1)
        XCTAssertEqual(mockUpdateMedicineUseCase.updatedMedicines[0].name, "Updated Medicine")
    }
    
    func testUpdateMedicine_WithError_ShowsError() async {
        // Given
        let testMedicine = TestHelpers.createTestMedicine(name: "Test Medicine")
        
        mockUpdateMedicineUseCase.shouldThrowError = true
        mockUpdateMedicineUseCase.errorToThrow = NSError(
            domain: "UpdateError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to update medicine"]
        )
        
        // When
        await sut.updateMedicine(testMedicine)
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Failed to update medicine"))
        } else {
            XCTFail("Expected error state")
        }
        
        // Medicine is reset on error
        XCTAssertNil(sut.medicine)
        XCTAssertEqual(mockUpdateMedicineUseCase.updatedMedicines.count, 0)
    }
    
    func testUpdateMedicine_LoadingStates() async {
        // Given
        let testMedicine = TestHelpers.createTestMedicine(name: "Test Medicine")
        
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        loadingExpectation.expectedFulfillmentCount = 2 // loading then success
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                loadingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.updateMedicine(testMedicine)
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 2.0)
        XCTAssertEqual(sut.state, .success)
    }
    
    // MARK: - Refresh Medicine Tests
    
    func testRefreshMedicine_Success() async {
        // Given
        let refreshedMedicine = TestHelpers.createTestMedicine(
            id: "refresh-med",
            name: "Refreshed Medicine",
            description: "Updated description"
        )
        mockGetMedicineUseCase.medicine = refreshedMedicine
        
        // When
        await sut.refreshMedicine(id: "refresh-med")
        
        // Then
        XCTAssertEqual(sut.state, .idle) // Should return to idle after successful refresh
        XCTAssertNotNil(sut.medicine)
        XCTAssertEqual(sut.medicine?.id, "refresh-med")
        XCTAssertEqual(sut.medicine?.name, "Refreshed Medicine")
        XCTAssertEqual(sut.medicine?.description, "Updated description")
        XCTAssertEqual(mockGetMedicineUseCase.lastId, "refresh-med")
    }
    
    func testRefreshMedicine_WithError_ShowsError() async {
        // Given
        mockGetMedicineUseCase.shouldThrowError = true
        mockGetMedicineUseCase.errorToThrow = NSError(
            domain: "RefreshError",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Medicine not found"]
        )
        
        // When
        await sut.refreshMedicine(id: "nonexistent-med")
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Medicine not found"))
        } else {
            XCTFail("Expected error state")
        }
        XCTAssertEqual(mockGetMedicineUseCase.lastId, "nonexistent-med")
    }
    
    func testRefreshMedicine_LoadingStates() async {
        // Given
        let testMedicine = TestHelpers.createTestMedicine(id: "test-med")
        mockGetMedicineUseCase.medicine = testMedicine
        
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        loadingExpectation.expectedFulfillmentCount = 2 // loading then idle
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                loadingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.refreshMedicine(id: "test-med")
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 2.0)
        XCTAssertEqual(sut.state, .idle)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow_FetchAislesAndAddMedicine() async {
        // Given
        let testAisles = [
            TestHelpers.createTestAisle(id: "aisle1", name: "Pharmacy", colorHex: "#007AFF")
        ]
        let newMedicine = TestHelpers.createTestMedicine(
            name: "New Medicine",
            aisleId: "aisle1"
        )
        
        mockGetAislesUseCase.returnAisles = testAisles
        
        // When - Fetch aisles first
        await sut.fetchAisles()
        
        // Then - Verify aisles loaded
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.aisles.count, 1)
        
        // When - Add medicine
        await sut.addMedicine(newMedicine)
        
        // Then - Verify medicine added
        XCTAssertEqual(sut.state, .success)
        XCTAssertNotNil(sut.medicine)
        XCTAssertEqual(sut.medicine?.name, "New Medicine")
        XCTAssertEqual(sut.medicine?.aisleId, "aisle1")
        
        // Verify use cases were called
        XCTAssertEqual(mockGetAislesUseCase.callCount, 1)
        XCTAssertEqual(mockAddMedicineUseCase.addedMedicines.count, 1)
    }
    
    func testEditWorkflow_RefreshAndUpdate() async {
        // Given
        let originalMedicine = TestHelpers.createTestMedicine(
            id: "edit-med",
            name: "Original Name",
            dosage: "100mg"
        )
        let updatedMedicine = TestHelpers.createTestMedicine(
            id: "edit-med",
            name: "Updated Name",
            dosage: "200mg"
        )
        
        mockGetMedicineUseCase.medicine = originalMedicine
        
        // When - Refresh medicine first
        await sut.refreshMedicine(id: "edit-med")
        
        // Then - Verify original loaded
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.medicine?.name, "Original Name")
        
        // When - Update medicine
        await sut.updateMedicine(updatedMedicine)
        
        // Then - Verify medicine updated
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.medicine?.name, "Updated Name")
        XCTAssertEqual(sut.medicine?.dosage, "200mg")
        
        // Verify use cases were called
        XCTAssertEqual(mockGetMedicineUseCase.lastId, "edit-med")
        XCTAssertEqual(mockUpdateMedicineUseCase.updatedMedicines.count, 1)
    }
    
    func testStateConsistency_MultipleOperations() async {
        // Given
        let testAisles = [TestHelpers.createTestAisle(id: "aisle1", name: "Test Aisle", colorHex: "#007AFF")]
        let testMedicine = TestHelpers.createTestMedicine(name: "Test Medicine")
        
        mockGetAislesUseCase.returnAisles = testAisles
        
        // When - Perform multiple operations
        await sut.fetchAisles()
        XCTAssertEqual(sut.state, .idle)
        
        await sut.addMedicine(testMedicine)
        XCTAssertEqual(sut.state, .success)
        
        sut.resetState()
        XCTAssertEqual(sut.state, .idle)
        
        // Then - State should be consistent
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.aisles.count, 1)
        XCTAssertNotNil(sut.medicine)
    }
    
    func testConcurrentOperations() async {
        // Given
        let testAisles = [TestHelpers.createTestAisle(id: "aisle1", name: "Test Aisle", colorHex: "#007AFF")]
        let testMedicine = TestHelpers.createTestMedicine(name: "Test Medicine")
        
        mockGetAislesUseCase.returnAisles = testAisles
        mockGetMedicineUseCase.medicine = testMedicine
        
        // When - Start operations concurrently
        async let fetchTask: () = sut.fetchAisles()
        async let refreshTask: () = sut.refreshMedicine(id: "test-id")
        
        // Wait for both to complete
        await fetchTask
        await refreshTask
        
        // Then - Both should succeed without conflicts
        XCTAssertEqual(sut.aisles.count, 1)
        XCTAssertNotNil(sut.medicine)
    }
    
    // MARK: - Edge Cases Tests
    
    func testAddMedicine_WithMinimalData() async {
        // Given
        let minimalMedicine = Medicine(
            id: "minimal",
            name: "Minimal Medicine",
            description: "",
            dosage: "",
            form: "",
            reference: "",
            unit: "",
            currentQuantity: 0,
            maxQuantity: 0,
            warningThreshold: 0,
            criticalThreshold: 0,
            expiryDate: nil,
            aisleId: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When
        await sut.addMedicine(minimalMedicine)
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.medicine?.name, "Minimal Medicine")
        XCTAssertEqual(sut.medicine?.description, "")
        XCTAssertEqual(sut.medicine?.currentQuantity, 0)
    }
    
    func testFetchAisles_LargeDataset() async {
        // Given
        let largeAisleList = (1...50).map { index in
            TestHelpers.createTestAisle(
                id: "aisle\(index)",
                name: "Aisle \(index)",
                colorHex: "#007AFF"
            )
        }
        mockGetAislesUseCase.returnAisles = largeAisleList
        
        // When
        await sut.fetchAisles()
        
        // Then
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.aisles.count, 50)
        XCTAssertEqual(sut.aisles[0].name, "Aisle 1")
        XCTAssertEqual(sut.aisles[49].name, "Aisle 50")
    }
    
    func testErrorRecovery() async {
        // Given
        mockAddMedicineUseCase.shouldThrowError = true
        mockAddMedicineUseCase.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        let testMedicine = TestHelpers.createTestMedicine(name: "Test Medicine")
        
        // When - First attempt fails
        await sut.addMedicine(testMedicine)
        
        // Then - Should be in error state
        if case .error = sut.state {
            // Expected
        } else {
            XCTFail("Expected error state")
        }
        
        // When - Fix error and retry
        mockAddMedicineUseCase.shouldThrowError = false
        await sut.addMedicine(testMedicine)
        
        // Then - Should succeed
        XCTAssertEqual(sut.state, .success)
        XCTAssertNotNil(sut.medicine)
    }
    
    func testFormModeDetection() {
        // Test Add Mode
        XCTAssertNil(sut.medicine)
        
        // Test Edit Mode
        let editMedicine = TestHelpers.createTestMedicine(name: "Edit Medicine")
        sut = MedicineFormViewModel(
            getMedicineUseCase: mockGetMedicineUseCase,
            getAislesUseCase: mockGetAislesUseCase,
            addMedicineUseCase: mockAddMedicineUseCase,
            updateMedicineUseCase: mockUpdateMedicineUseCase,
            medicine: editMedicine
        )
        
        XCTAssertNotNil(sut.medicine)
        XCTAssertEqual(sut.medicine?.name, "Edit Medicine")
    }
}
