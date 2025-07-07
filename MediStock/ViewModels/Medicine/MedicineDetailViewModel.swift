import Foundation
import Combine

enum MedicineDetailViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class MedicineDetailViewModel: ObservableObject {
    // MARK: - Properties
    
    private let getMedicineUseCase: GetMedicineUseCaseProtocol
    private let updateMedicineStockUseCase: UpdateMedicineStockUseCaseProtocol
    private let deleteMedicineUseCase: DeleteMedicineUseCaseProtocol
    private let getHistoryUseCase: GetHistoryForMedicineUseCaseProtocol
    
    @Published private(set) var medicine: Medicine
    @Published private(set) var history: [HistoryEntry] = []
    @Published private(set) var state: MedicineDetailViewState = .idle
    @Published private(set) var isLoadingHistory: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var aisleName: String? {
        // Dans une implémentation réelle, on récupérerait le nom du rayon à partir de l'ID
        return nil
    }
    
    // MARK: - Initialization
    
    init(
        medicine: Medicine,
        getMedicineUseCase: GetMedicineUseCaseProtocol,
        updateMedicineStockUseCase: UpdateMedicineStockUseCaseProtocol,
        deleteMedicineUseCase: DeleteMedicineUseCaseProtocol,
        getHistoryUseCase: GetHistoryForMedicineUseCaseProtocol
    ) {
        self.medicine = medicine
        self.getMedicineUseCase = getMedicineUseCase
        self.updateMedicineStockUseCase = updateMedicineStockUseCase
        self.deleteMedicineUseCase = deleteMedicineUseCase
        self.getHistoryUseCase = getHistoryUseCase
    }
    
    // MARK: - Public Methods
    
    func resetState() {
        state = .idle
    }
    
    @MainActor
    func refreshMedicine() async {
        state = .loading
        
        do {
            let updatedMedicine = try await getMedicineUseCase.execute(id: medicine.id)
                self.medicine = updatedMedicine
                state = .success
        } catch {
            state = .error("Erreur lors du chargement: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func updateStock(newQuantity: Int, comment: String) async {
        state = .loading
        
        do {
            let updatedMedicine = try await updateMedicineStockUseCase.execute(
                medicineId: medicine.id, 
                newQuantity: newQuantity,
                comment: comment
            )
            
            self.medicine = updatedMedicine
            state = .success
            
            // Rafraîchir l'historique
            await fetchHistory()
        } catch {
            state = .error("Erreur lors de la mise à jour du stock: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func deleteMedicine() async {
        state = .loading
        
        do {
            try await deleteMedicineUseCase.execute(id: medicine.id)
            state = .success
        } catch {
            state = .error("Erreur lors de la suppression: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func fetchHistory() async {
        isLoadingHistory = true
        
        do {
            history = try await getHistoryUseCase.execute(medicineId: medicine.id)
        } catch {
            // On ne change pas l'état principal pour une erreur d'historique
            // mais on pourrait ajouter un état spécifique à l'historique si nécessaire
            history = []
        }
        
        isLoadingHistory = false
    }
}

