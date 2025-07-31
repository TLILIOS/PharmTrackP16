import Foundation

// MARK: - Dependency Container

@MainActor
class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    // Services
    lazy var dataService = DataService()
    lazy var authService = AuthService()
    lazy var notificationService = NotificationService()
    
    // Repositories
    lazy var medicineRepository: MedicineRepositoryProtocol = MedicineRepository(dataService: dataService)
    lazy var aisleRepository: AisleRepositoryProtocol = AisleRepository(dataService: dataService)
    lazy var historyRepository: HistoryRepositoryProtocol = HistoryRepository(dataService: dataService)
    
    private var _authRepository: AuthRepositoryProtocol?
    var authRepository: AuthRepositoryProtocol {
        if _authRepository == nil {
            _authRepository = AuthRepository(authService: authService)
        }
        return _authRepository!
    }
    
    // ViewModels
    @MainActor
    func makeMedicineListViewModel() -> MedicineListViewModel {
        MedicineListViewModel(
            repository: medicineRepository,
            historyRepository: historyRepository,
            notificationService: notificationService
        )
    }
    
    @MainActor
    func makeAisleListViewModel() -> AisleListViewModel {
        AisleListViewModel(repository: aisleRepository)
    }
    
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(repository: authRepository)
    }
    
    @MainActor
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            medicineRepository: medicineRepository,
            aisleRepository: aisleRepository,
            notificationService: notificationService
        )
    }
    
    @MainActor
    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(repository: historyRepository)
    }
}