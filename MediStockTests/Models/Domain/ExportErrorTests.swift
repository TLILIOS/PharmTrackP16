import XCTest
@testable @preconcurrency import MediStock
@MainActor
final class ExportErrorTests: XCTestCase, Sendable {
    
    func testExportErrorDescriptions() {
        let unsupportedFormatError = ExportError.unsupportedFormat
        XCTAssertEqual(unsupportedFormatError.errorDescription, "Format d'exportation non supporté.")
        
        let conversionFailedError = ExportError.conversionFailed
        XCTAssertEqual(conversionFailedError.errorDescription, "Échec de la conversion des données pour l'exportation.")
        
        let fileSaveFailedError = ExportError.fileSaveFailed
        XCTAssertEqual(fileSaveFailedError.errorDescription, "Échec de l'enregistrement du fichier d'exportation.")
    }
    
    func testExportErrorEquality() {
        XCTAssertEqual(ExportError.unsupportedFormat, ExportError.unsupportedFormat)
        XCTAssertEqual(ExportError.conversionFailed, ExportError.conversionFailed)
        XCTAssertEqual(ExportError.fileSaveFailed, ExportError.fileSaveFailed)
        XCTAssertNotEqual(ExportError.unsupportedFormat, ExportError.conversionFailed)
    }
    
    func testExportErrorLocalizedErrorConformance() {
        let error: LocalizedError = ExportError.unsupportedFormat
        XCTAssertNotNil(error.errorDescription)
    }
    
    func testAllExportErrorCases() {
        let allCases: [ExportError] = [
            .unsupportedFormat,
            .conversionFailed,
            .fileSaveFailed
        ]
        
        for exportError in allCases {
            XCTAssertNotNil(exportError.errorDescription)
            XCTAssertFalse(exportError.errorDescription!.isEmpty)
        }
    }
    
    func testExportErrorDescriptionNonNil() {
        XCTAssertNotNil(ExportError.unsupportedFormat.errorDescription)
        XCTAssertNotNil(ExportError.conversionFailed.errorDescription)
        XCTAssertNotNil(ExportError.fileSaveFailed.errorDescription)
    }
    
    func testExportErrorDescriptionNotEmpty() {
        XCTAssertFalse(ExportError.unsupportedFormat.errorDescription!.isEmpty)
        XCTAssertFalse(ExportError.conversionFailed.errorDescription!.isEmpty)
        XCTAssertFalse(ExportError.fileSaveFailed.errorDescription!.isEmpty)
    }
}
