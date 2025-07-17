import Foundation
import Combine

@MainActor
class AdjustStockViewModel: ObservableObject {
    @Published var medicine: Medicine?
    @Published var adjustmentQuantity: Int = 0
    @Published var adjustmentReason: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage: Bool = false
    @Published var state: LoadingState = .idle
    
    enum LoadingState: Equatable {
        case idle
        case loading
        case success
        case error(String)
    }
    
    private let getMedicineUseCase: GetMedicineUseCaseProtocol
    private let adjustStockUseCase: any AdjustStockUseCaseProtocol
    private let medicineId: String
    
    init(
        getMedicineUseCase: GetMedicineUseCaseProtocol,
        adjustStockUseCase: any AdjustStockUseCaseProtocol,
        medicine: Medicine? = nil,
        medicineId: String
    ) {
        self.getMedicineUseCase = getMedicineUseCase
        self.adjustStockUseCase = adjustStockUseCase
        self.medicine = medicine
        self.medicineId = medicineId
    }
    
    func adjustStock(newQuantity: Int, reason: String) async {
        guard let medicine = medicine else {
            state = .error("Médicament non trouvé")
            return
        }
        
        state = .loading
        isLoading = true
        
        do {
            let adjustment = newQuantity - medicine.currentQuantity
            try await adjustStockUseCase.execute(
                medicineId: medicine.id,
                adjustment: adjustment,
                reason: reason
            )
            
            // Refresh medicine data
            self.medicine = try await getMedicineUseCase.execute(id: medicine.id)
            
            state = .success
            showingSuccessMessage = true
            
            // Post notification to update other views
            NotificationCenter.default.post(name: Notification.Name("StockAdjusted"), object: nil)
            NotificationCenter.default.post(name: Notification.Name("MedicineUpdated"), object: nil)
        } catch {
            state = .error("Erreur lors de l'ajustement du stock: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func loadMedicine() async {
        state = .loading
        isLoading = true
        
        do {
            // Si on a déjà le medicine, on le garde, sinon on le charge depuis l'ID
            if medicine == nil {
                self.medicine = try await getMedicineUseCase.execute(id: medicineId)
            }
            state = .idle
        } catch {
            state = .error("Erreur lors du chargement du médicament: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func resetState() {
        state = .idle
        errorMessage = nil
    }
    
    func dismissSuccessMessage() {
        showingSuccessMessage = false
    }
    
    func dismissErrorMessage() {
        errorMessage = nil
    }
}