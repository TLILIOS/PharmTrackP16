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

    func generateHistoryReport(
        entries: [HistoryEntry],
        statistics: HistoryStatistics?,
        dateRange: String,
        authorName: String
    ) async throws -> Data {

        let pdfMetaData = [
            kCGPDFContextCreator: "MediStock",
            kCGPDFContextAuthor: authorName,
            kCGPDFContextTitle: "Rapport d'historique MediStock"
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
            yPosition = drawHistoryHeader(
                authorName: authorName,
                dateRange: dateRange,
                yPosition: yPosition,
                pageRect: pageRect
            )

            // Statistiques
            if let stats = statistics {
                yPosition = drawHistoryStatistics(
                    statistics: stats,
                    context: context,
                    yPosition: yPosition,
                    pageRect: pageRect
                )
            }

            // Liste des actions
            yPosition = drawHistoryEntries(
                entries: entries,
                context: context,
                yPosition: yPosition,
                pageRect: pageRect
            )
        }

        return data
    }

    func generateStockHistoryReport(
        entries: [StockHistory],
        medicines: [String: String],
        filterType: String,
        authorName: String
    ) async throws -> Data {

        let pdfMetaData = [
            kCGPDFContextCreator: "MediStock",
            kCGPDFContextAuthor: authorName,
            kCGPDFContextTitle: "Rapport de mouvements de stock MediStock"
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
            yPosition = drawStockHistoryHeader(
                authorName: authorName,
                filterType: filterType,
                yPosition: yPosition,
                pageRect: pageRect
            )

            // Statistiques
            yPosition = drawStockHistoryStatistics(
                entries: entries,
                context: context,
                yPosition: yPosition,
                pageRect: pageRect
            )

            // Liste des mouvements
            yPosition = drawStockHistoryEntries(
                entries: entries,
                medicines: medicines,
                context: context,
                yPosition: yPosition,
                pageRect: pageRect
            )
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

    // MARK: - History Report Drawing Methods

    private func drawHistoryHeader(
        authorName: String,
        dateRange: String,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        var currentY = yPosition

        // Titre principal
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        let title = "Rapport d'historique MediStock"
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
        currentY += 25

        // Période sélectionnée
        let periodString = "Période: \(dateRange)"
        periodString.draw(
            at: CGPoint(x: PDFLayout.leftMargin, y: currentY),
            withAttributes: dateAttributes
        )
        currentY += 25

        // Informations utilisateur
        let userInfo = "Utilisateur: \(authorName)"
        userInfo.draw(
            at: CGPoint(x: PDFLayout.leftMargin, y: currentY),
            withAttributes: dateAttributes
        )
        currentY += 40

        return currentY
    }

    private func drawHistoryStatistics(
        statistics: HistoryStatistics,
        context: UIGraphicsPDFRendererContext,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        drawSection(
            context: context,
            title: "Statistiques du mois",
            yPosition: yPosition,
            pageRect: pageRect
        ) { y in
            var currentY = y
            let statsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            let statsItems = [
                "Actions totales: \(statistics.totalActions)",
                "Ajouts: \(statistics.addActions)",
                "Retraits: \(statistics.removeActions)",
                "Modifications: \(statistics.modifications)"
            ]

            for item in statsItems {
                item.draw(
                    at: CGPoint(x: PDFLayout.leftMargin + 20, y: currentY),
                    withAttributes: statsAttributes
                )
                currentY += 20
            }

            // Top médicaments
            if !statistics.topMedicines.isEmpty {
                currentY += 10
                "Médicaments les plus actifs:".draw(
                    at: CGPoint(x: PDFLayout.leftMargin + 20, y: currentY),
                    withAttributes: [
                        .font: UIFont.boldSystemFont(ofSize: 12),
                        .foregroundColor: UIColor.black
                    ]
                )
                currentY += 20

                for medicine in statistics.topMedicines.prefix(3) {
                    "  • \(medicine.name): \(medicine.count) actions".draw(
                        at: CGPoint(x: PDFLayout.leftMargin + 40, y: currentY),
                        withAttributes: statsAttributes
                    )
                    currentY += 18
                }
            }

            return currentY
        }
    }

    private func drawHistoryEntries(
        entries: [HistoryEntry],
        context: UIGraphicsPDFRendererContext,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        drawSection(
            context: context,
            title: "Historique des actions (\(entries.count) entrées)",
            yPosition: yPosition,
            pageRect: pageRect
        ) { y in
            var currentY = y
            let entryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.black
            ]
            let detailsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]

            // Grouper par date
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: entries) { entry in
                calendar.startOfDay(for: entry.timestamp)
            }
            let sortedDates = grouped.keys.sorted(by: >)

            for date in sortedDates {
                guard let dayEntries = grouped[date] else { continue }

                // Vérifier si on a besoin d'une nouvelle page
                if currentY > PDFLayout.pageHeight - PDFLayout.bottomMargin {
                    context.beginPage()
                    currentY = PDFLayout.topMargin
                }

                // Date du jour
                let dateString = date.formatted(date: .complete, time: .omitted)
                let dateTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 13),
                    .foregroundColor: UIColor.black
                ]
                dateString.draw(
                    at: CGPoint(x: PDFLayout.leftMargin + 20, y: currentY),
                    withAttributes: dateTitleAttributes
                )
                currentY += 20

                // Entrées du jour
                for entry in dayEntries.sorted(by: { $0.timestamp > $1.timestamp }) {
                    // Vérifier si on a besoin d'une nouvelle page
                    if currentY > PDFLayout.pageHeight - PDFLayout.bottomMargin - 60 {
                        context.beginPage()
                        currentY = PDFLayout.topMargin
                    }

                    // Heure et action
                    let timeString = entry.timestamp.formatted(date: .omitted, time: .shortened)
                    let actionString = "\(timeString) - \(entry.action)"
                    actionString.draw(
                        at: CGPoint(x: PDFLayout.leftMargin + 40, y: currentY),
                        withAttributes: entryAttributes
                    )
                    currentY += 18

                    // Détails
                    let details = entry.details
                    let maxWidth = PDFLayout.pageWidth - PDFLayout.leftMargin - PDFLayout.rightMargin - 60
                    let detailsRect = CGRect(
                        x: PDFLayout.leftMargin + 40,
                        y: currentY,
                        width: maxWidth,
                        height: 1000
                    )
                    details.draw(
                        in: detailsRect,
                        withAttributes: detailsAttributes
                    )
                    currentY += 15
                }

                currentY += 10
            }

            return currentY
        }
    }

    // MARK: - Stock History Report Drawing Methods

    private func drawStockHistoryHeader(
        authorName: String,
        filterType: String,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        var currentY = yPosition

        // Titre principal
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        let title = "Rapport de mouvements de stock"
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
        currentY += 25

        // Filtre appliqué
        let filterString = "Filtre: \(filterType)"
        filterString.draw(
            at: CGPoint(x: PDFLayout.leftMargin, y: currentY),
            withAttributes: dateAttributes
        )
        currentY += 25

        // Informations utilisateur
        let userInfo = "Utilisateur: \(authorName)"
        userInfo.draw(
            at: CGPoint(x: PDFLayout.leftMargin, y: currentY),
            withAttributes: dateAttributes
        )
        currentY += 40

        return currentY
    }

    private func drawStockHistoryStatistics(
        entries: [StockHistory],
        context: UIGraphicsPDFRendererContext,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        drawSection(
            context: context,
            title: "Statistiques",
            yPosition: yPosition,
            pageRect: pageRect
        ) { y in
            var currentY = y
            let statsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            let adjustments = entries.filter { $0.type == .adjustment }.count
            let additions = entries.filter { $0.type == .addition }.count
            let deletions = entries.filter { $0.type == .deletion }.count

            let statsItems = [
                "Mouvements totaux: \(entries.count)",
                "Ajustements de stock: \(adjustments)",
                "Médicaments ajoutés: \(additions)",
                "Médicaments supprimés: \(deletions)"
            ]

            for item in statsItems {
                item.draw(
                    at: CGPoint(x: PDFLayout.leftMargin + 20, y: currentY),
                    withAttributes: statsAttributes
                )
                currentY += 20
            }

            return currentY
        }
    }

    private func drawStockHistoryEntries(
        entries: [StockHistory],
        medicines: [String: String],
        context: UIGraphicsPDFRendererContext,
        yPosition: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        drawSection(
            context: context,
            title: "Détail des mouvements (\(entries.count) entrées)",
            yPosition: yPosition,
            pageRect: pageRect
        ) { y in
            var currentY = y
            let detailsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray
            ]

            // Grouper par date
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: entries) { entry in
                calendar.startOfDay(for: entry.date)
            }
            let sortedDates = grouped.keys.sorted(by: >)

            for date in sortedDates {
                guard let dayEntries = grouped[date] else { continue }

                // Vérifier si on a besoin d'une nouvelle page
                if currentY > PDFLayout.pageHeight - PDFLayout.bottomMargin {
                    context.beginPage()
                    currentY = PDFLayout.topMargin
                }

                // Date du jour
                let dateString = date.formatted(date: .complete, time: .omitted)
                let dateTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 13),
                    .foregroundColor: UIColor.black
                ]
                dateString.draw(
                    at: CGPoint(x: PDFLayout.leftMargin + 20, y: currentY),
                    withAttributes: dateTitleAttributes
                )
                currentY += 20

                // Entrées du jour
                for entry in dayEntries.sorted(by: { $0.date > $1.date }) {
                    // Vérifier si on a besoin d'une nouvelle page
                    if currentY > PDFLayout.pageHeight - PDFLayout.bottomMargin - 80 {
                        context.beginPage()
                        currentY = PDFLayout.topMargin
                    }

                    // Nom du médicament
                    let medicineName = medicines[entry.medicineId] ?? "Médicament supprimé"
                    let timeString = entry.date.formatted(date: .omitted, time: .shortened)

                    // Type d'action et détails
                    let typeLabel: String
                    let typeColor: UIColor
                    switch entry.type {
                    case .adjustment:
                        typeLabel = "Ajustement"
                        typeColor = .blue
                    case .addition:
                        typeLabel = "Ajout"
                        typeColor = .green
                    case .deletion:
                        typeLabel = "Suppression"
                        typeColor = .red
                    }

                    // Ligne principale
                    let mainLine = "\(timeString) - \(medicineName) [\(typeLabel)]"
                    let mainAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: typeColor
                    ]
                    mainLine.draw(
                        at: CGPoint(x: PDFLayout.leftMargin + 40, y: currentY),
                        withAttributes: mainAttributes
                    )
                    currentY += 18

                    // Détails de la modification
                    var detailsLine = ""
                    if entry.type == .adjustment {
                        let changeSign = entry.change >= 0 ? "+" : ""
                        detailsLine = "  Quantité: \(entry.previousQuantity) → \(entry.newQuantity) (\(changeSign)\(entry.change))"
                    } else if entry.type == .addition {
                        detailsLine = "  Quantité ajoutée: \(entry.newQuantity)"
                    } else if entry.type == .deletion {
                        detailsLine = "  Quantité retirée: \(entry.previousQuantity)"
                    }

                    detailsLine.draw(
                        at: CGPoint(x: PDFLayout.leftMargin + 40, y: currentY),
                        withAttributes: detailsAttributes
                    )
                    currentY += 15

                    // Raison si présente
                    if let reason = entry.reason, !reason.isEmpty {
                        let reasonLine = "  Raison: \(reason)"
                        let maxWidth = PDFLayout.pageWidth - PDFLayout.leftMargin - PDFLayout.rightMargin - 60
                        let reasonRect = CGRect(
                            x: PDFLayout.leftMargin + 40,
                            y: currentY,
                            width: maxWidth,
                            height: 1000
                        )
                        reasonLine.draw(
                            in: reasonRect,
                            withAttributes: detailsAttributes
                        )
                        currentY += 15
                    }

                    currentY += 5
                }

                currentY += 10
            }

            return currentY
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
