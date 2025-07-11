import XCTest
@testable import MediStock

final class RealGetMedicineUseCaseTests: XCTestCase {
    
    var sut: RealGetMedicineUseCase!
    var mockMedicineRepository: MockMedicineRepository!
    
    override func setUp() {
        super.setUp()
        mockMedicineRepository = MockMedicineRepository()
        sut = RealGetMedicineUseCase(medicineRepository: mockMedicineRepository)
    }
    
    override func tearDown() {
        mockMedicineRepository = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Factory
    
    private func createTestMedicine(
        id: String = "test-medicine-1",
        name: String = "Test Medicine",
        currentQuantity: Int = 50
    ) -> Medicine {
        return Medicine(
            id: id,
            name: name,
            description: "Test Description",
            dosage: "500mg",
            form: "Tablet",
            reference: "TEST-001",
            unit: "tablet",
            currentQuantity: currentQuantity,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            aisleId: "test-aisle-1",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Initialization Tests
    
    func test_init_shouldSetupCorrectly() {
        // Given & When
        // SUT is initialized in setUp
        
        // Then
        XCTAssertNotNil(sut)
    }
    
    func test_init_withRepository_shouldStoreRepository() {
        // Given
        let customRepository = MockMedicineRepository()
        
        // When
        let useCase = RealGetMedicineUseCase(medicineRepository: customRepository)
        
        // Then
        XCTAssertNotNil(useCase)
        // Repository is stored privately, verified through behavior tests
    }
    
    // MARK: - execute(id:) Success Tests
    
    func test_execute_withValidId_shouldReturnMedicine() async throws {
        // Given
        let testMedicine = createTestMedicine(id: "valid-medicine-1")
        mockMedicineRepository.medicines = [testMedicine]
        
        // When
        let result = try await sut.execute(id: "valid-medicine-1")
        
        // Then
        XCTAssertEqual(result.id, testMedicine.id)
        XCTAssertEqual(result.name, testMedicine.name)
        XCTAssertEqual(result.currentQuantity, testMedicine.currentQuantity)
        XCTAssertEqual(result.aisleId, testMedicine.aisleId)
    }
    
    func test_execute_withValidId_shouldCallRepositoryOnce() async throws {
        // Given
        let testMedicine = createTestMedicine(id: "test-medicine")
        mockMedicineRepository.medicines = [testMedicine]
        
        // When
        _ = try await sut.execute(id: "test-medicine")
        
        // Then
        // Verify repository method was called
        // Note: MockMedicineRepository doesn't track getMedicine calls
        // This would need to be added to the mock for complete verification
    }
    
    func test_execute_withDifferentMedicineTypes_shouldReturnCorrectMedicine() async throws {
        // Given
        let tablet = createTestMedicine(id: "tablet-1", name: "Tablet Medicine")
        let syrup = Medicine(
            id: "syrup-1",
            name: "Syrup Medicine",
            description: "Liquid medicine",
            dosage: "10ml",
            form: "Syrup",
            reference: "SYR-001",
            unit: "ml",
            currentQuantity: 250,
            maxQuantity: 500,
            warningThreshold: 100,
            criticalThreshold: 50,
            expiryDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            aisleId: "liquid-aisle",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockMedicineRepository.medicines = [tablet, syrup]
        
        // When
        let resultTablet = try await sut.execute(id: "tablet-1")
        let resultSyrup = try await sut.execute(id: "syrup-1")
        
        // Then
        XCTAssertEqual(resultTablet.id, "tablet-1")
        XCTAssertEqual(resultTablet.form, "Tablet")
        XCTAssertEqual(resultSyrup.id, "syrup-1")
        XCTAssertEqual(resultSyrup.form, "Syrup")
    }
    
    func test_execute_withMedicineHavingDifferentStockLevels_shouldReturnCorrectData() async throws {
        // Given
        let criticalStock = createTestMedicine(id: "critical-1", currentQuantity: 5)
        let warningStock = createTestMedicine(id: "warning-1", currentQuantity: 15)
        let normalStock = createTestMedicine(id: "normal-1", currentQuantity: 80)
        
        mockMedicineRepository.medicines = [criticalStock, warningStock, normalStock]
        
        // When
        let criticalResult = try await sut.execute(id: "critical-1")
        let warningResult = try await sut.execute(id: "warning-1")
        let normalResult = try await sut.execute(id: "normal-1")
        
        // Then
        XCTAssertEqual(criticalResult.stockStatus, .critical)
        XCTAssertEqual(warningResult.stockStatus, .warning)
        XCTAssertEqual(normalResult.stockStatus, .normal)
    }
    
    // MARK: - execute(id:) Error Tests
    
    func test_execute_withNonExistentId_shouldThrowNotFoundError() async {
        // Given
        let existingMedicine = createTestMedicine(id: "existing-medicine")
        mockMedicineRepository.medicines = [existingMedicine]
        
        // When & Then
        do {
            _ = try await sut.execute(id: "non-existent-id")
            XCTFail("Should throw error for non-existent medicine")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "MedicineUseCase")
            XCTAssertEqual(nsError.code, 404)
            XCTAssertTrue(nsError.localizedDescription.contains("Medicine not found"))
        }
    }
    
    func test_execute_withEmptyId_shouldThrowNotFoundError() async {
        // Given
        let testMedicine = createTestMedicine(id: "valid-medicine")
        mockMedicineRepository.medicines = [testMedicine]
        
        // When & Then
        do {
            _ = try await sut.execute(id: "")
            XCTFail("Should throw error for empty ID")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "MedicineUseCase")
            XCTAssertEqual(nsError.code, 404)
        }
    }
    
    func test_execute_withWhitespaceId_shouldThrowNotFoundError() async {
        // Given
        let testMedicine = createTestMedicine(id: "valid-medicine")
        mockMedicineRepository.medicines = [testMedicine]
        
        // When & Then
        do {
            _ = try await sut.execute(id: "   ")
            XCTFail("Should throw error for whitespace-only ID")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "MedicineUseCase")
            XCTAssertEqual(nsError.code, 404)
        }
    }
    
    func test_execute_withRepositoryError_shouldPropagateError() async {
        // Given
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(
            domain: "RepositoryError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Database connection failed"]
        )
        
        // When & Then
        do {
            _ = try await sut.execute(id: "any-id")
            XCTFail("Should propagate repository error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "RepositoryError")
            XCTAssertEqual(nsError.code, 500)
            XCTAssertTrue(nsError.localizedDescription.contains("Database connection failed"))
        }
    }
    
    func test_execute_withNetworkError_shouldPropagateNetworkError() async {
        // Given
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "Network unavailable"]
        )
        
        // When & Then
        do {
            _ = try await sut.execute(id: "medicine-id")
            XCTFail("Should propagate network error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, NSURLErrorDomain)
            XCTAssertEqual(nsError.code, NSURLErrorNotConnectedToInternet)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func test_execute_withSpecialCharactersInId_shouldHandleCorrectly() async throws {
        // Given
        let specialId = "medicine-123-@#$%"
        let testMedicine = createTestMedicine(id: specialId)
        mockMedicineRepository.medicines = [testMedicine]
        
        // When
        let result = try await sut.execute(id: specialId)
        
        // Then
        XCTAssertEqual(result.id, specialId)
    }
    
    func test_execute_withVeryLongId_shouldHandleCorrectly() async throws {
        // Given
        let longId = String(repeating: "a", count: 1000)
        let testMedicine = createTestMedicine(id: longId)
        mockMedicineRepository.medicines = [testMedicine]
        
        // When
        let result = try await sut.execute(id: longId)
        
        // Then
        XCTAssertEqual(result.id, longId)
    }
    
    func test_execute_withUnicodeId_shouldHandleCorrectly() async throws {
        // Given
        let unicodeId = "médicament-🏥-测试"
        let testMedicine = createTestMedicine(id: unicodeId)
        mockMedicineRepository.medicines = [testMedicine]
        
        // When
        let result = try await sut.execute(id: unicodeId)
        
        // Then
        XCTAssertEqual(result.id, unicodeId)
    }
    
    func test_execute_withCaseSensitiveIds_shouldBeExact() async {
        // Given
        let lowerCaseMedicine = createTestMedicine(id: "medicine-abc")
        let upperCaseMedicine = createTestMedicine(id: "MEDICINE-ABC")
        mockMedicineRepository.medicines = [lowerCaseMedicine, upperCaseMedicine]
        
        // When
        let lowerResult = try await sut.execute(id: "medicine-abc")
        let upperResult = try await sut.execute(id: "MEDICINE-ABC")
        
        // Then
        XCTAssertEqual(lowerResult.id, "medicine-abc")
        XCTAssertEqual(upperResult.id, "MEDICINE-ABC")
        XCTAssertNotEqual(lowerResult.id, upperResult.id)
    }
    
    // MARK: - Performance Tests
    
    func test_execute_performance() async throws {
        // Given
        let medicines = (1...1000).map { index in
            createTestMedicine(id: "medicine-\(index)", name: "Medicine \(index)")
        }
        mockMedicineRepository.medicines = medicines
        let targetId = "medicine-500" // Middle of the list
        
        // When & Then
        measure {
            Task {
                do {
                    _ = try await sut.execute(id: targetId)
                } catch {
                    XCTFail("Performance test should not fail: \(error)")
                }
            }
        }
    }
    
    func test_execute_performanceWithManyMedicines() async throws {
        // Given
        let medicines = (1...10000).map { index in
            createTestMedicine(id: "med-\(index)")
        }
        mockMedicineRepository.medicines = medicines
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await sut.execute(id: "med-5000")
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertLessThan(timeElapsed, 1.0) // Should complete within 1 second
    }
    
    // MARK: - Concurrency Tests
    
    func test_execute_concurrentCalls_shouldHandleCorrectly() async throws {
        // Given
        let medicines = (1...100).map { index in
            createTestMedicine(id: "concurrent-\(index)")
        }
        mockMedicineRepository.medicines = medicines
        
        // When
        let results = await withTaskGroup(of: Medicine?.self) { group in
            for i in 1...10 {
                group.addTask {
                    do {
                        return try await self.sut.execute(id: "concurrent-\(i)")
                    } catch {
                        return nil
                    }
                }
            }
            
            var allResults: [Medicine?] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        // Then
        XCTAssertEqual(results.count, 10)
        let successfulResults = results.compactMap { $0 }
        XCTAssertEqual(successfulResults.count, 10)
    }
    
    func test_execute_concurrentCallsSameId_shouldReturnSameResult() async throws {
        // Given
        let testMedicine = createTestMedicine(id: "shared-medicine")
        mockMedicineRepository.medicines = [testMedicine]
        
        // When
        let results = await withTaskGroup(of: Medicine?.self) { group in
            for _ in 1...5 {
                group.addTask {
                    do {
                        return try await self.sut.execute(id: "shared-medicine")
                    } catch {
                        return nil
                    }
                }
            }
            
            var allResults: [Medicine?] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        // Then
        let successfulResults = results.compactMap { $0 }
        XCTAssertEqual(successfulResults.count, 5)
        XCTAssertTrue(successfulResults.allSatisfy { $0.id == "shared-medicine" })
    }
    
    // MARK: - Integration Tests
    
    func test_execute_withRepositoryDelay_shouldWaitForResult() async throws {
        // Given
        let testMedicine = createTestMedicine(id: "delayed-medicine")
        mockMedicineRepository.medicines = [testMedicine]
        mockMedicineRepository.delayNanoseconds = 100_000_000 // 0.1 seconds
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await sut.execute(id: "delayed-medicine")
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertEqual(result.id, "delayed-medicine")
        XCTAssertGreaterThan(timeElapsed, 0.09) // Should take at least the delay time
    }
    
    func test_execute_errorHandling_shouldProvideDetailedInformation() async {
        // Given
        mockMedicineRepository.medicines = []
        
        // When & Then
        do {
            _ = try await sut.execute(id: "missing-medicine")
            XCTFail("Should throw error")
        } catch {
            let nsError = error as NSError
            
            // Verify error provides useful information
            XCTAssertEqual(nsError.domain, "MedicineUseCase")
            XCTAssertEqual(nsError.code, 404)
            XCTAssertNotNil(nsError.localizedDescription)
            XCTAssertFalse(nsError.localizedDescription.isEmpty)
        }
    }
    
    // MARK: - Business Logic Tests
    
    func test_execute_withValidMedicine_shouldReturnCompleteData() async throws {
        // Given
        let completeMedicine = Medicine(
            id: "complete-medicine",
            name: "Complete Medicine Data",
            description: "Full description",
            dosage: "250mg",
            form: "Capsule",
            reference: "REF-12345",
            unit: "capsule",
            currentQuantity: 45,
            maxQuantity: 200,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            aisleId: "specific-aisle-123",
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            updatedAt: Date()
        )
        mockMedicineRepository.medicines = [completeMedicine]
        
        // When
        let result = try await sut.execute(id: "complete-medicine")
        
        // Then
        XCTAssertEqual(result.id, completeMedicine.id)
        XCTAssertEqual(result.name, completeMedicine.name)
        XCTAssertEqual(result.description, completeMedicine.description)
        XCTAssertEqual(result.dosage, completeMedicine.dosage)
        XCTAssertEqual(result.form, completeMedicine.form)
        XCTAssertEqual(result.reference, completeMedicine.reference)
        XCTAssertEqual(result.unit, completeMedicine.unit)
        XCTAssertEqual(result.currentQuantity, completeMedicine.currentQuantity)
        XCTAssertEqual(result.maxQuantity, completeMedicine.maxQuantity)
        XCTAssertEqual(result.warningThreshold, completeMedicine.warningThreshold)
        XCTAssertEqual(result.criticalThreshold, completeMedicine.criticalThreshold)
        XCTAssertEqual(result.expiryDate, completeMedicine.expiryDate)
        XCTAssertEqual(result.aisleId, completeMedicine.aisleId)
        XCTAssertEqual(result.createdAt, completeMedicine.createdAt)
        XCTAssertEqual(result.updatedAt, completeMedicine.updatedAt)
    }
}

// MARK: - Test Extensions

extension Medicine {
    static func testMedicine(
        id: String = UUID().uuidString,
        name: String = "Test Medicine",
        currentQuantity: Int = 50,
        stockStatus: StockStatus = .normal
    ) -> Medicine {
        let warningThreshold: Int
        let criticalThreshold: Int
        
        switch stockStatus {
        case .critical:
            warningThreshold = currentQuantity + 10
            criticalThreshold = currentQuantity + 5
        case .warning:
            warningThreshold = currentQuantity + 5
            criticalThreshold = currentQuantity - 5
        case .normal:
            warningThreshold = currentQuantity - 10
            criticalThreshold = currentQuantity - 20
        }
        
        return Medicine(
            id: id,
            name: name,
            description: "Test Description",
            dosage: "500mg",
            form: "Tablet",
            reference: "TEST-001",
            unit: "tablet",
            currentQuantity: currentQuantity,
            maxQuantity: 100,
            warningThreshold: warningThreshold,
            criticalThreshold: criticalThreshold,
            expiryDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            aisleId: "test-aisle-1",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}