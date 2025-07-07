import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import Combine

// MARK: - Use Case Protocols

// Authentication Use Cases
protocol GetUserUseCaseProtocol {
    func execute() async throws -> User
}

protocol SignInUseCaseProtocol {
    func execute(email: String, password: String) async throws
}

protocol SignUpUseCaseProtocol {
    func execute(email: String, password: String, name: String) async throws
}

protocol SignOutUseCaseProtocol {
    func execute() async throws
}

// Medicine Use Cases
protocol GetMedicinesUseCaseProtocol {
    func execute() async throws -> [Medicine]
}

protocol GetMedicineUseCaseProtocol {
    func execute(id: String) async throws -> Medicine
}

protocol AddMedicineUseCaseProtocol {
    func execute(medicine: Medicine) async throws
}

protocol UpdateMedicineUseCaseProtocol {
    func execute(medicine: Medicine) async throws
}

protocol DeleteMedicineUseCaseProtocol {
    func execute(id: String) async throws
}

protocol AdjustStockUseCaseProtocol {
    func execute(medicineId: String, adjustment: Int, reason: String) async throws
}

protocol SearchMedicineUseCaseProtocol {
    func execute(query: String) async throws -> [Medicine]
}

protocol GetHistoryForMedicineUseCaseProtocol {
    func execute(medicineId: String) async throws -> [HistoryEntry]
}

protocol UpdateMedicineStockUseCaseProtocol {
    func execute(medicineId: String, newQuantity: Int, comment: String) async throws -> Medicine
}

// Aisle Use Cases
protocol GetAislesUseCaseProtocol {
    func execute() async throws -> [Aisle]
}

protocol AddAisleUseCaseProtocol {
    func execute(aisle: Aisle) async throws
}

protocol UpdateAisleUseCaseProtocol {
    func execute(aisle: Aisle) async throws
}

protocol DeleteAisleUseCaseProtocol {
    func execute(id: String) async throws
}

protocol SearchAisleUseCaseProtocol {
    func execute(query: String) async throws -> [Aisle]
}

protocol GetMedicineCountByAisleUseCaseProtocol {
    func execute(aisleId: String) async throws -> Int
}

// MARK: - Repository Protocols
protocol AisleRepositoryProtocol {
    func getAisles() async throws -> [Aisle]
    func getAisle(id: String) async throws -> Aisle?
    func saveAisle(_ aisle: Aisle) async throws -> Aisle
    func deleteAisle(id: String) async throws
    func getMedicineCountByAisle(aisleId: String) async throws -> Int
    func observeAisles() -> AnyPublisher<[Aisle], Error>
    func observeAisle(id: String) -> AnyPublisher<Aisle?, Error>
}

// History Use Cases
protocol GetHistoryUseCaseProtocol {
    func execute() async throws -> [HistoryEntry]
}

protocol GetRecentHistoryUseCaseProtocol {
    func execute(limit: Int) async throws -> [HistoryEntry]
}

protocol ExportHistoryUseCaseProtocol {
    func execute(format: ExportFormat) async throws -> Data
}

enum ExportFormat {
    case csv
    case json
    case pdf
}

/// Énumération des destinations de navigation possibles
enum NavigationDestination: Hashable {
    case medicineDetail(Medicine)
    case medicineForm(Medicine?)
    case adjustStock(Medicine)
    case aisle(Aisle?)
    case criticalStock
    case expiringMedicines
    case history
    case settings
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .medicineDetail(let medicine):
            hasher.combine("medicineDetail")
            hasher.combine(medicine.id)
        case .medicineForm(let medicine):
            hasher.combine("medicineForm")
            hasher.combine(medicine?.id ?? "new")
        case .adjustStock(let medicine):
            hasher.combine("adjustStock")
            hasher.combine(medicine.id)
        case .aisle(let aisle):
            hasher.combine("aisle")
            hasher.combine(aisle?.id ?? "new")
        case .criticalStock:
            hasher.combine("criticalStock")
        case .expiringMedicines:
            hasher.combine("expiringMedicines")
        case .history:
            hasher.combine("history")
        case .settings:
            hasher.combine("settings")
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.medicineDetail(let lhsMedicine), .medicineDetail(let rhsMedicine)):
            return lhsMedicine.id == rhsMedicine.id
        case (.medicineForm(let lhsMedicine), .medicineForm(let rhsMedicine)):
            return lhsMedicine?.id == rhsMedicine?.id
        case (.adjustStock(let lhsMedicine), .adjustStock(let rhsMedicine)):
            return lhsMedicine.id == rhsMedicine.id
        case (.aisle(let lhsAisle), .aisle(let rhsAisle)):
            return lhsAisle?.id == rhsAisle?.id
        case (.criticalStock, .criticalStock),
             (.expiringMedicines, .expiringMedicines),
             (.history, .history),
             (.settings, .settings):
            return true
        default:
            return false
        }
    }
}

/// Classe coordinateur qui gère la navigation et l'injection de dépendances
@MainActor
class AppCoordinator: ObservableObject {
    // MARK: - Navigation Paths
    
    @Published var dashboardNavigationPath: [NavigationDestination] = []
    @Published var medicineNavigationPath: [NavigationDestination] = []
    @Published var aislesNavigationPath: [NavigationDestination] = []
    @Published var historyNavigationPath: [NavigationDestination] = []
    @Published var profileNavigationPath: [NavigationDestination] = []
    
    @Published var globalErrorMessage: String?
    
    // MARK: - Use Cases
    
    // Auth
    private let getUserUseCase: GetUserUseCaseProtocol
    private let signOutUseCase: SignOutUseCaseProtocol
    
    // Medicines
    private let getMedicinesUseCase: GetMedicinesUseCaseProtocol
    private let getMedicineUseCase: GetMedicineUseCaseProtocol
    private let addMedicineUseCase: AddMedicineUseCaseProtocol
    private let updateMedicineUseCase: UpdateMedicineUseCaseProtocol
    private let deleteMedicineUseCase: DeleteMedicineUseCaseProtocol
    private let adjustStockUseCase: AdjustStockUseCaseProtocol
    private let searchMedicineUseCase: SearchMedicineUseCaseProtocol
    
    // Aisles
    private let getAislesUseCase: GetAislesUseCaseProtocol
    private let addAisleUseCase: AddAisleUseCaseProtocol
    private let updateAisleUseCase: UpdateAisleUseCaseProtocol
    private let deleteAisleUseCase: DeleteAisleUseCaseProtocol
    private let searchAisleUseCase: SearchAisleUseCaseProtocol
    private let getMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol
    
    // History
    private let getHistoryUseCase: GetHistoryUseCaseProtocol
    private let getRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol
    private let exportHistoryUseCase: ExportHistoryUseCaseProtocol
    
    // MARK: - ViewModels
    
    // Ces propriétés sont accédées directement par la MainTabView
    let dashboardViewModel: DashboardViewModel
    let medicineListViewModel: MedicineStockViewModel
    let aislesViewModel: AislesViewModel
    let historyViewModel: HistoryViewModel
    let profileViewModel: ProfileViewModel
    
    // MARK: - Initialization
    
    init(
        // Auth
        getUserUseCase: GetUserUseCaseProtocol,
        signOutUseCase: SignOutUseCaseProtocol,
        
        // Medicines
        getMedicinesUseCase: GetMedicinesUseCaseProtocol,
        getMedicineUseCase: GetMedicineUseCaseProtocol,
        addMedicineUseCase: AddMedicineUseCaseProtocol,
        updateMedicineUseCase: UpdateMedicineUseCaseProtocol,
        deleteMedicineUseCase: DeleteMedicineUseCaseProtocol,
        adjustStockUseCase: AdjustStockUseCaseProtocol,
        searchMedicineUseCase: SearchMedicineUseCaseProtocol,
        
        // Aisles
        getAislesUseCase: GetAislesUseCaseProtocol,
        addAisleUseCase: AddAisleUseCaseProtocol,
        updateAisleUseCase: UpdateAisleUseCaseProtocol,
        deleteAisleUseCase: DeleteAisleUseCaseProtocol,
        searchAisleUseCase: SearchAisleUseCaseProtocol,
        getMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol,
        
        // History
        getHistoryUseCase: GetHistoryUseCaseProtocol,
        getRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol,
        exportHistoryUseCase: ExportHistoryUseCaseProtocol
    ) {
        // Auth
        self.getUserUseCase = getUserUseCase
        self.signOutUseCase = signOutUseCase
        
        // Medicines
        self.getMedicinesUseCase = getMedicinesUseCase
        self.getMedicineUseCase = getMedicineUseCase
        self.addMedicineUseCase = addMedicineUseCase
        self.updateMedicineUseCase = updateMedicineUseCase
        self.deleteMedicineUseCase = deleteMedicineUseCase
        self.adjustStockUseCase = adjustStockUseCase
        self.searchMedicineUseCase = searchMedicineUseCase
        
        // Aisles
        self.getAislesUseCase = getAislesUseCase
        self.addAisleUseCase = addAisleUseCase
        self.updateAisleUseCase = updateAisleUseCase
        self.deleteAisleUseCase = deleteAisleUseCase
        self.searchAisleUseCase = searchAisleUseCase
        self.getMedicineCountByAisleUseCase = getMedicineCountByAisleUseCase
        
        // History
        self.getHistoryUseCase = getHistoryUseCase
        self.getRecentHistoryUseCase = getRecentHistoryUseCase
        self.exportHistoryUseCase = exportHistoryUseCase
        
        // Initialiser les ViewModels
        self.dashboardViewModel = DashboardViewModel(
            getUserUseCase: getUserUseCase,
            getMedicinesUseCase: getMedicinesUseCase,
            getAislesUseCase: getAislesUseCase,
            getRecentHistoryUseCase: getRecentHistoryUseCase
        )
        
        self.medicineListViewModel = MedicineStockViewModel()
        
        self.aislesViewModel = AislesViewModel(
            getAislesUseCase: getAislesUseCase,
            addAisleUseCase: addAisleUseCase,
            updateAisleUseCase: updateAisleUseCase,
            deleteAisleUseCase: deleteAisleUseCase,
            getMedicineCountByAisleUseCase: getMedicineCountByAisleUseCase
        )
        
        self.historyViewModel = HistoryViewModel(
            getHistoryUseCase: getHistoryUseCase,
            getMedicinesUseCase: getMedicinesUseCase,
            exportHistoryUseCase: exportHistoryUseCase
        )
        
        self.profileViewModel = ProfileViewModel(
            getUserUseCase: getUserUseCase,
            signOutUseCase: signOutUseCase
        )
    }
    
    // MARK: - Navigation Methods
    
    func navigateTo(_ destination: NavigationDestination) {
        switch destination {
        case .medicineDetail, .medicineForm, .adjustStock:
            medicineNavigationPath.append(destination)
        case .aisle:
            aislesNavigationPath.append(destination)
        case .criticalStock, .expiringMedicines:
            medicineNavigationPath.append(destination)
        case .history:
            historyNavigationPath.append(destination)
        case .settings:
            profileNavigationPath.append(destination)
        }
    }
    
    func navigateFromDashboard(_ destination: NavigationDestination) {
        dashboardNavigationPath.append(destination)
    }
    
    func dismissGlobalError() {
        globalErrorMessage = nil
    }
    
    func showGlobalError(_ message: String) {
        globalErrorMessage = message
    }
    
    // MARK: - View Factory
    
    @ViewBuilder
    func view(for destination: NavigationDestination) -> some View {
        switch destination {
        case .medicineDetail(let medicine):
            MedicineDetailView(medicine: medicine)
        case .medicineForm(let medicine):
            MedicineFormView(medicineFormViewModel: createMedicineFormViewModel(for: medicine))
        case .adjustStock(let medicine):
            createAdjustStockViewModel(for: medicine)
        case .aisle(let aisle):
            createAisleFormViewModel(for: aisle)
        case .criticalStock:
            Text("Stocks critiques") // À implémenter
        case .expiringMedicines:
            Text("Médicaments expirant bientôt") // À implémenter
        case .history:
            HistoryView(historyViewModel: historyViewModel)
        case .settings:
            Text("Paramètres") // À implémenter
        }
    }
    
    // MARK: - ViewModel Factory Methods
    
    private func createMedicineDetailViewModel(for medicine: Medicine) -> MedicineDetailViewModel {
        return MedicineDetailViewModel(
            medicine: medicine,
            getMedicineUseCase: getMedicineUseCase,
            updateMedicineStockUseCase: MockUpdateMedicineStockUseCase(),
            deleteMedicineUseCase: deleteMedicineUseCase,
            getHistoryUseCase: MockGetHistoryForMedicineUseCase()
        )
    }
    
    private func createMedicineFormViewModel(for medicine: Medicine?) -> MedicineFormViewModel {
        return MedicineFormViewModel(
            getMedicineUseCase: getMedicineUseCase,
            getAislesUseCase: getAislesUseCase,
            addMedicineUseCase: addMedicineUseCase,
            updateMedicineUseCase: updateMedicineUseCase,
            medicine: medicine
        )
    }
    
    private func createAdjustStockViewModel(for medicine: Medicine) -> some View {
        return Text("Adjust Stock View - TODO")
    }
    
    private func createAisleFormViewModel(for aisle: Aisle?) -> some View {
        return Text("Aisle Form View - TODO")
    }
}

// MARK: - Real Implementations

// MARK: - Firebase Repository Implementations
class FirebaseMedicineRepository: MedicineRepositoryProtocol {
    private let db = Firestore.firestore()
    private let collection = "medicines"
    
    func getMedicines() async throws -> [Medicine] {
        let snapshot = try await db.collection(collection).getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: MedicineDTO.self).toDomain()
        }
    }
    
    func getMedicine(id: String) async throws -> Medicine? {
        let document = try await db.collection(collection).document(id).getDocument()
        guard document.exists, let medicineDTO = try? document.data(as: MedicineDTO.self) else { return nil }
        return medicineDTO.toDomain()
    }
    
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        let medicineDTO = MedicineDTO.fromDomain(medicine)
        if medicine.id.isEmpty {
            let documentRef = db.collection(collection).document()
            let newMedicine = Medicine(
                id: documentRef.documentID, name: medicine.name, description: medicine.description,
                dosage: medicine.dosage, form: medicine.form, reference: medicine.reference,
                unit: medicine.unit, currentQuantity: medicine.currentQuantity, maxQuantity: medicine.maxQuantity,
                warningThreshold: medicine.warningThreshold, criticalThreshold: medicine.criticalThreshold,
                expiryDate: medicine.expiryDate, aisleId: medicine.aisleId,
                createdAt: Date(), updatedAt: Date()
            )
            let newMedicineDTO = MedicineDTO.fromDomain(newMedicine)
            try await documentRef.setData(from: newMedicineDTO)
            return newMedicine
        } else {
            let updatedMedicine = Medicine(
                id: medicine.id, name: medicine.name, description: medicine.description,
                dosage: medicine.dosage, form: medicine.form, reference: medicine.reference,
                unit: medicine.unit, currentQuantity: medicine.currentQuantity, maxQuantity: medicine.maxQuantity,
                warningThreshold: medicine.warningThreshold, criticalThreshold: medicine.criticalThreshold,
                expiryDate: medicine.expiryDate, aisleId: medicine.aisleId,
                createdAt: medicine.createdAt, updatedAt: Date()
            )
            let updatedMedicineDTO = MedicineDTO.fromDomain(updatedMedicine)
            try await db.collection(collection).document(medicine.id).setData(from: updatedMedicineDTO)
            return updatedMedicine
        }
    }
    
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        try await db.collection(collection).document(id).updateData([
            "currentQuantity": newStock, "updatedAt": FieldValue.serverTimestamp()
        ])
        guard let updatedMedicine = try await getMedicine(id: id) else {
            throw NSError(domain: "MedicineRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Medicine not found"])
        }
        return updatedMedicine
    }
    
    func deleteMedicine(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
    
    func observeMedicines() -> AnyPublisher<[Medicine], Error> {
        return Future { promise in
            let listener = self.db.collection(self.collection).addSnapshotListener { snapshot, error in
                if let error = error { promise(.failure(error)); return }
                guard let snapshot = snapshot else { promise(.failure(NSError(domain: "MedicineRepository", code: 500))); return }
                let medicines = snapshot.documents.compactMap { try? $0.data(as: MedicineDTO.self).toDomain() }
                promise(.success(medicines))
            }
        }.eraseToAnyPublisher()
    }
    
    func observeMedicine(id: String) -> AnyPublisher<Medicine?, Error> {
        return Future { promise in
            let listener = self.db.collection(self.collection).document(id).addSnapshotListener { snapshot, error in
                if let error = error { promise(.failure(error)); return }
                guard let snapshot = snapshot, snapshot.exists else { promise(.success(nil)); return }
                do {
                    let medicine = try snapshot.data(as: MedicineDTO.self).toDomain()
                    promise(.success(medicine))
                } catch { promise(.failure(error)) }
            }
        }.eraseToAnyPublisher()
    }
}

class FirebaseAisleRepository: AisleRepositoryProtocol {
    private let db = Firestore.firestore()
    private let collection = "aisles"
    private let medicinesCollection = "medicines"
    
    func getAisles() async throws -> [Aisle] {
        let snapshot = try await db.collection(collection).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AisleDTO.self).toDomain() }
    }
    
    func getAisle(id: String) async throws -> Aisle? {
        let document = try await db.collection(collection).document(id).getDocument()
        guard document.exists, let aisleDTO = try? document.data(as: AisleDTO.self) else { return nil }
        return aisleDTO.toDomain()
    }
    
    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        if aisle.id.isEmpty {
            let documentRef = db.collection(collection).document()
            let newAisle = Aisle(id: documentRef.documentID, name: aisle.name, description: aisle.description,
                                colorHex: aisle.colorHex, icon: aisle.icon)
            let newAisleDTO = AisleDTO.fromDomain(newAisle)
            try await documentRef.setData(from: newAisleDTO)
            return newAisle
        } else {
            let updatedAisle = Aisle(id: aisle.id, name: aisle.name, description: aisle.description,
                                   colorHex: aisle.colorHex, icon: aisle.icon)
            let updatedAisleDTO = AisleDTO.fromDomain(updatedAisle)
            try await db.collection(collection).document(aisle.id).setData(from: updatedAisleDTO)
            return updatedAisle
        }
    }
    
    func deleteAisle(id: String) async throws {
        let medicinesInAisle = try await db.collection(medicinesCollection).whereField("aisleId", isEqualTo: id).getDocuments()
        if !medicinesInAisle.documents.isEmpty {
            throw NSError(domain: "AisleRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot delete aisle: it contains medicines"])
        }
        try await db.collection(collection).document(id).delete()
    }
    
    func getMedicineCountByAisle(aisleId: String) async throws -> Int {
        let snapshot = try await db.collection(medicinesCollection).whereField("aisleId", isEqualTo: aisleId).getDocuments()
        return snapshot.documents.count
    }
    
    func observeAisles() -> AnyPublisher<[Aisle], Error> {
        return Future { promise in
            let listener = self.db.collection(self.collection).addSnapshotListener { snapshot, error in
                if let error = error { promise(.failure(error)); return }
                guard let snapshot = snapshot else { promise(.failure(NSError(domain: "AisleRepository", code: 500))); return }
                let aisles = snapshot.documents.compactMap { try? $0.data(as: AisleDTO.self).toDomain() }
                promise(.success(aisles))
            }
        }.eraseToAnyPublisher()
    }
    
    func observeAisle(id: String) -> AnyPublisher<Aisle?, Error> {
        return Future { promise in
            let listener = self.db.collection(self.collection).document(id).addSnapshotListener { snapshot, error in
                if let error = error { promise(.failure(error)); return }
                guard let snapshot = snapshot, snapshot.exists else { promise(.success(nil)); return }
                do {
                    let aisle = try snapshot.data(as: AisleDTO.self).toDomain()
                    promise(.success(aisle))
                } catch { promise(.failure(error)) }
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Real Use Cases
class RealGetMedicinesUseCase: GetMedicinesUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    init(medicineRepository: MedicineRepositoryProtocol) { self.medicineRepository = medicineRepository }
    func execute() async throws -> [Medicine] { try await medicineRepository.getMedicines() }
}

class RealGetMedicineUseCase: GetMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    init(medicineRepository: MedicineRepositoryProtocol) { self.medicineRepository = medicineRepository }
    func execute(id: String) async throws -> Medicine {
        guard let medicine = try await medicineRepository.getMedicine(id: id) else {
            throw NSError(domain: "MedicineUseCase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Medicine not found"])
        }
        return medicine
    }
}

class RealAddMedicineUseCase: AddMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol, historyRepository: HistoryRepositoryProtocol) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
    }
    
    func execute(medicine: Medicine) async throws {
        let savedMedicine = try await medicineRepository.saveMedicine(medicine)
        
        // Ajouter une entrée à l'historique
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: savedMedicine.id,
            userId: "current_user", // TODO: Récupérer l'utilisateur actuel
            action: "Médicament ajouté",
            details: "Nouveau médicament '\(savedMedicine.name)' ajouté avec une quantité de \(savedMedicine.currentQuantity) \(savedMedicine.unit)",
            timestamp: Date()
        )
        
        try await historyRepository.addHistoryEntry(historyEntry)
    }
}

class RealUpdateMedicineUseCase: UpdateMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol, historyRepository: HistoryRepositoryProtocol) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
    }
    
    func execute(medicine: Medicine) async throws {
        let updatedMedicine = try await medicineRepository.saveMedicine(medicine)
        
        // Ajouter une entrée à l'historique
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: updatedMedicine.id,
            userId: "current_user", // TODO: Récupérer l'utilisateur actuel
            action: "Médicament modifié",
            details: "Médicament '\(updatedMedicine.name)' mis à jour",
            timestamp: Date()
        )
        
        try await historyRepository.addHistoryEntry(historyEntry)
    }
}

class RealDeleteMedicineUseCase: DeleteMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol, historyRepository: HistoryRepositoryProtocol) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
    }
    
    func execute(id: String) async throws {
        // Récupérer le médicament avant de le supprimer pour l'historique
        let medicine = try await medicineRepository.getMedicine(id: id)
        
        try await medicineRepository.deleteMedicine(id: id)
        
        // Ajouter une entrée à l'historique si le médicament existait
        if let deletedMedicine = medicine {
            let historyEntry = HistoryEntry(
                id: UUID().uuidString,
                medicineId: deletedMedicine.id,
                userId: "current_user", // TODO: Récupérer l'utilisateur actuel
                action: "Médicament supprimé",
                details: "Médicament '\(deletedMedicine.name)' supprimé du stock",
                timestamp: Date()
            )
            
            try await historyRepository.addHistoryEntry(historyEntry)
        }
    }
}

class RealGetAislesUseCase: GetAislesUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    init(aisleRepository: AisleRepositoryProtocol) { self.aisleRepository = aisleRepository }
    func execute() async throws -> [Aisle] { try await aisleRepository.getAisles() }
}

class RealAddAisleUseCase: AddAisleUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    init(aisleRepository: AisleRepositoryProtocol) { self.aisleRepository = aisleRepository }
    func execute(aisle: Aisle) async throws { _ = try await aisleRepository.saveAisle(aisle) }
}

class RealUpdateAisleUseCase: UpdateAisleUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    init(aisleRepository: AisleRepositoryProtocol) { self.aisleRepository = aisleRepository }
    func execute(aisle: Aisle) async throws { _ = try await aisleRepository.saveAisle(aisle) }
}

class RealDeleteAisleUseCase: DeleteAisleUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    init(aisleRepository: AisleRepositoryProtocol) { self.aisleRepository = aisleRepository }
    func execute(id: String) async throws { try await aisleRepository.deleteAisle(id: id) }
}

class RealGetMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    init(aisleRepository: AisleRepositoryProtocol) { self.aisleRepository = aisleRepository }
    func execute(aisleId: String) async throws -> Int { try await aisleRepository.getMedicineCountByAisle(aisleId: aisleId) }
}

class RealGetUserUseCase: GetUserUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func execute() async throws -> User {
        guard let currentUser = authRepository.currentUser else {
            throw AuthError.userNotFound
        }
        return currentUser
    }
}

class RealSignOutUseCase: SignOutUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func execute() async throws {
        try await authRepository.signOut()
    }
}

class RealGetHistoryUseCase: GetHistoryUseCaseProtocol {
    private let historyRepository: HistoryRepositoryProtocol
    
    init(historyRepository: HistoryRepositoryProtocol) {
        self.historyRepository = historyRepository
    }
    
    func execute() async throws -> [HistoryEntry] {
        return try await historyRepository.getAllHistory()
    }
}

class RealGetRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol {
    private let historyRepository: HistoryRepositoryProtocol
    
    init(historyRepository: HistoryRepositoryProtocol) {
        self.historyRepository = historyRepository
    }
    
    func execute(limit: Int) async throws -> [HistoryEntry] {
        let allHistory = try await historyRepository.getAllHistory()
        return Array(allHistory.prefix(limit))
    }
}

class RealExportHistoryUseCase: ExportHistoryUseCaseProtocol {
    private let historyRepository: HistoryRepositoryProtocol
    
    init(historyRepository: HistoryRepositoryProtocol) {
        self.historyRepository = historyRepository
    }
    
    func execute(format: ExportFormat) async throws -> Data {
        let formatString: String
        switch format {
        case .csv:
            formatString = "csv"
        case .json:
            formatString = "json"
        case .pdf:
            formatString = "pdf"
        }
        return try await historyRepository.exportHistory(format: formatString, medicineId: nil)
    }
}

// MARK: - Mock Implementations

class MockGetUserUseCase: GetUserUseCaseProtocol {
    func execute() async throws -> User {
        return User(id: "mock-user-id", email: "user@example.com", displayName: "Mock User")
    }
}

class MockSignOutUseCase: SignOutUseCaseProtocol {
    func execute() async throws {
        // Mock sign out - do nothing for now
    }
}

class MockGetMedicinesUseCase: GetMedicinesUseCaseProtocol {
    func execute() async throws -> [Medicine] {
        return [
            Medicine(
                id: "1",
                name: "Paracétamol",
                description: "Antalgique et antipyrétique",
                dosage: "500mg",
                form: "Comprimé",
                reference: "PAR-500",
                unit: "comprimé",
                currentQuantity: 45,
                maxQuantity: 100,
                warningThreshold: 20,
                criticalThreshold: 10,
                expiryDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                aisleId: "aisle-1",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Medicine(
                id: "2",
                name: "Ibuprofène",
                description: "Anti-inflammatoire non stéroïdien",
                dosage: "400mg",
                form: "Comprimé",
                reference: "IBU-400",
                unit: "comprimé",
                currentQuantity: 8,
                maxQuantity: 50,
                warningThreshold: 15,
                criticalThreshold: 5,
                expiryDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                aisleId: "aisle-2",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
}

class MockGetMedicineUseCase: GetMedicineUseCaseProtocol {
    func execute(id: String) async throws -> Medicine {
        return Medicine(
            id: id,
            name: "Paracétamol",
            description: "Antalgique et antipyrétique",
            dosage: "500mg",
            form: "Comprimé",
            reference: "PAR-500",
            unit: "comprimé",
            currentQuantity: 45,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            aisleId: "aisle-1",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

class MockAddMedicineUseCase: AddMedicineUseCaseProtocol {
    func execute(medicine: Medicine) async throws {}
}

class MockUpdateMedicineUseCase: UpdateMedicineUseCaseProtocol {
    func execute(medicine: Medicine) async throws {}
}

class MockDeleteMedicineUseCase: DeleteMedicineUseCaseProtocol {
    func execute(id: String) async throws {}
}

class MockAdjustStockUseCase: AdjustStockUseCaseProtocol {
    func execute(medicineId: String, adjustment: Int, reason: String) async throws {}
}

class MockSearchMedicineUseCase: SearchMedicineUseCaseProtocol {
    func execute(query: String) async throws -> [Medicine] {
        return []
    }
}

class MockGetHistoryForMedicineUseCase: GetHistoryForMedicineUseCaseProtocol {
    func execute(medicineId: String) async throws -> [HistoryEntry] {
        return []
    }
}

class MockUpdateMedicineStockUseCase: UpdateMedicineStockUseCaseProtocol {
    func execute(medicineId: String, newQuantity: Int, comment: String) async throws -> Medicine {
        return Medicine(
            id: medicineId,
            name: "Updated Medicine",
            description: "Updated Description",
            dosage: "500mg",
            form: "Comprimé",
            reference: "UPD-500",
            unit: "comprimé",
            currentQuantity: newQuantity,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            aisleId: "aisle-1",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

class MockGetAislesUseCase: GetAislesUseCaseProtocol {
    func execute() async throws -> [Aisle] {
        return [
            Aisle(id: "aisle-1", name: "Analgésiques", description: "Médicaments contre la douleur", colorHex: "#007AFF", icon: "pills"),
            Aisle(id: "aisle-2", name: "Anti-inflammatoires", description: "Médicaments anti-inflammatoires", colorHex: "#34C759", icon: "cross.fill")
        ]
    }
}

class MockAddAisleUseCase: AddAisleUseCaseProtocol {
    func execute(aisle: Aisle) async throws {}
}

class MockUpdateAisleUseCase: UpdateAisleUseCaseProtocol {
    func execute(aisle: Aisle) async throws {}
}

class MockDeleteAisleUseCase: DeleteAisleUseCaseProtocol {
    func execute(id: String) async throws {}
}

class MockSearchAisleUseCase: SearchAisleUseCaseProtocol {
    func execute(query: String) async throws -> [Aisle] {
        return []
    }
}

class MockGetMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol {
    func execute(aisleId: String) async throws -> Int {
        return 5
    }
}

class MockGetHistoryUseCase: GetHistoryUseCaseProtocol {
    func execute() async throws -> [HistoryEntry] {
        return []
    }
}

class MockGetRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol {
    func execute(limit: Int) async throws -> [HistoryEntry] {
        return []
    }
}

class MockExportHistoryUseCase: ExportHistoryUseCaseProtocol {
    func execute(format: ExportFormat) async throws -> Data {
        return Data()
    }
}

// MARK: - Quick ViewModel definitions for compilation

@MainActor
class MedicineListViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    
    private let getMedicinesUseCase: GetMedicinesUseCaseProtocol
    private let getAislesUseCase: GetAislesUseCaseProtocol
    
    init(getMedicinesUseCase: GetMedicinesUseCaseProtocol, getAislesUseCase: GetAislesUseCaseProtocol) {
        self.getMedicinesUseCase = getMedicinesUseCase
        self.getAislesUseCase = getAislesUseCase
    }
    
    func loadMedicines() async {
        do {
            medicines = try await getMedicinesUseCase.execute()
        } catch {
            print("Error loading medicines: \(error)")
        }
    }
    
    func filterByStockStatus(_ status: StockStatus) {
        // TODO: Implement filtering
    }
    
    func filterByExpiryStatus(_ status: ExpiryStatus) {
        // TODO: Implement filtering
    }
}

// MARK: - Preview Helper

extension AppCoordinator {
    static func createWithRealAuth() -> AppCoordinator {
        let authRepository = FirebaseAuthRepository()
        
        // Create real auth use cases but inline to avoid external dependencies
        let getUserUseCase = RealGetUserUseCase(authRepository: authRepository)
        let signOutUseCase = RealSignOutUseCase(authRepository: authRepository)
        
        return AppCoordinator(
            // Auth - using real implementations
            getUserUseCase: getUserUseCase,
            signOutUseCase: signOutUseCase,
            
            // Medicines - using mock for now (can be replaced later)
            getMedicinesUseCase: MockGetMedicinesUseCase(),
            getMedicineUseCase: MockGetMedicineUseCase(),
            addMedicineUseCase: MockAddMedicineUseCase(),
            updateMedicineUseCase: MockUpdateMedicineUseCase(),
            deleteMedicineUseCase: MockDeleteMedicineUseCase(),
            adjustStockUseCase: MockAdjustStockUseCase(),
            searchMedicineUseCase: MockSearchMedicineUseCase(),
            
            // Aisles
            getAislesUseCase: MockGetAislesUseCase(),
            addAisleUseCase: MockAddAisleUseCase(),
            updateAisleUseCase: MockUpdateAisleUseCase(),
            deleteAisleUseCase: MockDeleteAisleUseCase(),
            searchAisleUseCase: MockSearchAisleUseCase(),
            getMedicineCountByAisleUseCase: MockGetMedicineCountByAisleUseCase(),
            
            // History
            getHistoryUseCase: MockGetHistoryUseCase(),
            getRecentHistoryUseCase: MockGetRecentHistoryUseCase(),
            exportHistoryUseCase: MockExportHistoryUseCase()
        )
    }
    
    static func createWithRealFirebase() -> AppCoordinator {
        // Create Firebase repositories
        let authRepository = FirebaseAuthRepository()
        let medicineRepository = FirebaseMedicineRepository()
        let aisleRepository = FirebaseAisleRepository()
        let historyRepository = FirebaseHistoryRepository()
        
        // Auth use cases
        let getUserUseCase = RealGetUserUseCase(authRepository: authRepository)
        let signOutUseCase = RealSignOutUseCase(authRepository: authRepository)
        
        // Medicine use cases with real Firebase
        let getMedicinesUseCase = RealGetMedicinesUseCase(medicineRepository: medicineRepository)
        let getMedicineUseCase = RealGetMedicineUseCase(medicineRepository: medicineRepository)
        let addMedicineUseCase = RealAddMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository)
        let updateMedicineUseCase = RealUpdateMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository)
        let deleteMedicineUseCase = RealDeleteMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository)
        
        // Aisle use cases with real Firebase
        let getAislesUseCase = RealGetAislesUseCase(aisleRepository: aisleRepository)
        let addAisleUseCase = RealAddAisleUseCase(aisleRepository: aisleRepository)
        let updateAisleUseCase = RealUpdateAisleUseCase(aisleRepository: aisleRepository)
        let deleteAisleUseCase = RealDeleteAisleUseCase(aisleRepository: aisleRepository)
        let getMedicineCountByAisleUseCase = RealGetMedicineCountByAisleUseCase(aisleRepository: aisleRepository)
        
        // History use cases with real Firebase
        let getHistoryUseCase = RealGetHistoryUseCase(historyRepository: historyRepository)
        let getRecentHistoryUseCase = RealGetRecentHistoryUseCase(historyRepository: historyRepository)
        let exportHistoryUseCase = RealExportHistoryUseCase(historyRepository: historyRepository)
        
        return AppCoordinator(
            // Auth - using real implementations
            getUserUseCase: getUserUseCase,
            signOutUseCase: signOutUseCase,
            
            // Medicines - using real Firebase implementations
            getMedicinesUseCase: getMedicinesUseCase,
            getMedicineUseCase: getMedicineUseCase,
            addMedicineUseCase: addMedicineUseCase,
            updateMedicineUseCase: updateMedicineUseCase,
            deleteMedicineUseCase: deleteMedicineUseCase,
            adjustStockUseCase: MockAdjustStockUseCase(), // TODO: Implement real adjust stock
            searchMedicineUseCase: MockSearchMedicineUseCase(), // TODO: Implement real search
            
            // Aisles - using real Firebase implementations
            getAislesUseCase: getAislesUseCase,
            addAisleUseCase: addAisleUseCase,
            updateAisleUseCase: updateAisleUseCase,
            deleteAisleUseCase: deleteAisleUseCase,
            searchAisleUseCase: MockSearchAisleUseCase(), // TODO: Implement real search
            getMedicineCountByAisleUseCase: getMedicineCountByAisleUseCase,
            
            // History - using real Firebase implementations
            getHistoryUseCase: getHistoryUseCase,
            getRecentHistoryUseCase: getRecentHistoryUseCase,
            exportHistoryUseCase: exportHistoryUseCase
        )
    }
    
    static var preview: AppCoordinator {
        AppCoordinator(
            // Auth
            getUserUseCase: MockGetUserUseCase(),
            signOutUseCase: MockSignOutUseCase(),
            
            // Medicines
            getMedicinesUseCase: MockGetMedicinesUseCase(),
            getMedicineUseCase: MockGetMedicineUseCase(),
            addMedicineUseCase: MockAddMedicineUseCase(),
            updateMedicineUseCase: MockUpdateMedicineUseCase(),
            deleteMedicineUseCase: MockDeleteMedicineUseCase(),
            adjustStockUseCase: MockAdjustStockUseCase(),
            searchMedicineUseCase: MockSearchMedicineUseCase(),
            
            // Aisles
            getAislesUseCase: MockGetAislesUseCase(),
            addAisleUseCase: MockAddAisleUseCase(),
            updateAisleUseCase: MockUpdateAisleUseCase(),
            deleteAisleUseCase: MockDeleteAisleUseCase(),
            searchAisleUseCase: MockSearchAisleUseCase(),
            getMedicineCountByAisleUseCase: MockGetMedicineCountByAisleUseCase(),
            
            // History
            getHistoryUseCase: MockGetHistoryUseCase(),
            getRecentHistoryUseCase: MockGetRecentHistoryUseCase(),
            exportHistoryUseCase: MockExportHistoryUseCase()
        )
    }
}

// MARK: - ProfileViewModel

@MainActor
class ProfileViewModel: ObservableObject {
    private let getUserUseCase: GetUserUseCaseProtocol
    private let signOutUseCase: SignOutUseCaseProtocol
    
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(getUserUseCase: GetUserUseCaseProtocol, signOutUseCase: SignOutUseCaseProtocol) {
        self.getUserUseCase = getUserUseCase
        self.signOutUseCase = signOutUseCase
    }
    
    @MainActor
    func loadUserProfile() async {
        isLoading = true
        
        do {
            user = try await getUserUseCase.execute()
        } catch {
            errorMessage = "Erreur lors du chargement du profil: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() async {
        isLoading = true
        
        do {
            try await signOutUseCase.execute()
        } catch {
            errorMessage = "Erreur lors de la déconnexion: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Minimal ProfileView

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        List {
            Section(header: Text("Profil")) {
                if let user = viewModel.user {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.accentApp)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(user.displayName ?? "Utilisateur")
                                .font(.headline)
                            
                            Text(user.email ?? "UserEmail")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 10)
                    }
                    .padding(.vertical, 10)
                } else {
                    HStack {
                        ProgressView()
                        Text("Chargement du profil...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Actions")) {
                Button(action: {
                    Task {
                        await viewModel.signOut()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .foregroundColor(.red)
                        Text("Déconnexion")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Mon Profil")
        .task {
            await viewModel.loadUserProfile()
        }
    }
}
