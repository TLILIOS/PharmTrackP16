import Foundation
import SwiftUI

// MARK: - History ViewModel

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var history: [HistoryEntry] = []
    @Published var stockHistory: [StockHistory] = [] {
        didSet {
            updateFilteredHistory()
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filterType: FilterType = .all {
        didSet {
            updateFilteredHistory()
        }
    }
    @Published var filteredHistory: [StockHistory] = []

    enum FilterType: String, CaseIterable, Identifiable {
        case all = "Tout"
        case adjustments = "Ajustements"
        case additions = "Ajouts"
        case deletions = "Suppressions"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: return "clock.fill"
            case .adjustments: return "arrow.up.arrow.down.circle.fill"
            case .additions: return "plus.circle.fill"
            case .deletions: return "trash.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .all: return .accentColor
            case .adjustments: return .blue
            case .additions: return .green
            case .deletions: return .red
            }
        }
    }

    private let repository: HistoryRepositoryProtocol

    init(repository: HistoryRepositoryProtocol = HistoryRepository()) {
        self.repository = repository

        print("🎧 [HistoryViewModel] Initialisation et configuration du listener de notification")

        // Écouter les notifications de changement d'historique
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HistoryDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📢 [HistoryViewModel] Notification HistoryDidChange REÇUE !")
            Task { @MainActor [weak self] in
                print("🔄 [HistoryViewModel] Rechargement de l'historique suite à la notification...")
                await self?.loadHistory()
            }
        }

        print("✅ [HistoryViewModel] Listener de notification configuré avec succès")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func updateFilteredHistory() {
        print("🔄 Mise à jour du filtre: \(filterType.rawValue)")

        switch filterType {
        case .all:
            filteredHistory = stockHistory
        case .adjustments:
            filteredHistory = stockHistory.filter { $0.type == .adjustment }
        case .additions:
            filteredHistory = stockHistory.filter { $0.type == .addition }
        case .deletions:
            let deletions = stockHistory.filter { $0.type == .deletion }
            print("🗑️ Suppressions trouvées: \(deletions.count)")
            if deletions.isEmpty {
                print("⚠️ Aucune suppression dans stockHistory de \(stockHistory.count) éléments")
                // Afficher quelques exemples
                let examples = stockHistory.prefix(3).map { "'\($0.type)'" }.joined(separator: ", ")
                print("   Exemples de types: [\(examples)]")
            } else {
                deletions.forEach { deletion in
                    print("   ✓ Suppression trouvée: medicineId=\(deletion.medicineId)")
                }
            }
            filteredHistory = deletions
        }

        print("📊 Résultat filtré: \(filteredHistory.count) élément(s)")
    }
    
    func loadHistory() async {
        print("📡 [HistoryViewModel] loadHistory() appelée")
        isLoading = true
        errorMessage = nil

        do {
            print("🔄 [HistoryViewModel] Récupération de l'historique depuis le repository...")
            history = try await repository.fetchHistory()
            print("✅ [HistoryViewModel] Récupéré \(history.count) entrées depuis le repository")

            // 📋 Afficher TOUTES les actions brutes
            print("\n📋 === ACTIONS BRUTES DEPUIS LA BASE DE DONNÉES ===")
            let uniqueActions = Set(history.map { $0.action })
            print("Actions uniques trouvées: \(uniqueActions.sorted())")
            print("Détails des \(history.count) entrées:")
            for (index, entry) in history.enumerated() {
                print("  [\(index + 1)] Action: '\(entry.action)' | Details: '\(entry.details)'")
            }
            print("==============================================\n")

            // Convertir l'historique en StockHistory
            stockHistory = history.compactMap { entry in
                convertToStockHistory(entry)
            }

            // 📊 Afficher un résumé des types
            let adjustments = stockHistory.filter { $0.type == .adjustment }.count
            let additions = stockHistory.filter { $0.type == .addition }.count
            let deletions = stockHistory.filter { $0.type == .deletion }.count
            print("📊 Résumé historique: \(stockHistory.count) total | Ajustements: \(adjustments) | Ajouts: \(additions) | Suppressions: \(deletions)")
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    private func convertToStockHistory(_ entry: HistoryEntry) -> StockHistory {
        // Parser l'action pour déterminer le type
        let type: StockHistory.HistoryType
        let actionLowercased = entry.action.lowercased()

        // Déterminer le type basé sur l'action (ordre de priorité important)
        if actionLowercased.contains("supprim") || actionLowercased == "suppression" {
            type = .deletion
        } else if actionLowercased.contains("création") ||
                  actionLowercased == "création" ||
                  actionLowercased == "ajout" {  // 🔧 FIX: Reconnaître "Ajout" comme addition
            type = .addition
        } else if actionLowercased.contains("ajout stock") ||
                  actionLowercased.contains("retrait stock") ||
                  actionLowercased.contains("ajustement stock") ||
                  actionLowercased.contains("ajustement") ||
                  actionLowercased.contains("mise à jour") ||
                  actionLowercased == "modification" {
            type = .adjustment
        } else {
            // Par défaut, considérer comme un ajustement
            print("⚠️ Action non reconnue: '\(entry.action)' - classée comme adjustment")
            type = .adjustment
        }

        print("🔍 Action: '\(entry.action)' → Type: \(type)")

        
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