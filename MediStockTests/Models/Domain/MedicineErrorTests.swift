import XCTest
@testable import MediStock

final class MedicineErrorTests: XCTestCase {
    
    func testMedicineErrorDescriptions() {
        let notFoundError = MedicineError.notFound
        XCTAssertEqual(notFoundError.errorDescription, "Le médicament demandé n'a pas été trouvé.")
        
        let invalidDataError = MedicineError.invalidData
        XCTAssertEqual(invalidDataError.errorDescription, "Les données du médicament sont invalides.")
        
        let saveFailedError = MedicineError.saveFailed
        XCTAssertEqual(saveFailedError.errorDescription, "Échec de l'enregistrement du médicament.")
        
        let deleteFailedError = MedicineError.deleteFailed
        XCTAssertEqual(deleteFailedError.errorDescription, "Échec de la suppression du médicament.")
    }
    
    func testMedicineErrorUnknownErrorWithNilError() {
        let unknownError = MedicineError.unknownError(nil)
        XCTAssertEqual(unknownError.errorDescription, "Une erreur inconnue est survenue.")
    }
    
    func testMedicineErrorUnknownErrorWithSpecificError() {
        let specificError = NSError(domain: "TestDomain", code: 456, userInfo: [NSLocalizedDescriptionKey: "Medicine specific error"])
        let unknownError = MedicineError.unknownError(specificError)
        XCTAssertEqual(unknownError.errorDescription, "Medicine specific error")
    }
    
    func testStockErrorDescriptions() {
        let insufficientStockError = StockError.insufficientStock
        XCTAssertEqual(insufficientStockError.errorDescription, "Stock insuffisant pour effectuer cette opération.")
        
        let invalidAmountError = StockError.invalidAmount
        XCTAssertEqual(invalidAmountError.errorDescription, "La quantité spécifiée n'est pas valide.")
    }
    
    func testMedicineErrorEquality() {
        XCTAssertEqual(MedicineError.notFound, MedicineError.notFound)
        XCTAssertEqual(MedicineError.invalidData, MedicineError.invalidData)
        XCTAssertNotEqual(MedicineError.notFound, MedicineError.invalidData)
    }
    
    func testStockErrorEquality() {
        XCTAssertEqual(StockError.insufficientStock, StockError.insufficientStock)
        XCTAssertEqual(StockError.invalidAmount, StockError.invalidAmount)
        XCTAssertNotEqual(StockError.insufficientStock, StockError.invalidAmount)
    }
    
    func testMedicineErrorLocalizedErrorConformance() {
        let error: LocalizedError = MedicineError.notFound
        XCTAssertNotNil(error.errorDescription)
    }
    
    func testStockErrorLocalizedErrorConformance() {
        let error: LocalizedError = StockError.insufficientStock
        XCTAssertNotNil(error.errorDescription)
    }
    
    func testAllMedicineErrorCases() {
        let allCases: [MedicineError] = [
            .notFound,
            .invalidData,
            .saveFailed,
            .deleteFailed,
            .unknownError(nil)
        ]
        
        for medicineError in allCases {
            XCTAssertNotNil(medicineError.errorDescription)
            XCTAssertFalse(medicineError.errorDescription!.isEmpty)
        }
    }
    
    func testAllStockErrorCases() {
        let allCases: [StockError] = [
            .insufficientStock,
            .invalidAmount
        ]
        
        for stockError in allCases {
            XCTAssertNotNil(stockError.errorDescription)
            XCTAssertFalse(stockError.errorDescription!.isEmpty)
        }
    }
}