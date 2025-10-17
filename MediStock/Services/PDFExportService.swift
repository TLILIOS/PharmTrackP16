import Foundation
import UIKit

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
}

// MARK: - PDFExportService

/// Service dédié à l'export PDF des rapports d'inventaire
/// Responsabilité : Génération de documents PDF professionnels
final class PDFExportService: PDFExportServiceProtocol {

    // MARK: - Constants

    private enum PDFLayout {
        static let pageWidth: CGFloat = 8.5 * 72.0  // Letter size
        static let pageHeight: CGFloat = 11 * 72.0
        static let leftMargin: CGFloat = 50
        static let rightMargin: CGFloat = 50
        static let topMargin: CGFloat = 50
        static let bottomMargin: CGFloat = 100
    }

    // MARK: - Public Methods

    func generateInventoryReport(
        medicines: [Medicine],
        aisles: [Aisle],
        authorName: String
    ) async throws -> Data {

        let pdfMetaData = [
            kCGPDFContextCreator: "MediStock",
            kCGPDFContextAuthor: authorName,
            kCGPDFContextTitle: "Rapport d'inventaire MediStock"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(
            x: 0,
            y: 0,
            width: PDFLayout.pageWidth,
            height: PDFLayout.pageHeight
        )

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = PDFLayout.topMargin

            // En-tête du rapport
            yPosition = drawHeader(
                authorName: authorName,
                yPosition: yPosition,
                pageRect: pageRect
            )

            // Résumé
            yPosition = drawSummary(
                medicines: medicines,
                aisles: aisles,
                context: context,
                yPosition: yPosition,
                pageRect: pageRect
            )

            // Inventaire par rayon
            yPosition = drawInventoryByAisle(
                medicines: medicines,
                aisles: aisles,
                context: context,
                yPosition: yPosition,
                pageRect: pageRect
            )

            // Stocks critiques
            let criticalMedicines = medicines.filter { $0.stockStatus == .critical }
            if !criticalMedicines.isEmpty {
                yPosition = drawCriticalStock(
                    medicines: criticalMedicines,
                    context: context,
                    yPosition: yPosition,
                    pageRect: pageRect
                )
            }

            // Expirations proches
            let expiringMedicines = medicines.filter { $0.isExpiringSoon && !$0.isExpired }
            if !expiringMedicines.isEmpty {
                yPosition = drawExpiringMedicines(
                    medicines: expiringMedicines,
                    context: context,
                    yPosition: yPosition,
                    pageRect: pageRect
                )
            }
        }

        return data
    }

    // MARK: - Private Drawing Methods

    private func drawHeader(
        authorName: String,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        var currentY = yPosition

        // Titre principal
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        let title = "Rapport d'inventaire MediStock"
        title.draw(
            at: CGPoint(x: PDFLayout.leftMargin, y: currentY),
            withAttributes: titleAttributes
        )
        currentY += 40

        // Date du rapport
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ]
        let dateString = "Généré le \(Date().formatted(date: .complete, time: .shortened))"
        dateString.draw(
            at: CGPoint(x: PDFLayout.leftMargin, y: currentY),
            withAttributes: dateAttributes
        )
        currentY += 30

        // Informations utilisateur
        let userInfo = "Utilisateur: \(authorName)"
        userInfo.draw(
            at: CGPoint(x: PDFLayout.leftMargin, y: currentY),
            withAttributes: dateAttributes
        )
        currentY += 40

        return currentY
    }

    private func drawSummary(
        medicines: [Medicine],
        aisles: [Aisle],
        context: UIGraphicsPDFRendererContext,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        drawSection(
            context: context,
            title: "Résumé",
            yPosition: yPosition,
            pageRect: pageRect
        ) { y in
            var currentY = y
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            let criticalCount = medicines.filter { $0.stockStatus == .critical }.count
            let expiringCount = medicines.filter { $0.isExpiringSoon && !$0.isExpired }.count

            let summaryItems = [
                "Nombre total de médicaments: \(medicines.count)",
                "Nombre de rayons: \(aisles.count)",
                "Médicaments en stock critique: \(criticalCount)",
                "Médicaments expirant bientôt: \(expiringCount)"
            ]

            for item in summaryItems {
                item.draw(
                    at: CGPoint(x: PDFLayout.leftMargin + 20, y: currentY),
                    withAttributes: summaryAttributes
                )
                currentY += 20
            }

            return currentY
        }
    }

    private func drawInventoryByAisle(
        medicines: [Medicine],
        aisles: [Aisle],
        context: UIGraphicsPDFRendererContext,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        drawSection(
            context: context,
            title: "Inventaire par rayon",
            yPosition: yPosition,
            pageRect: pageRect
        ) { y in
            var currentY = y
            let itemAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.black
            ]

            for aisle in aisles.sorted(by: { $0.name < $1.name }) {
                // Vérifier si on a besoin d'une nouvelle page
                if currentY > PDFLayout.pageHeight - PDFLayout.bottomMargin {
                    context.beginPage()
                    currentY = PDFLayout.topMargin
                }

                // Nom du rayon
                let aisleTitle = "• \(aisle.name)"
                let aisleTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 13),
                    .foregroundColor: UIColor.black
                ]
                aisleTitle.draw(
                    at: CGPoint(x: PDFLayout.leftMargin + 20, y: currentY),
                    withAttributes: aisleTitleAttributes
                )
                currentY += 20

                // Médicaments du rayon
                let medicinesInAisle = medicines.filter { $0.aisleId == (aisle.id ?? "") }
                if medicinesInAisle.isEmpty {
                    "  Aucun médicament".draw(
                        at: CGPoint(x: PDFLayout.leftMargin + 40, y: currentY),
                        withAttributes: itemAttributes
                    )
                    currentY += 20
                } else {
                    for medicine in medicinesInAisle.sorted(by: { $0.name < $1.name }) {
                        let medicineInfo = "  - \(medicine.name): \(medicine.currentQuantity)/\(medicine.maxQuantity) \(medicine.unit)"
                        medicineInfo.draw(
                            at: CGPoint(x: PDFLayout.leftMargin + 40, y: currentY),
                            withAttributes: itemAttributes
                        )
                        currentY += 18
                    }
                }
                currentY += 10
            }

            return currentY
        }
    }

    private func drawCriticalStock(
        medicines: [Medicine],
        context: UIGraphicsPDFRendererContext,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        drawSection(
            context: context,
            title: "Stocks critiques",
            yPosition: yPosition,
            pageRect: pageRect
        ) { y in
            var currentY = y
            let criticalAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.red
            ]

            for medicine in medicines.sorted(by: { $0.name < $1.name }) {
                let info = "• \(medicine.name): \(medicine.currentQuantity)/\(medicine.maxQuantity) \(medicine.unit) (Seuil critique: \(medicine.criticalThreshold))"
                info.draw(
                    at: CGPoint(x: PDFLayout.leftMargin + 20, y: currentY),
                    withAttributes: criticalAttributes
                )
                currentY += 20
            }

            return currentY
        }
    }

    private func drawExpiringMedicines(
        medicines: [Medicine],
        context: UIGraphicsPDFRendererContext,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        drawSection(
            context: context,
            title: "Expirations proches",
            yPosition: yPosition,
            pageRect: pageRect
        ) { y in
            var currentY = y
            let expiryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.orange
            ]

            for medicine in medicines.sorted(by: { $0.expiryDate ?? Date() < $1.expiryDate ?? Date() }) {
                if let expiryDate = medicine.expiryDate {
                    let status = medicine.isExpired ? "EXPIRÉ" : "Expire"
                    let info = "• \(medicine.name): \(status) le \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
                    let attributes = medicine.isExpired ? [
                        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: UIColor.red
                    ] : expiryAttributes
                    info.draw(
                        at: CGPoint(x: PDFLayout.leftMargin + 20, y: currentY),
                        withAttributes: attributes
                    )
                    currentY += 20
                }
            }

            return currentY
        }
    }

    private func drawSection(
        context: UIGraphicsPDFRendererContext,
        title: String,
        yPosition: CGFloat,
        pageRect: CGRect,
        drawContent: (CGFloat) -> CGFloat
    ) -> CGFloat {
        var currentY = yPosition

        // Vérifier si on a besoin d'une nouvelle page
        if currentY > PDFLayout.pageHeight - 150 {
            context.beginPage()
            currentY = PDFLayout.topMargin
        }

        // Titre de section
        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        title.draw(
            at: CGPoint(x: PDFLayout.leftMargin, y: currentY),
            withAttributes: sectionTitleAttributes
        )
        currentY += 25

        // Ligne de séparation
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: PDFLayout.leftMargin, y: currentY))
        linePath.addLine(to: CGPoint(x: pageRect.width - PDFLayout.rightMargin, y: currentY))
        UIColor.lightGray.setStroke()
        linePath.lineWidth = 0.5
        linePath.stroke()
        currentY += 15

        // Contenu de la section
        currentY = drawContent(currentY)
        currentY += 30

        return currentY
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
}
