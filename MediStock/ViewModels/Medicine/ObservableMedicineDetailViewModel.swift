import SwiftUI
import Observation

@Observable
final class ObservableMedicineDetailViewModel {
    // MARK: - Published Properties
    var medicine: Medicine?
    var isLoading = false
    var errorMessage: String?
    var history: [HistoryEntry] = []
    var isLoadingHistory = false
    
    // MARK: - Dependencies
    private let medicineRepository: any MedicineRepositoryProtocol
    private let aisleRepository: any AisleRepositoryProtocol
    private let historyRepository: any HistoryRepositoryProtocol
    
    // MARK: - Computed Properties
    var aisleName: String? {
        // Cette propriété devrait être calculée de manière réactive
        return nil // À implémenter selon votre logique
    }
    
    // MARK: - Initializer
    init(
        medicineId: String,
        medicineRepository: any MedicineRepositoryProtocol,
        aisleRepository: any AisleRepositoryProtocol,
        historyRepository: any HistoryRepositoryProtocol
    ) {
        self.medicineRepository = medicineRepository
        self.aisleRepository = aisleRepository
        self.historyRepository = historyRepository
        
        Task {
            await loadMedicine(id: medicineId)
        }
    }
    
    // MARK: - Methods
    @MainActor
    func loadMedicine(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            medicine = try await medicineRepository.getMedicine(id: id)
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchHistory() async {
        guard let medicineId = medicine?.id else { return }
        
        isLoadingHistory = true
        
        do {
            history = try await historyRepository.getHistoryForMedicine(medicineId: medicineId)
        } catch {
            errorMessage = "Erreur lors du chargement de l'historique: \(error.localizedDescription)"
        }
        
        isLoadingHistory = false
    }
    
    @MainActor
    func deleteMedicine() async {
        guard let medicine = medicine else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await medicineRepository.deleteMedicine(id: medicine.id)
            // Navigation handled by the view
        } catch {
            errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    func adjustStock(newQuantity: Int, reason: String) async {
        guard let currentMedicine = medicine else { return }
        
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
            
           _ = try await historyRepository.addHistoryEntry(historyEntry)
            
        } catch {
            errorMessage = "Erreur lors de l'ajustement: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - View Integration Helper
extension ObservableMedicineDetailViewModel {
    static func create(
        medicineId: String,
        medicineRepository: any MedicineRepositoryProtocol,
        aisleRepository: any AisleRepositoryProtocol,
        historyRepository: any HistoryRepositoryProtocol
    ) -> ObservableMedicineDetailViewModel {
        return ObservableMedicineDetailViewModel(
            medicineId: medicineId,
            medicineRepository: medicineRepository,
            aisleRepository: aisleRepository,
            historyRepository: historyRepository
        )
    }
}
