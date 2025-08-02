import Foundation
import SwiftUI

// MARK: - History ViewModel

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var history: [HistoryEntry] = []
    @Published var stockHistory: [StockHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filterType: FilterType = .all
    
    enum FilterType: String, CaseIterable {
        case all = "Tout"
        case adjustments = "Ajustements"
        case additions = "Ajouts"
        case deletions = "Suppressions"
        
        var icon: String {
            switch self {
            case .all: return "clock"
            case .adjustments: return "arrow.up.arrow.down"
            case .additions: return "plus.circle"
            case .deletions: return "trash"
            }
        }
    }
    
    private let repository: HistoryRepositoryProtocol
    
    init(repository: HistoryRepositoryProtocol = HistoryRepository()) {
        self.repository = repository
    }
    
    var filteredHistory: [StockHistory] {
        switch filterType {
        case .all:
            return stockHistory
        case .adjustments:
            return stockHistory.filter { $0.type == .adjustment }
        case .additions:
            return stockHistory.filter { $0.type == .addition }
        case .deletions:
            return stockHistory.filter { $0.type == .deletion }
        }
    }
    
    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            history = try await repository.fetchHistory()
            // Convertir l'historique en StockHistory
            stockHistory = history.compactMap { entry in
                convertToStockHistory(entry)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func convertToStockHistory(_ entry: HistoryEntry) -> StockHistory {
        // Parser l'action pour déterminer le type
        let type: StockHistory.HistoryType
        if entry.action.contains("Ajout stock") || entry.action.contains("Retrait stock") || entry.action.contains("Ajustement") {
            type = .adjustment
        } else if entry.action == "Ajout" {
            type = .addition
        } else if entry.action.contains("supprim") {
            type = .deletion
        } else if entry.action == "Modification" {
            type = .adjustment
        } else {
            type = .adjustment
        }
        
        // Extraire le changement et les quantités depuis les détails
        let change = extractChange(from: entry.details)
        let quantities = extractQuantities(from: entry.details)
        
        return StockHistory(
            id: entry.id,
            medicineId: entry.medicineId,
            userId: entry.userId,
            type: type,
            date: entry.timestamp,
            change: change,
            previousQuantity: quantities.previous,
            newQuantity: quantities.new,
            reason: extractReason(from: entry.details)
        )
    }
    
    private func extractChange(from details: String) -> Int {
        // Extraire le nombre depuis "X unités - raison"
        if let match = details.firstMatch(of: /(\d+)\s+\w+/) {
            return Int(String(match.1)) ?? 0
        }
        return 0
    }
    
    private func extractQuantities(from details: String) -> (previous: Int, new: Int) {
        // Pour l'instant, retourner des valeurs par défaut
        return (0, 0)
    }
    
    private func extractReason(from details: String) -> String? {
        // Extraire la raison après le tiret
        if let dashIndex = details.firstIndex(of: "-") {
            let reasonStart = details.index(after: dashIndex)
            return String(details[reasonStart...]).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    func clearError() {
        errorMessage = nil
    }
}