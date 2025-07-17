import SwiftUI
import Observation

@Observable
final class ObservableAdjustStockViewModel {
    // MARK: - Published Properties
    var medicine: Medicine?
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    private let medicineId: String
    private let medicineRepository: any MedicineRepositoryProtocol
    private let historyRepository: any HistoryRepositoryProtocol
    
    // MARK: - Initializer
    init(
        medicineId: String,
        medicineRepository: any MedicineRepositoryProtocol,
        historyRepository: any HistoryRepositoryProtocol
    ) {
        self.medicineId = medicineId
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
        
        Task {
            await loadMedicine()
        }
    }
    
    // MARK: - Methods
    @MainActor
    func loadMedicine() async {
        isLoading = true
        errorMessage = nil
        
        do {
            medicine = try await medicineRepository.getMedicine(id: medicineId)
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    func adjustStock(newQuantity: Int, reason: String) async -> Bool {
        guard let currentMedicine = medicine else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedMedicine = Medicine(
                id: currentMedicine.id,
                name: currentMedicine.name,
                description: currentMedicine.description,
                dosage: currentMedicine.dosage,
                form: currentMedicine.form,
                reference: currentMedicine.reference,
                unit: currentMedicine.unit,
                currentQuantity: newQuantity,
                maxQuantity: currentMedicine.maxQuantity,
                warningThreshold: currentMedicine.warningThreshold,
                criticalThreshold: currentMedicine.criticalThreshold,
                expiryDate: currentMedicine.expiryDate,
                aisleId: currentMedicine.aisleId,
                createdAt: currentMedicine.createdAt,
                updatedAt: Date()
            )
            
            medicine = try await medicineRepository.saveMedicine(updatedMedicine)
            
            // Ajouter à l'historique
            let historyEntry = HistoryEntry(
                id: UUID().uuidString,
                medicineId: currentMedicine.id,
                userId: "system",
                action: "Ajustement de stock",
                details: reason,
                timestamp: Date()
            )
            
            try await historyRepository.addHistoryEntry(historyEntry)
            
            // Post notification to update other views
            NotificationCenter.default.post(name: Notification.Name("StockAdjusted"), object: nil)
            NotificationCenter.default.post(name: Notification.Name("MedicineUpdated"), object: nil)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Erreur lors de l'ajustement: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    @MainActor
    func resetError() {
        errorMessage = nil
    }
}