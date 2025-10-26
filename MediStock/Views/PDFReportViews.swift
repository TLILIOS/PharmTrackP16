import SwiftUI

// MARK: - PDF Layout Constants

enum PDFConstants {
    static let pageWidth: CGFloat = 8.5 * 72.0  // Letter size en points
    static let pageHeight: CGFloat = 11 * 72.0
    static let leftMargin: CGFloat = 50
    static let rightMargin: CGFloat = 50
    static let topMargin: CGFloat = 50
    static let bottomMargin: CGFloat = 100
    static let contentWidth: CGFloat = pageWidth - leftMargin - rightMargin
}

// MARK: - Composants réutilisables

/// En-tête de rapport PDF
struct PDFReportHeader: View {
    let title: String
    let authorName: String
    let additionalInfo: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)

            Text("Généré le \(Date().formatted(date: .complete, time: .shortened))")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            if let info = additionalInfo {
                Text(info)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            Text("Utilisateur: \(authorName)")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PDFConstants.leftMargin)
        .padding(.top, PDFConstants.topMargin)
    }
}

/// Section de rapport PDF avec titre et séparateur
struct PDFReportSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PDFConstants.leftMargin)
        .padding(.vertical, 15)
    }
}

/// Ligne d'information de rapport
struct PDFInfoLine: View {
    let text: String
    let indent: CGFloat
    let fontSize: CGFloat
    let color: Color

    init(
        _ text: String,
        indent: CGFloat = 20,
        fontSize: CGFloat = 12,
        color: Color = .black
    ) {
        self.text = text
        self.indent = indent
        self.fontSize = fontSize
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(color)
            .padding(.leading, indent)
    }
}

// MARK: - PDFInventoryReportView

/// Vue SwiftUI pour le rapport d'inventaire PDF
struct PDFInventoryReportView: View {
    let medicines: [Medicine]
    let aisles: [Aisle]
    let authorName: String

    var criticalMedicines: [Medicine] {
        medicines.filter { $0.stockStatus == .critical }
    }

    var expiringMedicines: [Medicine] {
        medicines.filter { $0.isExpiringSoon && !$0.isExpired }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // En-tête
            PDFReportHeader(
                title: "Rapport d'inventaire MediStock",
                authorName: authorName,
                additionalInfo: nil
            )

            // Résumé
            PDFReportSection(title: "Résumé") {
                VStack(alignment: .leading, spacing: 8) {
                    PDFInfoLine("Nombre total de médicaments: \(medicines.count)")
                    PDFInfoLine("Nombre de rayons: \(aisles.count)")
                    PDFInfoLine("Médicaments en stock critique: \(criticalMedicines.count)")
                    PDFInfoLine("Médicaments expirant bientôt: \(expiringMedicines.count)")
                }
            }

            // Inventaire par rayon
            PDFReportSection(title: "Inventaire par rayon") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(aisles.sorted(by: { $0.name < $1.name })) { aisle in
                        aisleSection(for: aisle)
                    }
                }
            }

            // Stocks critiques
            if !criticalMedicines.isEmpty {
                PDFReportSection(title: "Stocks critiques") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(criticalMedicines.sorted(by: { $0.name < $1.name })) { medicine in
                            PDFInfoLine(
                                "• \(medicine.name): \(medicine.currentQuantity)/\(medicine.maxQuantity) \(medicine.unit) (Seuil critique: \(medicine.criticalThreshold))",
                                fontSize: 11,
                                color: .red
                            )
                        }
                    }
                }
            }

            // Expirations proches
            if !expiringMedicines.isEmpty {
                PDFReportSection(title: "Expirations proches") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(expiringMedicines.sorted(by: { ($0.expiryDate ?? Date()) < ($1.expiryDate ?? Date()) })) { medicine in
                            if let expiryDate = medicine.expiryDate {
                                let status = medicine.isExpired ? "EXPIRÉ" : "Expire"
                                PDFInfoLine(
                                    "• \(medicine.name): \(status) le \(expiryDate.formatted(date: .abbreviated, time: .omitted))",
                                    fontSize: 11,
                                    color: medicine.isExpired ? .red : .orange
                                )
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(width: PDFConstants.pageWidth, height: PDFConstants.pageHeight)
        .background(Color.white)
    }

    @ViewBuilder
    private func aisleSection(for aisle: Aisle) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            PDFInfoLine(
                "• \(aisle.name)",
                fontSize: 13,
                color: .black
            )
            .fontWeight(.bold)

            let medicinesInAisle = medicines.filter { $0.aisleId == (aisle.id ?? "") }

            if medicinesInAisle.isEmpty {
                PDFInfoLine("  Aucun médicament", indent: 40, fontSize: 11)
            } else {
                ForEach(medicinesInAisle.sorted(by: { $0.name < $1.name })) { medicine in
                    PDFInfoLine(
                        "  - \(medicine.name): \(medicine.currentQuantity)/\(medicine.maxQuantity) \(medicine.unit)",
                        indent: 40,
                        fontSize: 11
                    )
                }
            }
        }
    }
}

// MARK: - PDFHistoryReportView

/// Vue SwiftUI pour le rapport d'historique PDF
struct PDFHistoryReportView: View {
    let entries: [HistoryEntry]
    let statistics: HistoryStatistics?
    let dateRange: String
    let authorName: String

    var groupedEntries: [(Date, [HistoryEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return grouped.sorted(by: { $0.key > $1.key })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // En-tête
            PDFReportHeader(
                title: "Rapport d'historique MediStock",
                authorName: authorName,
                additionalInfo: "Période: \(dateRange)"
            )

            // Statistiques
            if let stats = statistics {
                PDFReportSection(title: "Statistiques du mois") {
                    VStack(alignment: .leading, spacing: 8) {
                        PDFInfoLine("Actions totales: \(stats.totalActions)")
                        PDFInfoLine("Ajouts: \(stats.addActions)")
                        PDFInfoLine("Retraits: \(stats.removeActions)")
                        PDFInfoLine("Modifications: \(stats.modifications)")

                        if !stats.topMedicines.isEmpty {
                            Text("Médicaments les plus actifs:")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.leading, 20)
                                .padding(.top, 5)

                            ForEach(stats.topMedicines.prefix(3), id: \.name) { medicine in
                                PDFInfoLine("  • \(medicine.name): \(medicine.count) actions", indent: 40, fontSize: 11)
                            }
                        }
                    }
                }
            }

            // Liste des actions
            PDFReportSection(title: "Historique des actions (\(entries.count) entrées)") {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(groupedEntries, id: \.0) { date, dayEntries in
                        daySection(date: date, entries: dayEntries)
                    }
                }
            }

            Spacer()
        }
        .frame(width: PDFConstants.pageWidth, height: PDFConstants.pageHeight)
        .background(Color.white)
    }

    @ViewBuilder
    private func daySection(date: Date, entries: [HistoryEntry]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(date.formatted(date: .complete, time: .omitted))
                .font(.system(size: 13, weight: .bold))
                .padding(.leading, 20)
                .padding(.top, 5)

            ForEach(entries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                VStack(alignment: .leading, spacing: 3) {
                    let timeString = entry.timestamp.formatted(date: .omitted, time: .shortened)
                    PDFInfoLine(
                        "\(timeString) - \(entry.action)",
                        indent: 40,
                        fontSize: 11
                    )

                    Text(entry.details)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .padding(.leading, 40)
                }
            }
        }
    }
}

// MARK: - PDFStockHistoryReportView

/// Vue SwiftUI pour le rapport de mouvements de stock PDF
struct PDFStockHistoryReportView: View {
    let entries: [StockHistory]
    let medicines: [String: String]
    let filterType: String
    let authorName: String

    var adjustmentsCount: Int {
        entries.filter { $0.type == .adjustment }.count
    }

    var additionsCount: Int {
        entries.filter { $0.type == .addition }.count
    }

    var deletionsCount: Int {
        entries.filter { $0.type == .deletion }.count
    }

    var groupedEntries: [(Date, [StockHistory])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped.sorted(by: { $0.key > $1.key })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // En-tête
            PDFReportHeader(
                title: "Rapport de mouvements de stock",
                authorName: authorName,
                additionalInfo: "Filtre: \(filterType)"
            )

            // Statistiques
            PDFReportSection(title: "Statistiques") {
                VStack(alignment: .leading, spacing: 8) {
                    PDFInfoLine("Mouvements totaux: \(entries.count)")
                    PDFInfoLine("Ajustements de stock: \(adjustmentsCount)")
                    PDFInfoLine("Médicaments ajoutés: \(additionsCount)")
                    PDFInfoLine("Médicaments supprimés: \(deletionsCount)")
                }
            }

            // Détail des mouvements
            PDFReportSection(title: "Détail des mouvements (\(entries.count) entrées)") {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(groupedEntries, id: \.0) { date, dayEntries in
                        daySection(date: date, entries: dayEntries)
                    }
                }
            }

            Spacer()
        }
        .frame(width: PDFConstants.pageWidth, height: PDFConstants.pageHeight)
        .background(Color.white)
    }

    @ViewBuilder
    private func daySection(date: Date, entries: [StockHistory]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(date.formatted(date: .complete, time: .omitted))
                .font(.system(size: 13, weight: .bold))
                .padding(.leading, 20)
                .padding(.top, 5)

            ForEach(entries.sorted(by: { $0.date > $1.date })) { entry in
                stockHistoryEntry(entry)
            }
        }
    }

    @ViewBuilder
    private func stockHistoryEntry(_ entry: StockHistory) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            let medicineName = medicines[entry.medicineId] ?? "Médicament supprimé"
            let timeString = entry.date.formatted(date: .omitted, time: .shortened)

            let (typeLabel, typeColor) = typeInfo(for: entry.type)

            PDFInfoLine(
                "\(timeString) - \(medicineName) [\(typeLabel)]",
                indent: 40,
                fontSize: 11,
                color: typeColor
            )

            // Détails de la modification
            if entry.type == .adjustment {
                let changeSign = entry.change >= 0 ? "+" : ""
                PDFInfoLine(
                    "Quantité: \(entry.previousQuantity) → \(entry.newQuantity) (\(changeSign)\(entry.change))",
                    indent: 40,
                    fontSize: 10,
                    color: .gray
                )
            } else if entry.type == .addition {
                PDFInfoLine(
                    "Quantité ajoutée: \(entry.newQuantity)",
                    indent: 40,
                    fontSize: 10,
                    color: .gray
                )
            } else if entry.type == .deletion {
                PDFInfoLine(
                    "Quantité retirée: \(entry.previousQuantity)",
                    indent: 40,
                    fontSize: 10,
                    color: .gray
                )
            }

            // Raison si présente
            if let reason = entry.reason, !reason.isEmpty {
                PDFInfoLine(
                    "Raison: \(reason)",
                    indent: 40,
                    fontSize: 10,
                    color: .gray
                )
            }
        }
    }

    private func typeInfo(for type: StockHistory.HistoryType) -> (String, Color) {
        switch type {
        case .adjustment:
            return ("Ajustement", .blue)
        case .addition:
            return ("Ajout", .green)
        case .deletion:
            return ("Suppression", .red)
        }
    }
}
