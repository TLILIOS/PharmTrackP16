import SwiftUI
import Observation

@Observable
final class ObservableMedicineFormViewModel {
    // MARK: - Published Properties
    var medicine: Medicine?
    var aisles: [Aisle] = []
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    private let medicineId: String?
    private let medicineRepository: any MedicineRepositoryProtocol
    private let aisleRepository: any AisleRepositoryProtocol
    
    // MARK: - Computed Properties
    var isEditing: Bool {
        medicineId != nil
    }
    
    // MARK: - Initializer
    init(
        medicineId: String?,
        medicineRepository: any MedicineRepositoryProtocol,
        aisleRepository: any AisleRepositoryProtocol
    ) {
        self.medicineId = medicineId
        self.medicineRepository = medicineRepository
        self.aisleRepository = aisleRepository
        
        Task {
            await fetchAisles()
            if let medicineId = medicineId {
                await loadMedicine(id: medicineId)
            }
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
    func fetchAisles() async {
        do {
            aisles = try await aisleRepository.getAisles()
        } catch {
            errorMessage = "Erreur lors du chargement des rayons: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func saveMedicine(_ medicine: Medicine) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await medicineRepository.saveMedicine(medicine)
            
            // Envoyer la notification appropriée
            if isEditing {
                NotificationCenter.default.post(name: Notification.Name("MedicineUpdated"), object: medicine)
            } else {
                NotificationCenter.default.post(name: Notification.Name("MedicineAdded"), object: medicine)
            }
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    @MainActor
    func addMedicine(_ medicine: Medicine) async {
        _ = await saveMedicine(medicine)
    }
    
    @MainActor
    func updateMedicine(_ medicine: Medicine) async {
        _ = await saveMedicine(medicine)
    }
    
    @MainActor
    func resetError() {
        errorMessage = nil
    }
}
