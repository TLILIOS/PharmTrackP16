import Foundation

@MainActor
public class DependencyContainer {
    
    // MARK: - Repositories
    
    lazy var medicineRepository: MedicineRepositoryProtocol = {
        FirebaseMedicineRepository()
    }()
    
    lazy var aisleRepository: AisleRepositoryProtocol = {
        FirebaseAisleRepository()
    }()
    
    lazy var historyRepository: HistoryRepositoryProtocol = {
        FirebaseHistoryRepository()
    }()
    
    lazy var authRepository: AuthRepositoryProtocol = {
        FirebaseAuthRepository()
    }()
    
    // MARK: - Use Cases
    
    lazy var getMedicinesUseCase: GetMedicinesUseCaseProtocol = {
        RealGetMedicinesUseCase(medicineRepository: medicineRepository)
    }()
    
    lazy var getMedicineUseCase: GetMedicineUseCaseProtocol = {
        RealGetMedicineUseCase(medicineRepository: medicineRepository)
    }()
    
    lazy var addMedicineUseCase: AddMedicineUseCaseProtocol = {
        RealAddMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository)
    }()
    
    lazy var updateMedicineUseCase: UpdateMedicineUseCaseProtocol = {
        RealUpdateMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository)
    }()
    
    lazy var deleteMedicineUseCase: DeleteMedicineUseCaseProtocol = {
        RealDeleteMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository)
    }()
    
    lazy var updateMedicineStockUseCase: UpdateMedicineStockUseCaseProtocol = {
        RealUpdateMedicineStockUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository)
    }()
    
    lazy var searchMedicineUseCase: SearchMedicineUseCaseProtocol = {
        RealSearchMedicineUseCase(medicineRepository: medicineRepository)
    }()
    
    lazy var getAislesUseCase: GetAislesUseCaseProtocol = {
        RealGetAislesUseCase(aisleRepository: aisleRepository)
    }()
    
    lazy var addAisleUseCase: AddAisleUseCaseProtocol = {
        RealAddAisleUseCase(aisleRepository: aisleRepository)
    }()
    
    lazy var updateAisleUseCase: UpdateAisleUseCaseProtocol = {
        RealUpdateAisleUseCase(aisleRepository: aisleRepository)
    }()
    
    lazy var deleteAisleUseCase: DeleteAisleUseCaseProtocol = {
        RealDeleteAisleUseCase(aisleRepository: aisleRepository)
    }()
    
    lazy var searchAisleUseCase: SearchAisleUseCaseProtocol = {
        RealSearchAisleUseCase(aisleRepository: aisleRepository)
    }()
    
    lazy var getMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol = {
        RealGetMedicineCountByAisleUseCase(aisleRepository: aisleRepository)
    }()
    
    lazy var getUserUseCase: GetUserUseCaseProtocol = {
        RealGetUserUseCase(authRepository: authRepository)
    }()
    
    lazy var signOutUseCase: SignOutUseCaseProtocol = {
        RealSignOutUseCase(authRepository: authRepository)
    }()
    
    lazy var getHistoryUseCase: GetHistoryUseCaseProtocol = {
        RealGetHistoryUseCase(historyRepository: historyRepository)
    }()
    
    lazy var getRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol = {
        RealGetRecentHistoryUseCase(historyRepository: historyRepository)
    }()
    
    lazy var exportHistoryUseCase: ExportHistoryUseCaseProtocol = {
        RealExportHistoryUseCase(historyRepository: historyRepository)
    }()
    
    // MARK: - ViewModels Factory
    
    func makeMedicineStockViewModel() -> MedicineStockViewModel {
        MedicineStockViewModel(
            medicineRepository: medicineRepository,
            aisleRepository: aisleRepository,
            historyRepository: historyRepository
        )
    }
    
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            getUserUseCase: getUserUseCase,
            getMedicinesUseCase: getMedicinesUseCase,
            getAislesUseCase: getAislesUseCase,
            getRecentHistoryUseCase: getRecentHistoryUseCase
        )
    }
    
    func makeAislesViewModel() -> AislesViewModel {
        AislesViewModel(
            getAislesUseCase: getAislesUseCase,
            addAisleUseCase: addAisleUseCase,
            updateAisleUseCase: updateAisleUseCase,
            deleteAisleUseCase: deleteAisleUseCase,
            getMedicineCountByAisleUseCase: getMedicineCountByAisleUseCase
        )
    }
    
    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(
            getHistoryUseCase: getHistoryUseCase,
            getMedicinesUseCase: getMedicinesUseCase,
            exportHistoryUseCase: exportHistoryUseCase
        )
    }
    
    func makeProfileViewModel() -> ProfileViewModel {
        let testDataService = TestMedicineDataService(
            getAislesUseCase: getAislesUseCase,
            addMedicineUseCase: addMedicineUseCase
        )
        
        return ProfileViewModel(
            getUserUseCase: getUserUseCase,
            signOutUseCase: signOutUseCase,
            testDataService: testDataService
        )
    }
    
    func makeMedicineDetailViewModel(for medicine: Medicine) -> MedicineDetailViewModel {
        MedicineDetailViewModel(
            medicine: medicine,
            getMedicineUseCase: getMedicineUseCase,
            updateMedicineStockUseCase: updateMedicineStockUseCase,
            deleteMedicineUseCase: deleteMedicineUseCase,
            getHistoryUseCase: MockGetHistoryForMedicineUseCase() // TODO: Implement real use case
        )
    }
    
    func makeMedicineFormViewModel(for medicine: Medicine?) -> MedicineFormViewModel {
        MedicineFormViewModel(
            getMedicineUseCase: getMedicineUseCase,
            getAislesUseCase: getAislesUseCase,
            addMedicineUseCase: addMedicineUseCase,
            updateMedicineUseCase: updateMedicineUseCase,
            medicine: medicine
        )
    }
    
    func makeAppCoordinator() -> AppCoordinator {
        AppCoordinator(dependencyContainer: self)
    }
}

// MARK: - Test Dependency Container

@MainActor
public class TestDependencyContainer: DependencyContainer {
    
    override lazy var medicineRepository: MedicineRepositoryProtocol = {
        MockMedicineRepository()
    }()
    
    override lazy var aisleRepository: AisleRepositoryProtocol = {
        MockAisleRepository()
    }()
    
    override lazy var historyRepository: HistoryRepositoryProtocol = {
        MockHistoryRepository()
    }()
    
    override lazy var authRepository: AuthRepositoryProtocol = {
        MockAuthRepository()
    }()
}