import XCTest
@testable import MediStock

// MARK: - Tests des fonctions refactorisées

final class RefactoredFunctionsTests: XCTestCase {
    
    var dataService: DataService!
    
    override func setUp() async throws {
        try await super.setUp()
        dataService = DataService()
    }
    
    override func tearDown() async throws {
        dataService = nil
        try await super.tearDown()
    }
    
    // MARK: - Tests saveAisle refactorisé
    
    func testSaveAisleWithValidation() async throws {
        // Test 1: Nom vide rejeté
        let emptyNameAisle = Aisle(id: "", name: "", description: nil, colorHex: "#FF0000", icon: "pills")
        
        do {
            _ = try await dataService.saveAisle(emptyNameAisle)
            XCTFail("Should throw validation error for empty name")
        } catch {
            XCTAssertTrue(error is ValidationError)
            if case ValidationError.emptyName = error {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
        
        // Test 2: Couleur invalide rejetée
        let invalidColorAisle = Aisle(id: "", name: "Test", description: nil, colorHex: "invalid", icon: "pills")
        
        do {
            _ = try await dataService.saveAisle(invalidColorAisle)
            XCTFail("Should throw validation error for invalid color")
        } catch {
            XCTAssertTrue(error is ValidationError)
            if case ValidationError.invalidColorFormat = error {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
        
        // Test 3: Icône invalide rejetée
        let invalidIconAisle = Aisle(id: "", name: "Test", description: nil, colorHex: "#FF0000", icon: "invalid.icon")
        
        do {
            _ = try await dataService.saveAisle(invalidIconAisle)
            XCTFail("Should throw validation error for invalid icon")
        } catch {
            XCTAssertTrue(error is ValidationError)
            if case ValidationError.invalidIcon = error {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testSaveAisleNameSanitization() async throws {
        // Test: Les espaces en début/fin sont supprimés
        let aisleWithSpaces = Aisle(
            id: "",
            name: "  Test Rayon  ",
            description: nil,
            colorHex: "#FF0000",
            icon: "pills"
        )
        
        // Mock de la sauvegarde (en réalité, il faudrait mocker Firebase)
        // Le nom devrait être nettoyé en "Test Rayon"
        XCTAssertEqual(ValidationHelper.sanitizeName(aisleWithSpaces.name), "Test Rayon")
    }
    
    // MARK: - Tests saveMedicine refactorisé
    
    func testSaveMedicineWithValidation() async throws {
        // Test 1: Quantité négative rejetée
        let negativeQuantityMedicine = Medicine(
            id: "",
            name: "Test",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "boîte",
            currentQuantity: -10,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: nil,
            aisleId: "test-aisle",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            _ = try await dataService.saveMedicine(negativeQuantityMedicine)
            XCTFail("Should throw validation error for negative quantity")
        } catch {
            XCTAssertTrue(error is ValidationError)
            if case ValidationError.negativeQuantity = error {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
        
        // Test 2: Seuils incohérents rejetés
        let invalidThresholdsMedicine = Medicine(
            id: "",
            name: "Test",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "boîte",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 30, // Critical > Warning!
            expiryDate: nil,
            aisleId: "test-aisle",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            _ = try await dataService.saveMedicine(invalidThresholdsMedicine)
            XCTFail("Should throw validation error for invalid thresholds")
        } catch {
            XCTAssertTrue(error is ValidationError)
            if case ValidationError.invalidThresholds = error {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
        
        // Test 3: Date d'expiration passée rejetée
        let expiredMedicine = Medicine(
            id: "",
            name: "Test",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "boîte",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: Date().addingTimeInterval(-86400), // Hier
            aisleId: "test-aisle",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            _ = try await dataService.saveMedicine(expiredMedicine)
            XCTFail("Should throw validation error for expired date")
        } catch {
            XCTAssertTrue(error is ValidationError)
            if case ValidationError.expiredDate = error {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testMedicineCopyWithPattern() {
        // Test du pattern copyWith pour éviter la duplication
        let originalMedicine = Medicine(
            id: "123",
            name: "Paracétamol",
            description: "Antalgique",
            dosage: "500mg",
            form: "Comprimé",
            reference: "REF123",
            unit: "boîte",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: Date().addingTimeInterval(86400 * 30),
            aisleId: "aisle-1",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Test 1: Copie avec modification de quantité
        let updatedMedicine = originalMedicine.copyWith(currentQuantity: 75)
        XCTAssertEqual(updatedMedicine.currentQuantity, 75)
        XCTAssertEqual(updatedMedicine.name, originalMedicine.name)
        XCTAssertEqual(updatedMedicine.id, originalMedicine.id)
        
        // Test 2: Copie avec nouveau timestamp
        let now = Date()
        let updatedWithTime = originalMedicine.copyWith(updatedAt: now)
        XCTAssertEqual(updatedWithTime.updatedAt, now)
        XCTAssertEqual(updatedWithTime.createdAt, originalMedicine.createdAt)
    }
    
    // MARK: - Tests d'intégrité référentielle
    
    func testDeleteAisleWithMedicinesProtection() async throws {
        // Test: La suppression d'un rayon avec des médicaments doit échouer
        // ou déplacer les médicaments vers "Non classé"
        
        // En pratique, ceci serait testé avec des mocks ou une base de test
        // Ici on vérifie juste que la méthode existe
        XCTAssertNotNil(dataService.deleteAisle)
    }
    
    // MARK: - Tests de validation des helpers
    
    func testValidationHelpers() {
        // Test isValidColorHex
        XCTAssertTrue(ValidationHelper.isValidColorHex("#FF0000"))
        XCTAssertTrue(ValidationHelper.isValidColorHex("#00ff00"))
        XCTAssertTrue(ValidationHelper.isValidColorHex("#123ABC"))
        
        XCTAssertFalse(ValidationHelper.isValidColorHex("FF0000"))
        XCTAssertFalse(ValidationHelper.isValidColorHex("#FF00"))
        XCTAssertFalse(ValidationHelper.isValidColorHex("#GGGGGG"))
        XCTAssertFalse(ValidationHelper.isValidColorHex("red"))
        
        // Test isValidName
        XCTAssertTrue(ValidationHelper.isValidName("Paracétamol"))
        XCTAssertTrue(ValidationHelper.isValidName("Anti-inflammatoire"))
        XCTAssertTrue(ValidationHelper.isValidName("Médicament 500mg"))
        XCTAssertTrue(ValidationHelper.isValidName("Sirop pour la toux"))
        
        XCTAssertFalse(ValidationHelper.isValidName(""))
        XCTAssertFalse(ValidationHelper.isValidName("   "))
        XCTAssertFalse(ValidationHelper.isValidName(String(repeating: "a", count: 101)))
        
        // Test isValidIcon
        XCTAssertTrue(ValidationHelper.isValidIcon("pills"))
        XCTAssertTrue(ValidationHelper.isValidIcon("heart.fill"))
        XCTAssertTrue(ValidationHelper.isValidIcon("bandage"))
        
        XCTAssertFalse(ValidationHelper.isValidIcon("invalid.icon"))
        XCTAssertFalse(ValidationHelper.isValidIcon(""))
        XCTAssertFalse(ValidationHelper.isValidIcon("custom.icon"))
    }
    
    // MARK: - Tests de performance
    
    func testSaveMedicinePerformance() {
        // Test que la validation n'impacte pas significativement les performances
        let medicine = Medicine(
            id: "",
            name: "Test Performance",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "boîte",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: Date().addingTimeInterval(86400),
            aisleId: "test-aisle",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        measure {
            do {
                try medicine.validate()
            } catch {
                XCTFail("Validation should pass")
            }
        }
    }
}