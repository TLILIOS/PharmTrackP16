import Foundation
import SwiftUI

// MARK: - Medicine List ViewModel

@MainActor
class MedicineListViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedAisleId: String?
    @Published var hasMoreMedicines = true
    
    private let repository: MedicineRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    private let notificationService: NotificationService
    
    init(
        repository: MedicineRepositoryProtocol = MedicineRepository(),
        historyRepository: HistoryRepositoryProtocol = HistoryRepository(),
        notificationService: NotificationService = NotificationService()
    ) {
        self.repository = repository
        self.historyRepository = historyRepository
        self.notificationService = notificationService
    }
    
    // Computed property pour les médicaments filtrés
    var filteredMedicines: [Medicine] {
        var result = medicines
        
        // Filtre par recherche
        if !searchText.isEmpty {
            result = result.filter { medicine in
                medicine.name.localizedCaseInsensitiveContains(searchText) ||
                (medicine.reference?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filtre par rayon
        if let aisleId = selectedAisleId {
            result = result.filter { $0.aisleId == aisleId }
        }
        
        return result.sorted { $0.name < $1.name }
    }
    
    var criticalMedicines: [Medicine] {
        medicines.filter { $0.stockStatus == .critical }
    }
    
    var expiringMedicines: [Medicine] {
        medicines.filter { $0.isExpiringSoon && !$0.isExpired }
    }
    
    func loadMedicines() async {
        isLoading = true
        errorMessage = nil
        
        do {
            medicines = try await repository.fetchMedicinesPaginated(limit: 20, refresh: true)
            hasMoreMedicines = medicines.count >= 20
            await notificationService.checkExpirations(medicines: medicines)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMoreMedicines() async {
        guard !isLoadingMore && hasMoreMedicines else { return }
        
        isLoadingMore = true
        
        do {
            let newMedicines = try await repository.fetchMedicinesPaginated(limit: 20, refresh: false)
            medicines.append(contentsOf: newMedicines)
            hasMoreMedicines = newMedicines.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingMore = false
    }
    
    func saveMedicine(_ medicine: Medicine) async {
        do {
            let saved = try await repository.saveMedicine(medicine)
            
            if let index = medicines.firstIndex(where: { $0.id == saved.id }) {
                medicines[index] = saved
            } else {
                medicines.append(saved)
            }
            
            // Ajouter à l'historique
            let historyEntry = HistoryEntry(
                id: UUID().uuidString,
                medicineId: saved.id,
                userId: "", // Will be set by repository
                action: medicine.id.isEmpty ? "Ajout" : "Modification",
                details: "Médicament: \(saved.name)",
                timestamp: Date()
            )
            try await historyRepository.addHistoryEntry(historyEntry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteMedicine(_ medicine: Medicine) async {
        do {
            try await repository.deleteMedicine(id: medicine.id)
            medicines.removeAll { $0.id == medicine.id }
            
            // Ajouter à l'historique
            let historyEntry = HistoryEntry(
                id: UUID().uuidString,
                medicineId: medicine.id,
                userId: "",
                action: "Suppression",
                details: "Médicament supprimé: \(medicine.name)",
                timestamp: Date()
            )
            try await historyRepository.addHistoryEntry(historyEntry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func adjustStock(medicine: Medicine, adjustment: Int, reason: String) async {
        let newQuantity = max(0, medicine.currentQuantity + adjustment)
        
        do {
            let updated = try await repository.updateMedicineStock(id: medicine.id, newStock: newQuantity)
            
            if let index = medicines.firstIndex(where: { $0.id == updated.id }) {
                medicines[index] = updated
            }
            
            // Historique
            let historyEntry = HistoryEntry(
                id: UUID().uuidString,
                medicineId: medicine.id,
                userId: "",
                action: adjustment > 0 ? "Ajout stock" : "Retrait stock",
                details: "\(abs(adjustment)) \(medicine.unit) - \(reason)",
                timestamp: Date()
            )
            try await historyRepository.addHistoryEntry(historyEntry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}