import SwiftUI

// MARK: - Navigation Destinations for each Tab

enum DashboardDestination: Hashable {
    case criticalStock
    case expiringMedicines
    case medicineDetail(String)
    case adjustStock(String)
    case medicineForm(String?)
}

enum MedicineDestination: Hashable {
    case medicineDetail(String)
    case medicineForm(String?)
    case adjustStock(String)
}

enum AisleDestination: Hashable {
    case aisleDetail(String)
    case medicinesByAisle(String)
    case aisleForm(String?)
    case medicineDetail(String)
}

enum HistoryDestination: Hashable {
    case historyDetail(String)
    case medicineDetail(String)
}

enum ProfileDestination: Hashable {
    case settings
    case about
}

// MARK: - Extensions with View Property

extension DashboardDestination {
    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
        case .criticalStock:
            // Utilise le vrai DashboardViewModel depuis l'environnement
            CriticalStockView(dashboardViewModel: DashboardViewModel(
                getUserUseCase: RealGetUserUseCase(authRepository: FirebaseAuthRepository()),
                getMedicinesUseCase: RealGetMedicinesUseCase(medicineRepository: FirebaseMedicineRepository()),
                getAislesUseCase: RealGetAislesUseCase(aisleRepository: FirebaseAisleRepository()),
                getRecentHistoryUseCase: RealGetRecentHistoryUseCase(historyRepository: FirebaseHistoryRepository())
            ))
        case .expiringMedicines:
            ExpiringMedicinesView(dashboardViewModel: DashboardViewModel(
                getUserUseCase: RealGetUserUseCase(authRepository: FirebaseAuthRepository()),
                getMedicinesUseCase: RealGetMedicinesUseCase(medicineRepository: FirebaseMedicineRepository()),
                getAislesUseCase: RealGetAislesUseCase(aisleRepository: FirebaseAisleRepository()),
                getRecentHistoryUseCase: RealGetRecentHistoryUseCase(historyRepository: FirebaseHistoryRepository())
            ))
        case .medicineDetail(let id):
            MedicineDetailView(
                medicineId: id,
                viewModel: MedicineDetailViewModel(
                    medicine: Medicine(
                        id: id,
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
                    ),
                    getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    updateMedicineStockUseCase: RealUpdateMedicineStockUseCase(
                        medicineRepository: FirebaseMedicineRepository(),
                        historyRepository: FirebaseHistoryRepository()
                    ),
                    deleteMedicineUseCase: RealDeleteMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    getHistoryUseCase: RealGetHistoryForMedicineUseCase(historyRepository: FirebaseHistoryRepository())
                )
            )
        case .adjustStock(let id):
            AdjustStockView(
                medicineId: id,
                viewModel: AdjustStockViewModel(
                    getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    adjustStockUseCase: RealAdjustStockUseCase(
                        medicineRepository: FirebaseMedicineRepository(),
                        historyRepository: FirebaseHistoryRepository()
                    ),
                    medicine: nil,
                    medicineId: id
                )
            )
        case .medicineForm(let id):
            MedicineFormView(
                medicineId: id,
                viewModel: MedicineFormViewModel(
                    getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    getAislesUseCase: RealGetAislesUseCase(aisleRepository: FirebaseAisleRepository()),
                    addMedicineUseCase: RealAddMedicineUseCase(
                        medicineRepository: FirebaseMedicineRepository(),
                        historyRepository: FirebaseHistoryRepository()
                    ),
                    updateMedicineUseCase: RealUpdateMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    medicine: nil
                )
            )
        }
    }
}

extension MedicineDestination {
    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
        case .medicineDetail(let id):
            MedicineDetailView(
                medicineId: id,
                viewModel: MedicineDetailViewModel(
                    medicine: Medicine(
                        id: id,
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
                    ),
                    getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    updateMedicineStockUseCase: RealUpdateMedicineStockUseCase(
                        medicineRepository: FirebaseMedicineRepository(),
                        historyRepository: FirebaseHistoryRepository()
                    ),
                    deleteMedicineUseCase: RealDeleteMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    getHistoryUseCase: RealGetHistoryForMedicineUseCase(historyRepository: FirebaseHistoryRepository())
                )
            )
        case .medicineForm(let id):
            MedicineFormView(
                medicineId: id,
                viewModel: MedicineFormViewModel(
                    getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    getAislesUseCase: RealGetAislesUseCase(aisleRepository: FirebaseAisleRepository()),
                    addMedicineUseCase: RealAddMedicineUseCase(
                        medicineRepository: FirebaseMedicineRepository(),
                        historyRepository: FirebaseHistoryRepository()
                    ),
                    updateMedicineUseCase: RealUpdateMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    medicine: nil
                )
            )
        case .adjustStock(let id):
            AdjustStockView(
                medicineId: id,
                viewModel: AdjustStockViewModel(
                    getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    adjustStockUseCase: RealAdjustStockUseCase(
                        medicineRepository: FirebaseMedicineRepository(),
                        historyRepository: FirebaseHistoryRepository()
                    ),
                    medicine: nil,
                    medicineId: id
                )
            )
        }
    }
}

extension AisleDestination {
    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
        case .aisleDetail(let id):
            Text("Détail du rayon: \(id)")
        case .medicinesByAisle(let id):
            MedicinesByAisleView(aisleId: id)
        case .aisleForm(let id):
            AisleFormView(viewModel: AislesViewModel(
                getAislesUseCase: RealGetAislesUseCase(aisleRepository: FirebaseAisleRepository()),
                addAisleUseCase: RealAddAisleUseCase(aisleRepository: FirebaseAisleRepository()),
                updateAisleUseCase: RealUpdateAisleUseCase(aisleRepository: FirebaseAisleRepository()),
                deleteAisleUseCase: RealDeleteAisleUseCase(aisleRepository: FirebaseAisleRepository()),
                getMedicineCountByAisleUseCase: RealGetMedicineCountByAisleUseCase(aisleRepository: FirebaseAisleRepository())
            ), editingAisle: nil)
        case .medicineDetail(let id):
            MedicineDetailView(
                medicineId: id,
                viewModel: MedicineDetailViewModel(
                    medicine: Medicine(
                        id: id,
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
                    ),
                    getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    updateMedicineStockUseCase: RealUpdateMedicineStockUseCase(
                        medicineRepository: FirebaseMedicineRepository(),
                        historyRepository: FirebaseHistoryRepository()
                    ),
                    deleteMedicineUseCase: RealDeleteMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    getHistoryUseCase: RealGetHistoryForMedicineUseCase(historyRepository: FirebaseHistoryRepository())
                )
            )
        }
    }
}

extension HistoryDestination {
    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
        case .historyDetail(let id):
            Text("Détail de l'historique: \(id)")
        case .medicineDetail(let id):
            MedicineDetailView(
                medicineId: id,
                viewModel: MedicineDetailViewModel(
                    medicine: Medicine(
                        id: id,
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
                    ),
                    getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    updateMedicineStockUseCase: RealUpdateMedicineStockUseCase(
                        medicineRepository: FirebaseMedicineRepository(),
                        historyRepository: FirebaseHistoryRepository()
                    ),
                    deleteMedicineUseCase: RealDeleteMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    getHistoryUseCase: RealGetHistoryForMedicineUseCase(historyRepository: FirebaseHistoryRepository())
                )
            )
        }
    }
}

extension ProfileDestination {
    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
        case .settings:
            AppearanceSettingsView()
        case .about:
            Text("À propos de MediStock")
        }
    }
}