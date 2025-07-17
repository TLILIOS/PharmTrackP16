import SwiftUI

// MARK: - Environment Keys pour l'injection de dépendances

struct MedicineRepositoryKey: EnvironmentKey {
    static let defaultValue: any MedicineRepositoryProtocol = FirebaseMedicineRepository()
}

struct AisleRepositoryKey: EnvironmentKey {
    static let defaultValue: any AisleRepositoryProtocol = FirebaseAisleRepository()
}

struct HistoryRepositoryKey: EnvironmentKey {
    static let defaultValue: any HistoryRepositoryProtocol = FirebaseHistoryRepository()
}

struct AuthRepositoryKey: EnvironmentKey {
    static let defaultValue: any AuthRepositoryProtocol = FirebaseAuthRepository()
}

// MARK: - Extensions EnvironmentValues

extension EnvironmentValues {
    var medicineRepository: any MedicineRepositoryProtocol {
        get { self[MedicineRepositoryKey.self] }
        set { self[MedicineRepositoryKey.self] = newValue }
    }
    
    var aisleRepository: any AisleRepositoryProtocol {
        get { self[AisleRepositoryKey.self] }
        set { self[AisleRepositoryKey.self] = newValue }
    }
    
    var historyRepository: any HistoryRepositoryProtocol {
        get { self[HistoryRepositoryKey.self] }
        set { self[HistoryRepositoryKey.self] = newValue }
    }
    
    var authRepository: any AuthRepositoryProtocol {
        get { self[AuthRepositoryKey.self] }
        set { self[AuthRepositoryKey.self] = newValue }
    }
}

// MARK: - View Extensions pour faciliter l'injection

extension View {
    func withRepositories(
        medicineRepository: any MedicineRepositoryProtocol = FirebaseMedicineRepository(),
        aisleRepository: any AisleRepositoryProtocol = FirebaseAisleRepository(),
        historyRepository: any HistoryRepositoryProtocol = FirebaseHistoryRepository(),
        authRepository: any AuthRepositoryProtocol = FirebaseAuthRepository()
    ) -> some View {
        let viewModelCreator = ViewModelCreator(
            medicineRepository: medicineRepository,
            aisleRepository: aisleRepository,
            historyRepository: historyRepository,
            authRepository: authRepository
        )
        
        return self
            .environment(\.medicineRepository, medicineRepository)
            .environment(\.aisleRepository, aisleRepository)
            .environment(\.historyRepository, historyRepository)
            .environment(\.authRepository, authRepository)
            .environment(\.viewModelCreator, viewModelCreator)
    }
}