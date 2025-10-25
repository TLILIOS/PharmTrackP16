import Foundation

// MARK: - History Repository

class HistoryRepository: HistoryRepositoryProtocol {
    private let historyService: HistoryDataService

    init(historyService: HistoryDataService = HistoryDataService()) {
        self.historyService = historyService
    }

    func fetchHistoryForMedicine(_ medicineId: String) async throws -> [HistoryEntry] {
        // Utiliser le filtre medicineId du service modulaire
        return try await historyService.getHistory(medicineId: medicineId)
    }

    func fetchHistory() async throws -> [HistoryEntry] {
        // Récupérer tout l'historique (medicineId: nil)
        return try await historyService.getHistory(medicineId: nil)
    }

    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        // Cette méthode est dépréciée - le service utilise maintenant des méthodes spécialisées
        // Mais pour maintenir la compatibilité avec HistoryRepositoryProtocol, on la garde
        // en déléguant vers recordMedicineAction avec les infos disponibles

        if !entry.medicineId.isEmpty {
            // Extraire le nom du médicament des détails si possible
            let medicineName = extractMedicineName(from: entry.details)

            try await historyService.recordMedicineAction(
                medicineId: entry.medicineId,
                medicineName: medicineName,
                action: entry.action,
                details: entry.details
            )
        } else {
            // Action générale - utiliser recordDeletion comme fallback
            try await historyService.recordDeletion(
                itemType: "general",
                itemId: entry.id,
                itemName: "",
                details: entry.details
            )
        }
    }

    // MARK: - Helper

    private func extractMedicineName(from details: String) -> String {
        // Recherche de patterns courants dans les détails
        // Ex: "Modification du médicament Doliprane"
        if let range = details.range(of: "médicament ") {
            let afterMedicine = String(details[range.upperBound...])
            let name = afterMedicine.split(separator: " ").first ?? ""
            return String(name)
        }
        return ""
    }
}
