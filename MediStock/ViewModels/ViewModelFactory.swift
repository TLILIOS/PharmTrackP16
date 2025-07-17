import SwiftUI
import Observation

// MARK: - Real UseCase implementations imported

// MARK: - Factory pour créer les ViewModels avec Environment
struct ViewModelFactory {
    
    // MARK: - Medicine ViewModels
    @MainActor static func createMedicineDetailViewModel(
        medicineId: String,
        medicineRepository: any MedicineRepositoryProtocol,
        aisleRepository: any AisleRepositoryProtocol,
        historyRepository: any HistoryRepositoryProtocol
    ) -> MedicineDetailViewModel {
        let mockMedicine = Medicine(
            id: medicineId,
            name: "Loading...",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "unit",
            currentQuantity: 0,
            maxQuantity: 100,
            warningThreshold: 10,
            criticalThreshold: 5,
            expiryDate: nil,
            aisleId: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return MedicineDetailViewModel(
            medicine: mockMedicine,
            getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: medicineRepository),
            updateMedicineStockUseCase: RealUpdateMedicineStockUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository),
            deleteMedicineUseCase: RealDeleteMedicineUseCase(medicineRepository: medicineRepository),
            getHistoryUseCase: RealGetHistoryForMedicineUseCase(historyRepository: historyRepository)
        )
    }
    
    @MainActor static func createMedicineFormViewModel(
        medicineId: String?,
        medicineRepository: any MedicineRepositoryProtocol,
        aisleRepository: any AisleRepositoryProtocol
    ) -> MedicineFormViewModel {
        return MedicineFormViewModel(
            getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: medicineRepository),
            getAislesUseCase: RealGetAislesUseCase(aisleRepository: aisleRepository),
            addMedicineUseCase: RealAddMedicineUseCase(medicineRepository: medicineRepository, historyRepository: FirebaseHistoryRepository()),
            updateMedicineUseCase: RealUpdateMedicineUseCase(medicineRepository: medicineRepository),
            medicine: nil
        )
    }
    
    @MainActor static func createAdjustStockViewModel(
        medicineId: String,
        medicineRepository: any MedicineRepositoryProtocol,
        historyRepository: any HistoryRepositoryProtocol
    ) -> AdjustStockViewModel {
        return AdjustStockViewModel(
            getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: medicineRepository),
            adjustStockUseCase: RealAdjustStockUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository),
            medicine: nil,
            medicineId: medicineId
        )
    }
    
    // MARK: - Aisle ViewModels
    @MainActor static func createAisleViewModel(
        aisleRepository: any AisleRepositoryProtocol,
        medicineRepository: any MedicineRepositoryProtocol
    ) -> AislesViewModel {
        return AislesViewModel(
            getAislesUseCase: RealGetAislesUseCase(aisleRepository: aisleRepository),
            addAisleUseCase: RealAddAisleUseCase(aisleRepository: aisleRepository),
            updateAisleUseCase: RealUpdateAisleUseCase(aisleRepository: aisleRepository),
            deleteAisleUseCase: RealDeleteAisleUseCase(aisleRepository: aisleRepository),
            getMedicineCountByAisleUseCase: RealGetMedicineCountByAisleUseCase(aisleRepository: aisleRepository)
        )
    }
}

// MARK: - Environment-aware ViewModels Creator
@Observable
final class ViewModelCreator {
    let medicineRepository: any MedicineRepositoryProtocol
    let aisleRepository: any AisleRepositoryProtocol
    let historyRepository: any HistoryRepositoryProtocol
    let authRepository: any AuthRepositoryProtocol
    
    init(
        medicineRepository: any MedicineRepositoryProtocol,
        aisleRepository: any AisleRepositoryProtocol,
        historyRepository: any HistoryRepositoryProtocol,
        authRepository: any AuthRepositoryProtocol
    ) {
        self.medicineRepository = medicineRepository
        self.aisleRepository = aisleRepository
        self.historyRepository = historyRepository
        self.authRepository = authRepository
    }
    
    @MainActor func createMedicineDetailViewModel(medicineId: String) -> MedicineDetailViewModel {
        let mockMedicine = Medicine(
            id: medicineId,
            name: "Loading...",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "unit",
            currentQuantity: 0,
            maxQuantity: 100,
            warningThreshold: 10,
            criticalThreshold: 5,
            expiryDate: nil,
            aisleId: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return MedicineDetailViewModel(
            medicine: mockMedicine,
            getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: medicineRepository),
            updateMedicineStockUseCase: RealUpdateMedicineStockUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository),
            deleteMedicineUseCase: RealDeleteMedicineUseCase(medicineRepository: medicineRepository),
            getHistoryUseCase: RealGetHistoryForMedicineUseCase(historyRepository: historyRepository)
        )
    }
    
    @MainActor func createMedicineDetailViewModel(medicine: Medicine) -> MedicineDetailViewModel {
        return MedicineDetailViewModel(
            medicine: medicine,
            getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: medicineRepository),
            updateMedicineStockUseCase: RealUpdateMedicineStockUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository),
            deleteMedicineUseCase: RealDeleteMedicineUseCase(medicineRepository: medicineRepository),
            getHistoryUseCase: RealGetHistoryForMedicineUseCase(historyRepository: historyRepository)
        )
    }
    
    @MainActor func createMedicineFormViewModel(medicineId: String?) -> MedicineFormViewModel {
        return MedicineFormViewModel(
            getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: medicineRepository),
            getAislesUseCase: RealGetAislesUseCase(aisleRepository: aisleRepository),
            addMedicineUseCase: RealAddMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository),
            updateMedicineUseCase: RealUpdateMedicineUseCase(medicineRepository: medicineRepository),
            medicine: nil
        )
    }
    
    @MainActor
    func createAdjustStockViewModel(medicineId: String, medicine: Medicine? = nil) -> AdjustStockViewModel {
        return AdjustStockViewModel(
            getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: medicineRepository),
            adjustStockUseCase: RealAdjustStockUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository),
            medicine: medicine,
            medicineId: medicineId
        )
    }
    
    @MainActor func createAisleViewModel() -> AislesViewModel {
        
        return AislesViewModel(
            getAislesUseCase: RealGetAislesUseCase(aisleRepository: aisleRepository),
            addAisleUseCase: RealAddAisleUseCase(aisleRepository: aisleRepository),
            updateAisleUseCase: RealUpdateAisleUseCase(aisleRepository: aisleRepository),
            deleteAisleUseCase: RealDeleteAisleUseCase(aisleRepository: aisleRepository),
            getMedicineCountByAisleUseCase: RealGetMedicineCountByAisleUseCase(aisleRepository: aisleRepository)
        )
    }
    
    @MainActor
    func createMedicineListViewModel() -> MedicineStockViewModel {
        return MedicineStockViewModel(
            medicineRepository: medicineRepository,
            aisleRepository: aisleRepository,
            historyRepository: historyRepository
        )
    }
}

// MARK: - Environment Key pour ViewModelCreator
struct ViewModelCreatorKey: EnvironmentKey {
    static let defaultValue = ViewModelCreator(
        medicineRepository: FirebaseMedicineRepository(),
        aisleRepository: FirebaseAisleRepository(),
        historyRepository: FirebaseHistoryRepository(),
        authRepository: FirebaseAuthRepository()
    )
}

extension EnvironmentValues {
    var viewModelCreator: ViewModelCreator {
        get { self[ViewModelCreatorKey.self] }
        set { self[ViewModelCreatorKey.self] = newValue }
    }
}

// MARK: - View Extension pour injection du creator
extension View {
    func withViewModelCreator(
        medicineRepository: any MedicineRepositoryProtocol = FirebaseMedicineRepository(),
        aisleRepository: any AisleRepositoryProtocol = FirebaseAisleRepository(),
        historyRepository: any HistoryRepositoryProtocol = FirebaseHistoryRepository(),
        authRepository: any AuthRepositoryProtocol = FirebaseAuthRepository()
    ) -> some View {
        let creator = ViewModelCreator(
            medicineRepository: medicineRepository,
            aisleRepository: aisleRepository,
            historyRepository: historyRepository,
            authRepository: authRepository
        )
        
        return self
            .environment(\.viewModelCreator, creator)
            .withRepositories(
                medicineRepository: medicineRepository,
                aisleRepository: aisleRepository,
                historyRepository: historyRepository,
                authRepository: authRepository
            )
    }
}
