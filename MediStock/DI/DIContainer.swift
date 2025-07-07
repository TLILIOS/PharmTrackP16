import Foundation

class DIContainer {
    static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - Authentication Use Cases
    
    lazy var getUserUseCase: GetUserUseCaseProtocol = MockGetUserUseCase()
    lazy var signInUseCase: SignInUseCaseProtocol = MockSignInUseCase()
    lazy var signUpUseCase: SignUpUseCaseProtocol = MockSignUpUseCase()
    lazy var signOutUseCase: SignOutUseCaseProtocol = MockSignOutUseCase()
    
    // MARK: - Medicine Use Cases
    
    lazy var getMedicinesUseCase: GetMedicinesUseCaseProtocol = MockGetMedicinesUseCase()
    lazy var getMedicineUseCase: GetMedicineUseCaseProtocol = MockGetMedicineUseCase()
    lazy var addMedicineUseCase: AddMedicineUseCaseProtocol = MockAddMedicineUseCase()
    lazy var updateMedicineUseCase: UpdateMedicineUseCaseProtocol = MockUpdateMedicineUseCase()
    lazy var deleteMedicineUseCase: DeleteMedicineUseCaseProtocol = MockDeleteMedicineUseCase()
    lazy var adjustStockUseCase: AdjustStockUseCaseProtocol = MockAdjustStockUseCase()
    lazy var searchMedicineUseCase: SearchMedicineUseCaseProtocol = MockSearchMedicineUseCase()
    
    // MARK: - Aisle Use Cases
    
    lazy var getAislesUseCase: GetAislesUseCaseProtocol = MockGetAislesUseCase()
    lazy var addAisleUseCase: AddAisleUseCaseProtocol = MockAddAisleUseCase()
    lazy var updateAisleUseCase: UpdateAisleUseCaseProtocol = MockUpdateAisleUseCase()
    lazy var deleteAisleUseCase: DeleteAisleUseCaseProtocol = MockDeleteAisleUseCase()
    lazy var searchAisleUseCase: SearchAisleUseCaseProtocol = MockSearchAisleUseCase()
    lazy var getMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol = MockGetMedicineCountByAisleUseCase()
    
    // MARK: - History Use Cases
    
    lazy var getHistoryUseCase: GetHistoryUseCaseProtocol = MockGetHistoryUseCase()
    lazy var getRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol = MockGetRecentHistoryUseCase()
    lazy var exportHistoryUseCase: ExportHistoryUseCaseProtocol = MockExportHistoryUseCase()
    
    // MARK: - App Coordinator
    
    lazy var appCoordinator: AppCoordinator = {
        AppCoordinator(
            // Auth
            getUserUseCase: getUserUseCase,
            signOutUseCase: signOutUseCase,
            
            // Medicines
            getMedicinesUseCase: getMedicinesUseCase,
            getMedicineUseCase: getMedicineUseCase,
            addMedicineUseCase: addMedicineUseCase,
            updateMedicineUseCase: updateMedicineUseCase,
            deleteMedicineUseCase: deleteMedicineUseCase,
            adjustStockUseCase: adjustStockUseCase,
            searchMedicineUseCase: searchMedicineUseCase,
            
            // Aisles
            getAislesUseCase: getAislesUseCase,
            addAisleUseCase: addAisleUseCase,
            updateAisleUseCase: updateAisleUseCase,
            deleteAisleUseCase: deleteAisleUseCase,
            searchAisleUseCase: searchAisleUseCase,
            getMedicineCountByAisleUseCase: getMedicineCountByAisleUseCase,
            
            // History
            getHistoryUseCase: getHistoryUseCase,
            getRecentHistoryUseCase: getRecentHistoryUseCase,
            exportHistoryUseCase: exportHistoryUseCase
        )
    }()
}