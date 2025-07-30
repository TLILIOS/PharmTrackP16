import Foundation
import SwiftUI

// MARK: - Dashboard ViewModel

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var aisles: [Aisle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let medicineRepository: MedicineRepositoryProtocol
    private let aisleRepository: AisleRepositoryProtocol
    private let notificationService: NotificationService
    
    init(
        medicineRepository: MedicineRepositoryProtocol = MedicineRepository(),
        aisleRepository: AisleRepositoryProtocol = AisleRepository(),
        notificationService: NotificationService = NotificationService()
    ) {
        self.medicineRepository = medicineRepository
        self.aisleRepository = aisleRepository
        self.notificationService = notificationService
    }
    
    var criticalMedicines: [Medicine] {
        medicines.filter { $0.stockStatus == .critical }
    }
    
    var expiringMedicines: [Medicine] {
        medicines.filter { $0.isExpiringSoon && !$0.isExpired }
    }
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let medicinesTask = medicineRepository.fetchMedicines()
            async let aislesTask = aisleRepository.fetchAisles()
            
            let (meds, aisls) = try await (medicinesTask, aislesTask)
            medicines = meds
            aisles = aisls
            
            // Vérifier les notifications d'expiration
            await notificationService.checkExpirations(medicines: medicines)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
}