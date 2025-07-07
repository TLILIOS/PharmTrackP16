import Foundation
import Combine

@MainActor
class AdjustStockViewModel: ObservableObject {
    @Published var medicine: Medicine
    @Published var adjustmentQuantity: Int = 0
    @Published var adjustmentReason: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage: Bool = false
    
    private let getMedicineUseCase: GetMedicineUseCaseProtocol
    private let adjustStockUseCase: AdjustStockUseCaseProtocol
    
    init(
        getMedicineUseCase: GetMedicineUseCaseProtocol,
        adjustStockUseCase: AdjustStockUseCaseProtocol,
        medicine: Medicine
    ) {
        self.getMedicineUseCase = getMedicineUseCase
        self.adjustStockUseCase = adjustStockUseCase
        self.medicine = medicine
    }
    
    func adjustStock() async {
        guard adjustmentQuantity != 0 else {
            errorMessage = "La quantité d'ajustement ne peut pas être zéro"
            return
        }
        
        guard !adjustmentReason.isEmpty else {
            errorMessage = "Veuillez saisir une raison pour l'ajustement"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await adjustStockUseCase.execute(
                medicineId: medicine.id,
                adjustment: adjustmentQuantity,
                reason: adjustmentReason
            )
            
            // Refresh medicine data
            medicine = try await getMedicineUseCase.execute(id: medicine.id)
            
            showingSuccessMessage = true
            adjustmentQuantity = 0
            adjustmentReason = ""
        } catch {
            errorMessage = "Erreur lors de l'ajustement du stock: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func dismissSuccessMessage() {
        showingSuccessMessage = false
    }
    
    func dismissErrorMessage() {
        errorMessage = nil
    }
}