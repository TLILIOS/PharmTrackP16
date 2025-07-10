import Foundation
@testable import MediStock

// MARK: - Test Dependency Container pour les tests

@MainActor
public class TestDependencyContainer {
    
    // MARK: - Repositories
    
    public lazy var medicineRepository: MedicineRepositoryProtocol = {
        MockMedicineRepository()
    }()
    
    public lazy var aisleRepository: AisleRepositoryProtocol = {
        MockAisleRepository()
    }()
    
    public lazy var historyRepository: HistoryRepositoryProtocol = {
        MockHistoryRepository()
    }()
    
    public lazy var authRepository: AuthRepositoryProtocol = {
        MockAuthRepository()
    }()
    
    // MARK: - Use Cases
    
    public lazy var getMedicinesUseCase: GetMedicinesUseCaseProtocol = {
        MockGetMedicinesUseCase()
    }()
    
    public lazy var getMedicineUseCase: GetMedicineUseCaseProtocol = {
        MockGetMedicineUseCase()
    }()
    
    public lazy var addMedicineUseCase: AddMedicineUseCaseProtocol = {
        MockAddMedicineUseCase()
    }()
    
    public lazy var updateMedicineUseCase: UpdateMedicineUseCaseProtocol = {
        MockUpdateMedicineUseCase()
    }()
    
    public lazy var deleteMedicineUseCase: DeleteMedicineUseCaseProtocol = {
        MockDeleteMedicineUseCase()
    }()
    
    public lazy var updateMedicineStockUseCase: UpdateMedicineStockUseCaseProtocol = {
        MockUpdateMedicineStockUseCase()
    }()
    
    public lazy var searchMedicineUseCase: SearchMedicineUseCaseProtocol = {
        MockSearchMedicineUseCase()
    }()
    
    public lazy var getAislesUseCase: GetAislesUseCaseProtocol = {
        MockGetAislesUseCase()
    }()
    
    public lazy var addAisleUseCase: AddAisleUseCaseProtocol = {
        MockAddAisleUseCase()
    }()
    
    public lazy var updateAisleUseCase: UpdateAisleUseCaseProtocol = {
        MockUpdateAisleUseCase()
    }()
    
    public lazy var deleteAisleUseCase: DeleteAisleUseCaseProtocol = {
        MockDeleteAisleUseCase()
    }()
    
    public lazy var searchAisleUseCase: SearchAisleUseCaseProtocol = {
        MockSearchAisleUseCase()
    }()
    
    public lazy var getMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol = {
        MockGetMedicineCountByAisleUseCase()
    }()
    
    public lazy var getUserUseCase: GetUserUseCaseProtocol = {
        MockGetUserUseCase()
    }()
    
    public lazy var signOutUseCase: SignOutUseCaseProtocol = {
        MockSignOutUseCase()
    }()
    
    public lazy var getHistoryUseCase: GetHistoryUseCaseProtocol = {
        MockGetHistoryUseCase()
    }()
    
    public lazy var getRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol = {
        MockGetRecentHistoryUseCase()
    }()
    
    public lazy var exportHistoryUseCase: ExportHistoryUseCaseProtocol = {
        MockExportHistoryUseCase()
    }()
    
    public lazy var getHistoryForMedicineUseCase: GetHistoryForMedicineUseCaseProtocol = {
        MockGetHistoryForMedicineUseCase()
    }()
    
    public lazy var adjustStockUseCase: AdjustStockUseCaseProtocol = {
        MockAdjustStockUseCase()
    }()
    
    public init() {}
}