import Foundation
import SwiftUI
import FirebaseAuth

// MARK: - HistoryDetailViewModel

@MainActor
class HistoryDetailViewModel: ObservableObject {
    @Published var historyEntries: [HistoryEntry] = []
    @Published var filteredEntries: [HistoryEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filtres
    @Published var selectedDateRange: DateRange = .all
    @Published var selectedActionType: ActionType? = nil
    @Published var searchText = ""
    
    // Statistiques
    @Published var statistics: HistoryStatistics?
    
    private let historyRepository: HistoryRepositoryProtocol
    private let medicineRepository: MedicineRepositoryProtocol
    private let pdfExportService: PDFExportServiceProtocol

    init(
        historyRepository: HistoryRepositoryProtocol = HistoryRepository(),
        medicineRepository: MedicineRepositoryProtocol = MedicineRepository(),
        pdfExportService: PDFExportServiceProtocol = PDFExportService()
    ) {
        self.historyRepository = historyRepository
        self.medicineRepository = medicineRepository
        self.pdfExportService = pdfExportService
    }
    
    // MARK: - Load History
    
    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            historyEntries = try await historyRepository.fetchHistory()
            applyFilters()
            await calculateStatistics()
            
            // Logger l'événement
            FirebaseService.shared.logScreenView(screenName: "History")
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadHistoryForMedicine(_ medicineId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            historyEntries = try await historyRepository.fetchHistoryForMedicine(medicineId)
            applyFilters()
            await calculateStatistics()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Filtering
    
    func applyFilters() {
        var result = historyEntries
        
        // Filtre par plage de dates
        if let dateRange = selectedDateRange.dateInterval {
            result = result.filter { entry in
                entry.timestamp >= dateRange.start && entry.timestamp <= dateRange.end
            }
        }
        
        // Filtre par type d'action
        if let actionType = selectedActionType {
            result = result.filter { entry in
                entry.action.lowercased().contains(actionType.rawValue.lowercased())
            }
        }
        
        // Filtre par recherche
        if !searchText.isEmpty {
            result = result.filter { entry in
                entry.details.localizedCaseInsensitiveContains(searchText) ||
                entry.action.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Trier par date décroissante
        filteredEntries = result.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Statistics
    
    private func calculateStatistics() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let monthEntries = filteredEntries.filter { $0.timestamp >= startOfMonth }
        
        let totalActions = monthEntries.count
        let addActions = monthEntries.filter { $0.action.contains("Ajout") }.count
        let removeActions = monthEntries.filter { $0.action.contains("Retrait") }.count
        let modifications = monthEntries.filter { $0.action.contains("Modification") }.count
        
        // Calculer les médicaments les plus actifs
        var medicineActivityCount: [String: Int] = [:]
        for entry in monthEntries {
            medicineActivityCount[entry.medicineId, default: 0] += 1
        }
        
        let topMedicineIds = medicineActivityCount
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        // Récupérer les noms des médicaments
        var topMedicines: [(name: String, count: Int)] = []
        do {
            let medicines = try await medicineRepository.fetchMedicines()
            for medicineId in topMedicineIds {
                if let medicine = medicines.first(where: { $0.id == medicineId }),
                   let count = medicineActivityCount[medicineId] {
                    topMedicines.append((medicine.name, count))
                }
            }
        } catch {
            // Failed to fetch medicines
        }
        
        statistics = HistoryStatistics(
            totalActions: totalActions,
            addActions: addActions,
            removeActions: removeActions,
            modifications: modifications,
            topMedicines: topMedicines
        )
    }
    
    // MARK: - Export
    
    func exportHistory(format: ExportFormat) async throws -> URL {
        switch format {
        case .csv:
            return try await exportToCSV()
        case .pdf:
            return try await exportToPDF()
        }
    }
    
    private func exportToCSV() async throws -> URL {
        var csvContent = "Date,Heure,Action,Détails,Utilisateur\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "fr_FR")
        
        for entry in filteredEntries {
            let date = dateFormatter.string(from: entry.timestamp)
            let action = entry.action.replacingOccurrences(of: ",", with: ";")
            let details = entry.details.replacingOccurrences(of: ",", with: ";")
            
            csvContent += "\(date),\(action),\(details),\(entry.userId)\n"
        }
        
        // Sauvegarder le fichier
        let fileName = "historique_\(Date().timeIntervalSince1970).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        
        // Logger l'export
        FirebaseService.shared.logEvent(AnalyticsEvent(
            name: "history_export",
            parameters: [
                "format": "csv",
                "entry_count": filteredEntries.count
            ]
        ))
        
        return tempURL
    }
    
    private func exportToPDF() async throws -> URL {
        // Récupérer l'utilisateur actuel
        let firebaseUser = Auth.auth().currentUser
        let authorName = firebaseUser?.displayName ??
                        firebaseUser?.email ??
                        "Utilisateur"

        // Récupérer le libellé de la plage de dates
        let dateRangeLabel = selectedDateRange.rawValue

        // Générer le PDF via le service
        let pdfData = try await pdfExportService.generateHistoryReport(
            entries: filteredEntries,
            statistics: statistics,
            dateRange: dateRangeLabel,
            authorName: authorName
        )

        // Sauvegarder le fichier temporaire
        let fileName = "historique_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try pdfData.write(to: tempURL)

        // Logger l'export
        FirebaseService.shared.logEvent(AnalyticsEvent(
            name: "history_export",
            parameters: [
                "format": "pdf",
                "entry_count": filteredEntries.count
            ]
        ))

        return tempURL
    }
}

// MARK: - Models

struct HistoryStatistics {
    let totalActions: Int
    let addActions: Int
    let removeActions: Int
    let modifications: Int
    let topMedicines: [(name: String, count: Int)]
}

enum DateRange: String, CaseIterable {
    case today = "Aujourd'hui"
    case week = "Cette semaine"
    case month = "Ce mois"
    case threeMonths = "3 derniers mois"
    case all = "Tout"
    
    var dateInterval: DateInterval? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.dateInterval(of: .day, for: now)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now)
        case .month:
            return calendar.dateInterval(of: .month, for: now)
        case .threeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return DateInterval(start: threeMonthsAgo, end: now)
        case .all:
            return nil
        }
    }
}

enum ActionType: String, CaseIterable {
    case addition = "Ajout"
    case removal = "Retrait"
    case modification = "Modification"
    case deletion = "Suppression"
    case stockAdjustment = "Ajustement stock"
    
    var icon: String {
        switch self {
        case .addition:
            return "plus.circle"
        case .removal:
            return "minus.circle"
        case .modification:
            return "pencil.circle"
        case .deletion:
            return "trash.circle"
        case .stockAdjustment:
            return "arrow.up.arrow.down.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .addition:
            return .green
        case .removal:
            return .orange
        case .modification:
            return .blue
        case .deletion:
            return .red
        case .stockAdjustment:
            return .purple
        }
    }
}

enum ExportFormat {
    case csv
    case pdf
}

enum ExportError: LocalizedError {
    case formatNotSupported
    case exportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .formatNotSupported:
            return "Format d'export non supporté"
        case .exportFailed(let reason):
            return "Échec de l'export: \(reason)"
        }
    }
}
