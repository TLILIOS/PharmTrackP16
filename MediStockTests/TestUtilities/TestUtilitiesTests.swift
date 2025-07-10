import XCTest
@testable import MediStock

final class TestUtilitiesTests: XCTestCase {
    
    // MARK: - Constants Tests
    
    func testTestConstants() {
        XCTAssertEqual(Constants.defaultTimeout, 10.0)
        XCTAssertEqual(Constants.shortTimeout, 2.0)
        XCTAssertEqual(Constants.longTimeout, 30.0)
        XCTAssertFalse(Constants.testUserId.isEmpty)
        XCTAssertFalse(Constants.testMedicineId.isEmpty)
        XCTAssertFalse(Constants.testAisleId.isEmpty)
    }
    
    // MARK: - Helper Function Tests
    
    func testWaitForCondition_Success() {
        // Given
        var conditionMet = false
        
        // When
        let expectation = XCTestExpectation(description: "Condition met")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            conditionMet = true
        }
        
        waitForCondition(timeout: 2.0) {
            if conditionMet {
                expectation.fulfill()
                return true
            }
            return false
        }
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(conditionMet)
    }
    
    func testWaitForCondition_Timeout() {
        // Given
        var conditionMet = false
        
        // When
        let startTime = Date()
        waitForCondition(timeout: 1.0) {
            conditionMet
        }
        let endTime = Date()
        
        // Then
        let elapsed = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThan(elapsed, 0.9) // Should wait at least the timeout
        XCTAssertLessThan(elapsed, 1.5) // But not too much longer
        XCTAssertFalse(conditionMet)
    }
    
    func testAssertEventuallyTrue_Success() {
        // Given
        var condition = false
        
        // When
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            condition = true
        }
        
        // Then
        assertEventuallyTrue(timeout: 2.0) {
            condition
        }
    }
    
    func testAssertEventuallyTrue_Failure() {
        // Given
        let condition = false
        
        // When & Then
        XCTAssertThrowsError(try assertEventuallyTrue(timeout: 0.5) {
            condition
        })
    }
    
    // MARK: - Mock Performance Tests
    
    func testMockPerformance_FastOperation() {
        // Given
        let mockRepository = MockMedicineRepository()
        
        // When
        measure {
            for _ in 0..<1000 {
                _ = mockRepository.medicines
            }
        }
        
        // Then - Should complete quickly
    }
    
    func testMockPerformance_WithDelay() {
        // Given
        let mockRepository = MockMedicineRepository()
        mockRepository.delayNanoseconds = 1_000_000 // 1ms
        
        // When
        let startTime = Date()
        Task {
            try? await mockRepository.getMedicines()
        }
        let endTime = Date()
        
        // Then
        let elapsed = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 0.1) // Should start quickly even with delay
    }
    
    // MARK: - Memory Management Tests
    
    func testMockMemoryManagement() {
        // Given
        var mockRepository: MockMedicineRepository? = MockMedicineRepository()
        weak var weakRepository = mockRepository
        
        // When
        mockRepository = nil
        
        // Then
        XCTAssertNil(weakRepository)
    }
    
    func testTestDataFactoryMemoryManagement() {
        // Given
        var medicine: Medicine? = TestDataFactory.createTestMedicine()
        weak var weakMedicine: Medicine? = medicine
        
        // When
        medicine = nil
        
        // Then
        XCTAssertNil(weakMedicine)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentMockAccess() {
        // Given
        let mockRepository = MockMedicineRepository()
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                let medicine = TestDataFactory.createTestMedicine(id: "med-\(i)")
                mockRepository.addedMedicines.append(medicine)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertGreaterThan(mockRepository.addedMedicines.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testMockErrorHandling() async {
        // Given
        let mockRepository = MockMedicineRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )
        
        // When & Then
        do {
            _ = try await mockRepository.getMedicines()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Test error")
        }
    }
    
    func testMockErrorResetting() async {
        // Given
        let mockRepository = MockMedicineRepository()
        mockRepository.shouldThrowError = true
        
        // When
        do {
            _ = try await mockRepository.getMedicines()
            XCTFail("Expected error")
        } catch {
            // Expected
        }
        
        // Reset error
        mockRepository.shouldThrowError = false
        
        // Then
        do {
            let medicines = try await mockRepository.getMedicines()
            XCTAssertNotNil(medicines)
        } catch {
            XCTFail("Should not throw error after reset")
        }
    }
    
    // MARK: - Data Validation Tests
    
    func testTestDataFactoryValidation() {
        // Given & When
        let medicine = TestDataFactory.createTestMedicine()
        let aisle = TestDataFactory.createTestAisle()
        let user = TestDataFactory.createTestUser()
        let historyEntry = TestDataFactory.createTestHistoryEntry()
        
        // Then
        XCTAssertFalse(medicine.id.isEmpty)
        XCTAssertFalse(medicine.name.isEmpty)
        XCTAssertGreaterThan(medicine.maxQuantity, 0)
        
        XCTAssertFalse(aisle.id.isEmpty)
        XCTAssertFalse(aisle.name.isEmpty)
        XCTAssertGreaterThan(aisle.capacity, 0)
        
        XCTAssertFalse(user.id.isEmpty)
        XCTAssertFalse(user.email.isEmpty)
        XCTAssertTrue(user.email.contains("@"))
        
        XCTAssertFalse(historyEntry.id.isEmpty)
        XCTAssertFalse(historyEntry.action.isEmpty)
        XCTAssertNotNil(historyEntry.timestamp)
    }
    
    func testMultipleDataCreation() {
        // Given & When
        let medicines = TestDataFactory.createMultipleMedicines(count: 5)
        let aisles = TestDataFactory.createMultipleAisles(count: 3)
        let users = TestDataFactory.createMultipleUsers(count: 4)
        
        // Then
        XCTAssertEqual(medicines.count, 5)
        XCTAssertEqual(aisles.count, 3)
        XCTAssertEqual(users.count, 4)
        
        // Check uniqueness
        let medicineIds = Set(medicines.map { $0.id })
        let aisleIds = Set(aisles.map { $0.id })
        let userIds = Set(users.map { $0.id })
        
        XCTAssertEqual(medicineIds.count, 5)
        XCTAssertEqual(aisleIds.count, 3)
        XCTAssertEqual(userIds.count, 4)
    }
    
    // MARK: - Random Data Tests
    
    func testRandomDataGeneration() {
        // Given & When
        let medicine1 = TestDataFactory.createTestMedicine()
        let medicine2 = TestDataFactory.createTestMedicine()
        
        // Then
        XCTAssertNotEqual(medicine1.id, medicine2.id)
        // Names might be the same due to predefined list, but IDs should be unique
    }
    
    func testRandomDataConsistency() {
        // Given
        let medicine = TestDataFactory.createTestMedicine(
            name: "Consistent Medicine",
            currentQuantity: 100
        )
        
        // When & Then
        XCTAssertEqual(medicine.name, "Consistent Medicine")
        XCTAssertEqual(medicine.currentQuantity, 100)
        // Other fields should be filled with default values
        XCTAssertFalse(medicine.id.isEmpty)
        XCTAssertFalse(medicine.description.isEmpty)
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyDataCreation() {
        // Given & When
        let emptyMedicines = TestDataFactory.createMultipleMedicines(count: 0)
        let emptyAisles = TestDataFactory.createMultipleAisles(count: 0)
        
        // Then
        XCTAssertTrue(emptyMedicines.isEmpty)
        XCTAssertTrue(emptyAisles.isEmpty)
    }
    
    func testLargeDataCreation() {
        // Given & When
        let largeMedicineList = TestDataFactory.createMultipleMedicines(count: 1000)
        
        // Then
        XCTAssertEqual(largeMedicineList.count, 1000)
        
        // Check that all have unique IDs
        let uniqueIds = Set(largeMedicineList.map { $0.id })
        XCTAssertEqual(uniqueIds.count, 1000)
    }
    
    // MARK: - Custom Validation Tests
    
    func testCustomValidationHelpers() {
        // Test email validation helper
        XCTAssertTrue(ValidationHelper.isValidEmail("test@example.com"))
        XCTAssertFalse(ValidationHelper.isValidEmail("invalid-email"))
        
        // Test quantity validation helper
        XCTAssertTrue(ValidationHelper.isValidQuantity(50, max: 100))
        XCTAssertFalse(ValidationHelper.isValidQuantity(-10, max: 100))
        XCTAssertFalse(ValidationHelper.isValidQuantity(150, max: 100))
        
        // Test name validation helper
        XCTAssertTrue(ValidationHelper.isValidName("Valid Name"))
        XCTAssertFalse(ValidationHelper.isValidName(""))
        XCTAssertFalse(ValidationHelper.isValidName("   "))
    }
    
    // MARK: - Test Isolation Tests
    
    func testTestIsolation() {
        // Given
        let mockRepo1 = MockMedicineRepository()
        let mockRepo2 = MockMedicineRepository()
        
        // When
        mockRepo1.addedMedicines.append(TestDataFactory.createTestMedicine())
        
        // Then
        XCTAssertEqual(mockRepo1.addedMedicines.count, 1)
        XCTAssertEqual(mockRepo2.addedMedicines.count, 0)
    }
    
    // MARK: - Performance Measurement Tests
    
    func testPerformanceMeasurement() {
        // Given
        let iterations = 10000
        
        // When
        measure {
            for _ in 0..<iterations {
                _ = TestDataFactory.createTestMedicine()
            }
        }
        
        // Then - Should complete within reasonable time
    }
    
    func testMemoryUsage() {
        // Given
        var medicines: [Medicine] = []
        
        // When
        for _ in 0..<1000 {
            medicines.append(TestDataFactory.createTestMedicine())
        }
        
        // Then
        XCTAssertEqual(medicines.count, 1000)
        
        // Clean up
        medicines.removeAll()
        XCTAssertTrue(medicines.isEmpty)
    }
}

// MARK: - Helper Extensions for Testing

private extension TestUtilitiesTests {
    
    func waitForCondition(timeout: TimeInterval, condition: () -> Bool) {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                break
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        }
    }
    
    func assertEventuallyTrue(timeout: TimeInterval, condition: () -> Bool) throws {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                throw XCTestError(.timeoutWhileWaiting)
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        }
    }
}

// MARK: - Test Helper Classes

private struct Constants {
    static let defaultTimeout: TimeInterval = 10.0
    static let shortTimeout: TimeInterval = 2.0
    static let longTimeout: TimeInterval = 30.0
    static let testUserId = "test-user-123"
    static let testMedicineId = "test-medicine-456"
    static let testAisleId = "test-aisle-789"
}

private struct ValidationHelper {
    static func isValidEmail(_ email: String) -> Bool {
        return email.contains("@") && email.contains(".") && email.count > 5
    }
    
    static func isValidQuantity(_ quantity: Int, max: Int) -> Bool {
        return quantity >= 0 && quantity <= max
    }
    
    static func isValidName(_ name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}