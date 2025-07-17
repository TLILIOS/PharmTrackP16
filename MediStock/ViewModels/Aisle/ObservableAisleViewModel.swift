import SwiftUI
import Observation

@Observable
final class ObservableAisleViewModel {
    // MARK: - Published Properties
    var aisles: [Aisle] = []
    var medicinesByAisle: [String: [Medicine]] = [:]
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    private let aisleRepository: any AisleRepositoryProtocol
    private let medicineRepository: any MedicineRepositoryProtocol
    
    // MARK: - Computed Properties
    var sortedAisles: [Aisle] {
        aisles.sorted { $0.name < $1.name }
    }
    
    // MARK: - Initializer
    init(
        aisleRepository: any AisleRepositoryProtocol,
        medicineRepository: any MedicineRepositoryProtocol
    ) {
        self.aisleRepository = aisleRepository
        self.medicineRepository = medicineRepository
        
        Task {
            await loadAisles()
        }
    }
    
    // MARK: - Methods
    @MainActor
    func loadAisles() async {
        isLoading = true
        errorMessage = nil
        
        do {
            aisles = try await aisleRepository.getAisles()
            await loadMedicinesForAisles()
        } catch {
            errorMessage = "Erreur lors du chargement des rayons: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMedicinesForAisles() async {
        do {
            let allMedicines = try await medicineRepository.getMedicines()
            
            // Grouper les médicaments par rayon
            medicinesByAisle = Dictionary(grouping: allMedicines) { $0.aisleId }
            
        } catch {
            errorMessage = "Erreur lors du chargement des médicaments: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func refreshData() async {
        await loadAisles()
    }
    
    @MainActor
    func addAisle(_ aisle: Aisle) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newAisle = try await aisleRepository.saveAisle(aisle)
            aisles.append(newAisle)
            medicinesByAisle[newAisle.id] = []
            
            // Envoyer la notification
            NotificationCenter.default.post(name: Notification.Name("AisleAdded"), object: newAisle)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Erreur lors de l'ajout du rayon: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    @MainActor
    func updateAisle(_ aisle: Aisle) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedAisle = try await aisleRepository.saveAisle(aisle)
            
            if let index = aisles.firstIndex(where: { $0.id == updatedAisle.id }) {
                aisles[index] = updatedAisle
            }
            
            // Envoyer la notification
            NotificationCenter.default.post(name: Notification.Name("AisleUpdated"), object: updatedAisle)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Erreur lors de la mise à jour du rayon: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    @MainActor
    func deleteAisle(_ aisle: Aisle) async -> Bool {
        // Vérifier qu'il n'y a pas de médicaments dans ce rayon
        let medicines = medicinesByAisle[aisle.id] ?? []
        guard medicines.isEmpty else {
            errorMessage = "Impossible de supprimer un rayon contenant des médicaments"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await aisleRepository.deleteAisle(id: aisle.id)
            aisles.removeAll { $0.id == aisle.id }
            medicinesByAisle.removeValue(forKey: aisle.id)
            
            // Envoyer la notification
            NotificationCenter.default.post(name: Notification.Name("AisleDeleted"), object: aisle.id)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Erreur lors de la suppression du rayon: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Helper Methods
    func getMedicinesForAisle(_ aisleId: String) -> [Medicine] {
        return medicinesByAisle[aisleId] ?? []
    }
    
    func getMedicineCountForAisle(_ aisleId: String) -> Int {
        return medicinesByAisle[aisleId]?.count ?? 0
    }
    
    func getCriticalMedicinesForAisle(_ aisleId: String) -> [Medicine] {
        let medicines = medicinesByAisle[aisleId] ?? []
        return medicines.filter { $0.currentQuantity <= $0.criticalThreshold }
    }
    
    func getWarningMedicinesForAisle(_ aisleId: String) -> [Medicine] {
        let medicines = medicinesByAisle[aisleId] ?? []
        return medicines.filter { 
            $0.currentQuantity > $0.criticalThreshold && 
            $0.currentQuantity <= $0.warningThreshold 
        }
    }
    
    func getAisleStockStatus(_ aisleId: String) -> AisleStockStatus {
        let medicines = medicinesByAisle[aisleId] ?? []
        
        if medicines.isEmpty {
            return .normal
        }
        
        let criticalCount = medicines.filter { $0.currentQuantity <= $0.criticalThreshold }.count
        let warningCount = medicines.filter { 
            $0.currentQuantity > $0.criticalThreshold && 
            $0.currentQuantity <= $0.warningThreshold 
        }.count
        
        if criticalCount > 0 {
            return .critical
        } else if warningCount > 0 {
            return .warning
        } else {
            return .normal
        }
    }
    
    @MainActor
    func resetError() {
        errorMessage = nil
    }
}

// MARK: - Aisle Stock Status Helper
enum AisleStockStatus {
    case normal
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "xmark.octagon"
        }
    }
    
    // Convertir depuis StockStatus (du domaine)
    init(from stockStatus: StockStatus) {
        switch stockStatus {
        case .normal: self = .normal
        case .warning: self = .warning
        case .critical: self = .critical
        }
    }
}