import Foundation
import SwiftUI

// MARK: - PDFExportServiceProtocol

/// Protocole pour le service d'export PDF
/// Permet l'injection de dépendance et les tests avec mocks
protocol PDFExportServiceProtocol {
    /// Génère un rapport PDF complet de l'inventaire
    /// - Parameters:
    ///   - medicines: Liste des médicaments à inclure
    ///   - aisles: Liste des rayons
    ///   - authorName: Nom de l'auteur du rapport
    /// - Returns: Data du PDF généré
    func generateInventoryReport(
        medicines: [Medicine],
        aisles: [Aisle],
        authorName: String
    ) async throws -> Data

    /// Génère un rapport PDF de l'historique des actions
    /// - Parameters:
    ///   - entries: Liste des entrées d'historique à inclure
    ///   - statistics: Statistiques de l'historique
    ///   - dateRange: Plage de dates sélectionnée
    ///   - authorName: Nom de l'auteur du rapport
    /// - Returns: Data du PDF généré
    func generateHistoryReport(
        entries: [HistoryEntry],
        statistics: HistoryStatistics?,
        dateRange: String,
        authorName: String
    ) async throws -> Data

    /// Génère un rapport PDF de l'historique des mouvements de stock
    /// - Parameters:
    ///   - entries: Liste des mouvements de stock à inclure
    ///   - medicines: Dictionnaire [medicineId: medicineName] pour afficher les noms
    ///   - filterType: Type de filtre appliqué
    ///   - authorName: Nom de l'auteur du rapport
    /// - Returns: Data du PDF généré
    func generateStockHistoryReport(
        entries: [StockHistory],
        medicines: [String: String],
        filterType: String,
        authorName: String
    ) async throws -> Data
}

// MARK: - PDFExportService

/// Service dédié à l'export PDF des rapports d'inventaire
/// Responsabilité : Génération de documents PDF professionnels en utilisant SwiftUI et ImageRenderer
@MainActor
final class PDFExportService: PDFExportServiceProtocol {

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - Public Methods

    func generateInventoryReport(
        medicines: [Medicine],
        aisles: [Aisle],
        authorName: String
    ) async throws -> Data {
        let reportView = PDFInventoryReportView(
            medicines: medicines,
            aisles: aisles,
            authorName: authorName
        )

        return try await renderPDF(
            view: reportView,
            title: "Rapport d'inventaire MediStock",
            author: authorName
        )
    }

    func generateHistoryReport(
        entries: [HistoryEntry],
        statistics: HistoryStatistics?,
        dateRange: String,
        authorName: String
    ) async throws -> Data {
        let reportView = PDFHistoryReportView(
            entries: entries,
            statistics: statistics,
            dateRange: dateRange,
            authorName: authorName
        )

        return try await renderPDF(
            view: reportView,
            title: "Rapport d'historique MediStock",
            author: authorName
        )
    }

    func generateStockHistoryReport(
        entries: [StockHistory],
        medicines: [String: String],
        filterType: String,
        authorName: String
    ) async throws -> Data {
        let reportView = PDFStockHistoryReportView(
            entries: entries,
            medicines: medicines,
            filterType: filterType,
            authorName: authorName
        )

        return try await renderPDF(
            view: reportView,
            title: "Rapport de mouvements de stock MediStock",
            author: authorName
        )
    }

    // MARK: - Private Helper Methods

    /// Rend une vue SwiftUI en PDF en utilisant ImageRenderer
    /// - Parameters:
    ///   - view: La vue SwiftUI à rendre
    ///   - title: Le titre du document PDF
    ///   - author: L'auteur du document PDF
    /// - Returns: Data du PDF généré
    private func renderPDF<Content: View>(
        view: Content,
        title: String,
        author: String
    ) async throws -> Data {
        let renderer = ImageRenderer(content: view)

        // Configuration de la taille de la page (Letter size)
        renderer.proposedSize = ProposedViewSize(
            width: PDFConstants.pageWidth,
            height: PDFConstants.pageHeight
        )

        // Configuration du rendu pour PDF
        renderer.scale = 2.0 // Qualité haute résolution

        let pdfData = NSMutableData()

        // Métadonnées du PDF
        let metadata: [String: Any] = [
            kCGPDFContextCreator as String: "MediStock",
            kCGPDFContextAuthor as String: author,
            kCGPDFContextTitle as String: title
        ]

        // Création du contexte PDF
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, metadata as CFDictionary?) else {
            throw PDFExportError.renderingFailed
        }

        context.beginPDFPage(nil as CFDictionary?)

        // Utilisation du renderer pour dessiner dans le contexte
        renderer.render { size, renderInContext in
            renderInContext(context)
        }

        context.endPDFPage()
        context.closePDF()

        return pdfData as Data
    }
}

// MARK: - PDF Export Error

/// Erreurs possibles lors de l'export PDF
enum PDFExportError: LocalizedError {
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .renderingFailed:
            return "Échec du rendu PDF"
        }
    }
}

// MARK: - Mock for Testing

/// Mock du service PDF pour les tests unitaires
final class MockPDFExportService: PDFExportServiceProtocol {
    var shouldThrowError = false
    var generatedPDFData: Data?

    func generateInventoryReport(
        medicines: [Medicine],
        aisles: [Aisle],
        authorName: String
    ) async throws -> Data {
        if shouldThrowError {
            throw NSError(domain: "MockPDFError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Erreur de test simulée"
            ])
        }

        let mockData = "Mock PDF Data".data(using: .utf8) ?? Data()
        generatedPDFData = mockData
        return mockData
    }

    func generateHistoryReport(
        entries: [HistoryEntry],
        statistics: HistoryStatistics?,
        dateRange: String,
        authorName: String
    ) async throws -> Data {
        if shouldThrowError {
            throw NSError(domain: "MockPDFError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Erreur de test simulée"
            ])
        }

        let mockData = "Mock History PDF Data".data(using: .utf8) ?? Data()
        generatedPDFData = mockData
        return mockData
    }

    func generateStockHistoryReport(
        entries: [StockHistory],
        medicines: [String: String],
        filterType: String,
        authorName: String
    ) async throws -> Data {
        if shouldThrowError {
            throw NSError(domain: "MockPDFError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Erreur de test simulée"
            ])
        }

        let mockData = "Mock Stock History PDF Data".data(using: .utf8) ?? Data()
        generatedPDFData = mockData
        return mockData
    }
}
