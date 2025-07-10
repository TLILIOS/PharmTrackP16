import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import Combine

// MARK: - Test Data Service

@MainActor
class TestMedicineDataService {
    private let getAislesUseCase: GetAislesUseCaseProtocol
    private let addMedicineUseCase: AddMedicineUseCaseProtocol
    
    init(getAislesUseCase: GetAislesUseCaseProtocol, addMedicineUseCase: AddMedicineUseCaseProtocol) {
        self.getAislesUseCase = getAislesUseCase
        self.addMedicineUseCase = addMedicineUseCase
    }
    
    func generateTestMedicines() async throws {
        let aisles = try await getAislesUseCase.execute()
        
        for aisle in aisles {
            let medicines = generateMedicinesForAisle(aisle)
            
            for medicine in medicines {
                try await addMedicineUseCase.execute(medicine: medicine)
            }
        }
    }
    
    private func generateMedicinesForAisle(_ aisle: Aisle) -> [Medicine] {
        let medicineTemplates = getMedicineTemplates(for: aisle.name.lowercased())
        
        return medicineTemplates.enumerated().map { index, template in
            Medicine(
                id: "", // Firebase génèrera l'ID
                name: template.name,
                description: template.description,
                dosage: template.dosage,
                form: template.form,
                reference: generateReference(template.name, index: index),
                unit: template.unit,
                currentQuantity: generateRandomStock(),
                maxQuantity: template.maxQuantity,
                warningThreshold: template.warningThreshold,
                criticalThreshold: template.criticalThreshold,
                expiryDate: generateRandomExpiryDate(),
                aisleId: aisle.id,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
    
    private func getMedicineTemplates(for aisleName: String) -> [MedicineTemplate] {
        // Détermine le type de médicaments selon le nom du rayon
        if aisleName.contains("analg") || aisleName.contains("douleur") || aisleName.contains("antalgique") {
            return analgesicMedicines
        } else if aisleName.contains("antibio") || aisleName.contains("infection") {
            return antibioticMedicines
        } else if aisleName.contains("vitamine") || aisleName.contains("supplément") {
            return vitaminMedicines
        } else if aisleName.contains("digest") || aisleName.contains("gastro") {
            return digestiveMedicines
        } else if aisleName.contains("cardio") || aisleName.contains("cœur") || aisleName.contains("tension") {
            return cardiovascularMedicines
        } else {
            return generalMedicines
        }
    }
    
    private func generateReference(_ name: String, index: Int) -> String {
        let prefix = String(name.prefix(3)).uppercased()
        return "\(prefix)-\(String(format: "%03d", index + 1))"
    }
    
    private func generateRandomStock() -> Int {
        let stockTypes = [5, 15, 25, 45, 75, 95] // Variété de stocks
        return stockTypes.randomElement() ?? 50
    }
    
    private func generateRandomExpiryDate() -> Date {
        let daysFromNow = [30, 60, 120, 180, 365, 730].randomElement() ?? 365
        return Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
    }
}

// MARK: - Medicine Templates

struct MedicineTemplate {
    let name: String
    let description: String
    let dosage: String
    let form: String
    let unit: String
    let maxQuantity: Int
    let warningThreshold: Int
    let criticalThreshold: Int
}

// MARK: - Medicine Categories

private let analgesicMedicines: [MedicineTemplate] = [
    MedicineTemplate(name: "Paracétamol", description: "Antalgique et antipyrétique", dosage: "500mg", form: "Comprimé", unit: "comprimé", maxQuantity: 100, warningThreshold: 20, criticalThreshold: 10),
    MedicineTemplate(name: "Ibuprofène", description: "Anti-inflammatoire non stéroïdien", dosage: "400mg", form: "Comprimé", unit: "comprimé", maxQuantity: 80, warningThreshold: 15, criticalThreshold: 8),
    MedicineTemplate(name: "Aspirine", description: "Antalgique et anti-inflammatoire", dosage: "500mg", form: "Comprimé", unit: "comprimé", maxQuantity: 120, warningThreshold: 25, criticalThreshold: 12),
    MedicineTemplate(name: "Doliprane", description: "Paracétamol pour douleurs légères", dosage: "1000mg", form: "Comprimé effervescent", unit: "comprimé", maxQuantity: 60, warningThreshold: 12, criticalThreshold: 6),
    MedicineTemplate(name: "Nurofen", description: "Ibuprofène pour douleurs et fièvre", dosage: "200mg", form: "Gélule", unit: "gélule", maxQuantity: 90, warningThreshold: 18, criticalThreshold: 9),
    MedicineTemplate(name: "Codéine", description: "Antalgique opioïde faible", dosage: "30mg", form: "Comprimé", unit: "comprimé", maxQuantity: 50, warningThreshold: 10, criticalThreshold: 5),
    MedicineTemplate(name: "Tramadol", description: "Antalgique opioïde", dosage: "50mg", form: "Gélule", unit: "gélule", maxQuantity: 40, warningThreshold: 8, criticalThreshold: 4),
    MedicineTemplate(name: "Diclofénac", description: "Anti-inflammatoire topique", dosage: "1%", form: "Gel", unit: "tube", maxQuantity: 30, warningThreshold: 6, criticalThreshold: 3),
    MedicineTemplate(name: "Morphine", description: "Antalgique opioïde fort", dosage: "10mg", form: "Ampoule", unit: "ampoule", maxQuantity: 20, warningThreshold: 4, criticalThreshold: 2),
    MedicineTemplate(name: "Ketoprofène", description: "Anti-inflammatoire puissant", dosage: "100mg", form: "Suppositoire", unit: "suppositoire", maxQuantity: 25, warningThreshold: 5, criticalThreshold: 2)
]

private let antibioticMedicines: [MedicineTemplate] = [
    MedicineTemplate(name: "Amoxicilline", description: "Antibiotique à large spectre", dosage: "500mg", form: "Gélule", unit: "gélule", maxQuantity: 80, warningThreshold: 16, criticalThreshold: 8),
    MedicineTemplate(name: "Azithromycine", description: "Macrolide pour infections respiratoires", dosage: "250mg", form: "Comprimé", unit: "comprimé", maxQuantity: 60, warningThreshold: 12, criticalThreshold: 6),
    MedicineTemplate(name: "Ciprofloxacine", description: "Fluoroquinolone", dosage: "500mg", form: "Comprimé", unit: "comprimé", maxQuantity: 50, warningThreshold: 10, criticalThreshold: 5),
    MedicineTemplate(name: "Clarithromycine", description: "Macrolide pour infections ORL", dosage: "500mg", form: "Comprimé", unit: "comprimé", maxQuantity: 40, warningThreshold: 8, criticalThreshold: 4),
    MedicineTemplate(name: "Doxycycline", description: "Tétracycline", dosage: "100mg", form: "Gélule", unit: "gélule", maxQuantity: 70, warningThreshold: 14, criticalThreshold: 7),
    MedicineTemplate(name: "Erythromycine", description: "Macrolide", dosage: "250mg", form: "Comprimé", unit: "comprimé", maxQuantity: 60, warningThreshold: 12, criticalThreshold: 6),
    MedicineTemplate(name: "Flucloxacilline", description: "Pénicilline anti-staphylococcique", dosage: "500mg", form: "Gélule", unit: "gélule", maxQuantity: 50, warningThreshold: 10, criticalThreshold: 5),
    MedicineTemplate(name: "Gentamicine", description: "Aminoglycoside", dosage: "80mg", form: "Ampoule", unit: "ampoule", maxQuantity: 30, warningThreshold: 6, criticalThreshold: 3),
    MedicineTemplate(name: "Métronidazole", description: "Antiprotozoaire et antibactérien", dosage: "500mg", form: "Comprimé", unit: "comprimé", maxQuantity: 45, warningThreshold: 9, criticalThreshold: 4),
    MedicineTemplate(name: "Vancomycine", description: "Glycopeptide", dosage: "500mg", form: "Flacon", unit: "flacon", maxQuantity: 20, warningThreshold: 4, criticalThreshold: 2)
]

private let vitaminMedicines: [MedicineTemplate] = [
    MedicineTemplate(name: "Vitamine C", description: "Acide ascorbique", dosage: "1000mg", form: "Comprimé effervescent", unit: "comprimé", maxQuantity: 120, warningThreshold: 24, criticalThreshold: 12),
    MedicineTemplate(name: "Vitamine D3", description: "Cholécalciférol", dosage: "1000UI", form: "Gouttes", unit: "flacon", maxQuantity: 50, warningThreshold: 10, criticalThreshold: 5),
    MedicineTemplate(name: "Vitamine B12", description: "Cyanocobalamine", dosage: "1000mcg", form: "Ampoule", unit: "ampoule", maxQuantity: 40, warningThreshold: 8, criticalThreshold: 4),
    MedicineTemplate(name: "Complexe B", description: "Vitamines du groupe B", dosage: "1 dose", form: "Gélule", unit: "gélule", maxQuantity: 100, warningThreshold: 20, criticalThreshold: 10),
    MedicineTemplate(name: "Fer", description: "Sulfate ferreux", dosage: "65mg", form: "Comprimé", unit: "comprimé", maxQuantity: 80, warningThreshold: 16, criticalThreshold: 8),
    MedicineTemplate(name: "Calcium", description: "Carbonate de calcium", dosage: "500mg", form: "Comprimé à croquer", unit: "comprimé", maxQuantity: 90, warningThreshold: 18, criticalThreshold: 9),
    MedicineTemplate(name: "Magnésium", description: "Oxyde de magnésium", dosage: "400mg", form: "Gélule", unit: "gélule", maxQuantity: 70, warningThreshold: 14, criticalThreshold: 7),
    MedicineTemplate(name: "Zinc", description: "Gluconate de zinc", dosage: "15mg", form: "Comprimé", unit: "comprimé", maxQuantity: 60, warningThreshold: 12, criticalThreshold: 6),
    MedicineTemplate(name: "Acide folique", description: "Vitamine B9", dosage: "5mg", form: "Comprimé", unit: "comprimé", maxQuantity: 50, warningThreshold: 10, criticalThreshold: 5),
    MedicineTemplate(name: "Oméga 3", description: "Acides gras essentiels", dosage: "1000mg", form: "Capsule", unit: "capsule", maxQuantity: 90, warningThreshold: 18, criticalThreshold: 9)
]

private let digestiveMedicines: [MedicineTemplate] = [
    MedicineTemplate(name: "Oméprazole", description: "Inhibiteur de la pompe à protons", dosage: "20mg", form: "Gélule", unit: "gélule", maxQuantity: 60, warningThreshold: 12, criticalThreshold: 6),
    MedicineTemplate(name: "Lopéramide", description: "Antidiarrhéique", dosage: "2mg", form: "Gélule", unit: "gélule", maxQuantity: 40, warningThreshold: 8, criticalThreshold: 4),
    MedicineTemplate(name: "Siméticone", description: "Anti-flatulent", dosage: "40mg", form: "Comprimé à croquer", unit: "comprimé", maxQuantity: 80, warningThreshold: 16, criticalThreshold: 8),
    MedicineTemplate(name: "Dompéridone", description: "Antiémétique", dosage: "10mg", form: "Comprimé", unit: "comprimé", maxQuantity: 50, warningThreshold: 10, criticalThreshold: 5),
    MedicineTemplate(name: "Lactulose", description: "Laxatif osmotique", dosage: "15ml", form: "Sirop", unit: "flacon", maxQuantity: 30, warningThreshold: 6, criticalThreshold: 3),
    MedicineTemplate(name: "Ranitidine", description: "Antagoniste H2", dosage: "150mg", form: "Comprimé", unit: "comprimé", maxQuantity: 70, warningThreshold: 14, criticalThreshold: 7),
    MedicineTemplate(name: "Probiotiques", description: "Ferments lactiques", dosage: "1 dose", form: "Gélule", unit: "gélule", maxQuantity: 60, warningThreshold: 12, criticalThreshold: 6),
    MedicineTemplate(name: "Pancréatine", description: "Enzymes digestives", dosage: "25000UI", form: "Gélule", unit: "gélule", maxQuantity: 45, warningThreshold: 9, criticalThreshold: 4),
    MedicineTemplate(name: "Charbon activé", description: "Adsorbant intestinal", dosage: "250mg", form: "Gélule", unit: "gélule", maxQuantity: 40, warningThreshold: 8, criticalThreshold: 4),
    MedicineTemplate(name: "Hyoscine", description: "Antispasmodique", dosage: "10mg", form: "Comprimé", unit: "comprimé", maxQuantity: 35, warningThreshold: 7, criticalThreshold: 3)
]

private let cardiovascularMedicines: [MedicineTemplate] = [
    MedicineTemplate(name: "Amlodipine", description: "Inhibiteur calcique", dosage: "5mg", form: "Comprimé", unit: "comprimé", maxQuantity: 90, warningThreshold: 18, criticalThreshold: 9),
    MedicineTemplate(name: "Lisinopril", description: "Inhibiteur de l'ECA", dosage: "10mg", form: "Comprimé", unit: "comprimé", maxQuantity: 80, warningThreshold: 16, criticalThreshold: 8),
    MedicineTemplate(name: "Métoprolol", description: "Bêta-bloquant", dosage: "50mg", form: "Comprimé", unit: "comprimé", maxQuantity: 70, warningThreshold: 14, criticalThreshold: 7),
    MedicineTemplate(name: "Atorvastatine", description: "Statine", dosage: "20mg", form: "Comprimé", unit: "comprimé", maxQuantity: 60, warningThreshold: 12, criticalThreshold: 6),
    MedicineTemplate(name: "Furosémide", description: "Diurétique de l'anse", dosage: "40mg", form: "Comprimé", unit: "comprimé", maxQuantity: 50, warningThreshold: 10, criticalThreshold: 5),
    MedicineTemplate(name: "Digoxine", description: "Digitalique", dosage: "0.25mg", form: "Comprimé", unit: "comprimé", maxQuantity: 40, warningThreshold: 8, criticalThreshold: 4),
    MedicineTemplate(name: "Warfarine", description: "Anticoagulant", dosage: "5mg", form: "Comprimé", unit: "comprimé", maxQuantity: 30, warningThreshold: 6, criticalThreshold: 3),
    MedicineTemplate(name: "Clopidogrel", description: "Antiagrégant plaquettaire", dosage: "75mg", form: "Comprimé", unit: "comprimé", maxQuantity: 45, warningThreshold: 9, criticalThreshold: 4),
    MedicineTemplate(name: "Isosorbide", description: "Vasodilatateur", dosage: "20mg", form: "Comprimé", unit: "comprimé", maxQuantity: 35, warningThreshold: 7, criticalThreshold: 3),
    MedicineTemplate(name: "Nitroglycérine", description: "Vasodilatateur d'urgence", dosage: "0.4mg", form: "Spray sublingual", unit: "spray", maxQuantity: 25, warningThreshold: 5, criticalThreshold: 2)
]

private let generalMedicines: [MedicineTemplate] = [
    MedicineTemplate(name: "Cétirizine", description: "Antihistaminique", dosage: "10mg", form: "Comprimé", unit: "comprimé", maxQuantity: 60, warningThreshold: 12, criticalThreshold: 6),
    MedicineTemplate(name: "Prednisolone", description: "Corticostéroïde", dosage: "5mg", form: "Comprimé", unit: "comprimé", maxQuantity: 40, warningThreshold: 8, criticalThreshold: 4),
    MedicineTemplate(name: "Salbutamol", description: "Bronchodilatateur", dosage: "100mcg", form: "Inhalateur", unit: "dose", maxQuantity: 200, warningThreshold: 40, criticalThreshold: 20),
    MedicineTemplate(name: "Lorazépam", description: "Anxiolytique", dosage: "1mg", form: "Comprimé", unit: "comprimé", maxQuantity: 30, warningThreshold: 6, criticalThreshold: 3),
    MedicineTemplate(name: "Insuline", description: "Hormone hypoglycémiante", dosage: "100UI/ml", form: "Cartouche", unit: "cartouche", maxQuantity: 20, warningThreshold: 4, criticalThreshold: 2),
    MedicineTemplate(name: "Thyroxine", description: "Hormone thyroïdienne", dosage: "100mcg", form: "Comprimé", unit: "comprimé", maxQuantity: 80, warningThreshold: 16, criticalThreshold: 8),
    MedicineTemplate(name: "Metformine", description: "Antidiabétique", dosage: "500mg", form: "Comprimé", unit: "comprimé", maxQuantity: 90, warningThreshold: 18, criticalThreshold: 9),
    MedicineTemplate(name: "Fluconazole", description: "Antifongique", dosage: "150mg", form: "Gélule", unit: "gélule", maxQuantity: 25, warningThreshold: 5, criticalThreshold: 2),
    MedicineTemplate(name: "Aciclovir", description: "Antiviral", dosage: "400mg", form: "Comprimé", unit: "comprimé", maxQuantity: 35, warningThreshold: 7, criticalThreshold: 3),
    MedicineTemplate(name: "Paracétamol injectable", description: "Antalgique intraveineux", dosage: "1g", form: "Flacon", unit: "flacon", maxQuantity: 30, warningThreshold: 6, criticalThreshold: 3)
]

// MARK: - Use Case Protocols

// Authentication Use Cases
public protocol GetUserUseCaseProtocol {
    func execute() async throws -> User
}

protocol SignInUseCaseProtocol {
    func execute(email: String, password: String) async throws
}

protocol SignUpUseCaseProtocol {
    func execute(email: String, password: String, name: String) async throws
}

public protocol SignOutUseCaseProtocol {
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
    case medicineDetail(String) // Medicine ID
    case medicineForm(String?) // Medicine ID or nil for new
    case adjustStock(String) // Medicine ID
    case aisle(String?) // Aisle ID or nil for new
    case medicinesByAisle(String) // Aisle ID
    case criticalStock
    case expiringMedicines
    case history
    case settings
    case medicineList // Liste des médicaments
    case aisles // Liste des rayons
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .medicineDetail(let medicineId):
            hasher.combine("medicineDetail")
            hasher.combine(medicineId)
        case .medicineForm(let medicineId):
            hasher.combine("medicineForm")
            hasher.combine(medicineId ?? "new")
        case .adjustStock(let medicineId):
            hasher.combine("adjustStock")
            hasher.combine(medicineId)
        case .aisle(let aisleId):
            hasher.combine("aisle")
            hasher.combine(aisleId ?? "new")
        case .medicinesByAisle(let aisleId):
            hasher.combine("medicinesByAisle")
            hasher.combine(aisleId)
        case .criticalStock:
            hasher.combine("criticalStock")
        case .expiringMedicines:
            hasher.combine("expiringMedicines")
        case .history:
            hasher.combine("history")
        case .settings:
            hasher.combine("settings")
        case .medicineList:
            hasher.combine("medicineList")
        case .aisles:
            hasher.combine("aisles")
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.medicineDetail(let lhsId), .medicineDetail(let rhsId)):
            return lhsId == rhsId
        case (.medicineForm(let lhsId), .medicineForm(let rhsId)):
            return lhsId == rhsId
        case (.adjustStock(let lhsId), .adjustStock(let rhsId)):
            return lhsId == rhsId
        case (.aisle(let lhsId), .aisle(let rhsId)):
            return lhsId == rhsId
        case (.medicinesByAisle(let lhsId), .medicinesByAisle(let rhsId)):
            return lhsId == rhsId
        case (.criticalStock, .criticalStock),
             (.expiringMedicines, .expiringMedicines),
             (.history, .history),
             (.settings, .settings),
             (.medicineList, .medicineList),
             (.aisles, .aisles):
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
    
    // Stack global unique pour toute l'application
    @Published var globalNavigationPath: [NavigationDestination] = []
    
    // Anciens stacks (conservés temporairement pour compatibilité)
    @Published var dashboardNavigationPath: [NavigationDestination] = []
    @Published var medicineNavigationPath: [NavigationDestination] = []
    @Published var aislesNavigationPath: [NavigationDestination] = []
    @Published var historyNavigationPath: [NavigationDestination] = []
    @Published var profileNavigationPath: [NavigationDestination] = []
    
    @Published var globalErrorMessage: String?
    
    // MARK: - Repositories
    
    private lazy var medicineRepository: MedicineRepositoryProtocol = FirebaseMedicineRepository()
    private lazy var aisleRepository: AisleRepositoryProtocol = FirebaseAisleRepository()
    private lazy var historyRepository: HistoryRepositoryProtocol = FirebaseHistoryRepository()
    private let authRepository: AuthRepositoryProtocol
    
    // MARK: - Use Cases
    
    lazy var getUserUseCase: GetUserUseCaseProtocol = RealGetUserUseCase(authRepository: authRepository)
    lazy var signOutUseCase: SignOutUseCaseProtocol = RealSignOutUseCase(authRepository: authRepository)
    lazy var getMedicineUseCase: GetMedicineUseCaseProtocol = RealGetMedicineUseCase(medicineRepository: medicineRepository)
    lazy var searchMedicineUseCase: SearchMedicineUseCaseProtocol = RealSearchMedicineUseCase(medicineRepository: medicineRepository)
    lazy var getAislesUseCase: GetAislesUseCaseProtocol = RealGetAislesUseCase(aisleRepository: aisleRepository)
    lazy var searchAisleUseCase: SearchAisleUseCaseProtocol = RealSearchAisleUseCase(aisleRepository: aisleRepository)
    lazy var addMedicineUseCase: AddMedicineUseCaseProtocol = RealAddMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository)
    
    // MARK: - ViewModels
    
    lazy var dashboardViewModel: DashboardViewModel = {
        DashboardViewModel(
            getUserUseCase: getUserUseCase,
            getMedicinesUseCase: RealGetMedicinesUseCase(medicineRepository: medicineRepository),
            getAislesUseCase: getAislesUseCase,
            getRecentHistoryUseCase: RealGetRecentHistoryUseCase(historyRepository: historyRepository),
            appCoordinator: self
        )
    }()
    
    lazy var medicineListViewModel: MedicineStockViewModel = {
        MedicineStockViewModel(
            medicineRepository: medicineRepository,
            aisleRepository: aisleRepository,
            historyRepository: historyRepository
        )
    }()
    
    lazy var aislesViewModel: AislesViewModel = {
        AislesViewModel(
            getAislesUseCase: getAislesUseCase,
            addAisleUseCase: RealAddAisleUseCase(aisleRepository: aisleRepository),
            updateAisleUseCase: RealUpdateAisleUseCase(aisleRepository: aisleRepository),
            deleteAisleUseCase: RealDeleteAisleUseCase(aisleRepository: aisleRepository),
            getMedicineCountByAisleUseCase: RealGetMedicineCountByAisleUseCase(aisleRepository: aisleRepository)
        )
    }()
    
    lazy var historyViewModel: HistoryViewModel = {
        return HistoryViewModel(
            getHistoryUseCase: RealGetHistoryUseCase(historyRepository: historyRepository),
            getMedicinesUseCase: RealGetMedicinesUseCase(medicineRepository: medicineRepository),
            exportHistoryUseCase: RealExportHistoryUseCase(historyRepository: historyRepository)
        )
    }()
    
    lazy var profileViewModel: ProfileViewModel = {
        return ProfileViewModel(
            getUserUseCase: getUserUseCase,
            signOutUseCase: signOutUseCase,
            testDataService: TestMedicineDataService(
                getAislesUseCase: getAislesUseCase,
                addMedicineUseCase: addMedicineUseCase
            )
        )
    }()
    
    // MARK: - Initialization
    
    init(authRepository: AuthRepositoryProtocol = FirebaseAuthRepository()) {
        self.authRepository = authRepository
    }
    
    // MARK: - Navigation Methods
    
    func navigateTo(_ destination: NavigationDestination) {
        // Navigation simplifiée : toutes les destinations vont dans le stack global
        globalNavigationPath.append(destination)
    }
    
    // Note: Logique de navigation contextuelle supprimée - plus nécessaire avec le stack global
    
    func navigateFromDashboard(_ destination: NavigationDestination) {
        // Navigation simplifiée : utilise le stack global
        globalNavigationPath.append(destination)
    }
    
    func navigateFromAisle(_ destination: NavigationDestination) {
        // Navigation simplifiée : utilise le stack global
        globalNavigationPath.append(destination)
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
        case .medicineDetail(let medicineId):
            MedicineDetailViewWrapper(medicineId: medicineId, appCoordinator: self)
        case .medicineForm(let medicineId):
            MedicineFormViewWrapper(medicineId: medicineId, appCoordinator: self)
        case .adjustStock(let medicineId):
            AdjustStockViewWrapper(medicineId: medicineId, appCoordinator: self)
        case .aisle(let aisleId):
            AisleFormViewWrapper(aisleId: aisleId, appCoordinator: self)
        case .medicinesByAisle(let aisleId):
            AisleMedicinesView(aisleId: aisleId, appCoordinator: self)
        case .criticalStock:
            CriticalStockViewWrapper(dashboardViewModel: dashboardViewModel)
        case .expiringMedicines:
            ExpiringMedicinesInlineView(dashboardViewModel: dashboardViewModel)
        case .history:
            HistoryView(historyViewModel: historyViewModel)
        case .settings:
            Text("Paramètres") // À implémenter
        case .medicineList:
            MedicineListView(medicineStockViewModel: medicineListViewModel)
        case .aisles:
            AislesView(aislesViewModel: aislesViewModel)
        }
    }
    
    // MARK: - ViewModel Factory Methods
    
     func createMedicineDetailViewModel(for medicine: Medicine) -> MedicineDetailViewModel {
        return MedicineDetailViewModel(
            medicine: medicine,
            getMedicineUseCase: getMedicineUseCase,
            updateMedicineStockUseCase: RealUpdateMedicineStockUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository),
            deleteMedicineUseCase: RealDeleteMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository),
            getHistoryUseCase: MockGetHistoryForMedicineUseCase()
        )
    }
    
     func createMedicineFormViewModel(for medicine: Medicine?) -> MedicineFormViewModel {
        return MedicineFormViewModel(
            getMedicineUseCase: getMedicineUseCase,
            getAislesUseCase: getAislesUseCase,
            addMedicineUseCase: RealAddMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository),
            updateMedicineUseCase: RealUpdateMedicineUseCase(medicineRepository: medicineRepository, historyRepository: historyRepository),
            medicine: medicine
        )
    }
    
    private func createAdjustStockViewModel(for medicine: Medicine) -> some View {
        let medicineDetailViewModel = createMedicineDetailViewModel(for: medicine)
        return AdjustStockView(viewModel: medicineDetailViewModel)
    }
    
    private func createAisleFormViewModel(for aisle: Aisle?) -> some View {
        return Text("Aisle Form View - TODO")
    }
    
    private func getAisleName(for aisleId: String) -> String {
        // Simple implementation - in real app, this should fetch from repository
        return "Médicaments du rayon"
    }
}

// MARK: - Navigation Wrapper Views

struct AdjustStockViewWrapper: View {
    let medicineId: String
    let appCoordinator: AppCoordinator
    @State private var medicine: Medicine?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Chargement...")
            } else if let medicine = medicine {
                AdjustStockView(viewModel: appCoordinator.createMedicineDetailViewModel(for: medicine))
            } else {
                VStack {
                    Text("Médicament introuvable")
                    Text(errorMessage ?? "")
                        .foregroundColor(.red)
                }
            }
        }
        .task {
            await loadMedicine()
        }
    }
    
    private func loadMedicine() async {
        do {
            medicine = try await appCoordinator.getMedicineUseCase.execute(id: medicineId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct MedicineDetailViewWrapper: View {
    let medicineId: String
    let appCoordinator: AppCoordinator
    @State private var medicine: Medicine?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Chargement...")
            } else if let medicine = medicine {
                MedicineDetailView(viewModel: appCoordinator.createMedicineDetailViewModel(for: medicine))
            } else {
                Text("Médicament introuvable")
            }
        }
        .task {
            await loadMedicine()
        }
    }
    
    private func loadMedicine() async {
        do {
            medicine = try await appCoordinator.getMedicineUseCase.execute(id: medicineId)
        } catch {
            print("Error loading medicine: \(error)")
        }
        isLoading = false
    }
}

struct MedicineFormViewWrapper: View {
    let medicineId: String?
    let appCoordinator: AppCoordinator
    @State private var medicine: Medicine?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if medicineId == nil {
                // New medicine
                MedicineFormView(medicineFormViewModel: appCoordinator.createMedicineFormViewModel(for: nil))
            } else if isLoading {
                ProgressView("Chargement...")
            } else if let medicine = medicine {
                MedicineFormView(medicineFormViewModel: appCoordinator.createMedicineFormViewModel(for: medicine))
            } else {
                Text("Médicament introuvable")
            }
        }
        .task {
            if let medicineId = medicineId {
                await loadMedicine(id: medicineId)
            } else {
                isLoading = false
            }
        }
    }
    
    private func loadMedicine(id: String) async {
        do {
            medicine = try await appCoordinator.getMedicineUseCase.execute(id: id)
        } catch {
            print("Error loading medicine: \(error)")
        }
        isLoading = false
    }
}

struct AisleFormViewWrapper: View {
    let aisleId: String?
    let appCoordinator: AppCoordinator
    
    var body: some View {
        Text("Aisle Form View - TODO")
    }
}

struct AisleMedicinesView: View {
    let aisleId: String
    let appCoordinator: AppCoordinator
    @State private var aisle: Aisle?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Chargement...")
            } else if let aisle = aisle {
                AisleMedicineListWrapper(
                    aisle: aisle,
                    medicineStockViewModel: appCoordinator.medicineListViewModel,
                    appCoordinator: appCoordinator
                )
                .navigationTitle(aisle.name)
                .onAppear {
                    // Pre-select this aisle in the medicine list filter
                    Task {
                        await appCoordinator.medicineListViewModel.fetchMedicines()
                        try await appCoordinator.medicineListViewModel.fetchAisles()
                    }
                }
            } else {
                Text("Rayon introuvable")
            }
        }
        .task {
            await loadAisle()
        }
    }
    
    private func loadAisle() async {
        do {
            let allAisles = try await appCoordinator.getAislesUseCase.execute()
            aisle = allAisles.first { $0.id == aisleId }
        } catch {
            print("Error loading aisle: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Wrapper pour navigation correcte depuis rayons
struct AisleMedicineListWrapper: View {
    let aisle: Aisle
    let medicineStockViewModel: MedicineStockViewModel
    let appCoordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 0) {
            // Liste des médicaments avec navigation corrigée
            if medicineStockViewModel.isLoading {
                Spacer()
                ProgressView("Chargement des médicaments...")
                Spacer()
            } else if medicineStockViewModel.medicines.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "pills")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Aucun médicament")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                List {
                    ForEach(medicinesInAisle) { medicine in
                        AisleMedicineCard(medicine: medicine) {
                            // Navigation corrigée: utilise aislesNavigationPath
                            appCoordinator.navigateFromAisle(.medicineDetail(medicine.id))
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Navigation corrigée pour ajouter médicament
                    appCoordinator.navigateFromAisle(.medicineForm(nil))
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            Task {
                await medicineStockViewModel.fetchMedicines()
            }
        }
    }
    
    // Filtre les médicaments pour cet aisle
    private var medicinesInAisle: [Medicine] {
        medicineStockViewModel.medicines.filter { medicine in
            medicine.aisleId == aisle.id
        }
    }
}

// MARK: - Medicine Card pour navigation depuis Rayon
struct AisleMedicineCard: View {
    let medicine: Medicine
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Statut du stock
            Circle()
                .fill(stockColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.name ?? "Nom non spécifié")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(medicine.dosage ?? "Dosage non spécifié")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Stock: \(medicine.currentQuantity)")
                        .font(.caption)
                        .foregroundColor(stockColor)
                    
                    Spacer()
                    
                    if let expiryDate = medicine.expiryDate {
                        Text("Exp: \(formatDate(expiryDate))")
                            .font(.caption)
                            .foregroundColor(isExpiringSoon(expiryDate) ? .orange : .secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
    
    private var stockColor: Color {
        if medicine.currentQuantity <= medicine.criticalThreshold {
            return .red
        } else if medicine.currentQuantity <= medicine.warningThreshold {
            return .orange
        } else {
            return .green
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func isExpiringSoon(_ date: Date) -> Bool {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return date <= thirtyDaysFromNow
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

public class RealGetUserUseCase: GetUserUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    public func execute() async throws -> User {
        guard let currentUser = authRepository.currentUser else {
            throw AuthError.userNotFound
        }
        return currentUser
    }
}

public class RealSignOutUseCase: SignOutUseCaseProtocol {
    private let authRepository: AuthRepositoryProtocol
    
    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    public func execute() async throws {
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

class RealSearchMedicineUseCase: SearchMedicineUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol) {
        self.medicineRepository = medicineRepository
    }
    
    func execute(query: String) async throws -> [Medicine] {
        let allMedicines = try await medicineRepository.getMedicines()
        
        // Recherche insensible à la casse dans le nom et la description
        return allMedicines.filter { medicine in
            let searchQuery = query.lowercased()
            let nameMatch = medicine.name.lowercased().contains(searchQuery)
            let descriptionMatch = medicine.description?.lowercased().contains(searchQuery) ?? false
            let referenceMatch = medicine.reference?.lowercased().contains(searchQuery) ?? false
            
            return nameMatch || descriptionMatch || referenceMatch
        }
    }
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

class RealUpdateMedicineStockUseCase: UpdateMedicineStockUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol, historyRepository: HistoryRepositoryProtocol) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
    }
    
    func execute(medicineId: String, newQuantity: Int, comment: String) async throws -> Medicine {
        // Mettre à jour le stock dans le repository
        let updatedMedicine = try await medicineRepository.updateMedicineStock(id: medicineId, newStock: newQuantity)
        
        // Ajouter une entrée à l'historique
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: "current_user", // TODO: Récupérer l'utilisateur actuel
            action: "Stock ajusté",
            details: comment.isEmpty ? "Stock ajusté à \(newQuantity) \(updatedMedicine.unit)" : comment,
            timestamp: Date()
        )
        
        try await historyRepository.addHistoryEntry(historyEntry)
        
        return updatedMedicine
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

class RealSearchAisleUseCase: SearchAisleUseCaseProtocol {
    private let aisleRepository: AisleRepositoryProtocol
    
    init(aisleRepository: AisleRepositoryProtocol) {
        self.aisleRepository = aisleRepository
    }
    
    func execute(query: String) async throws -> [Aisle] {
        let allAisles = try await aisleRepository.getAisles()
        
        // Recherche insensible à la casse dans le nom et la description
        return allAisles.filter { aisle in
            let searchQuery = query.lowercased()
            let nameMatch = aisle.name.lowercased().contains(searchQuery)
            let descriptionMatch = aisle.description?.lowercased().contains(searchQuery) ?? false
            
            return nameMatch || descriptionMatch
        }
    }
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
    static var preview: AppCoordinator {
        AppCoordinator(authRepository: FirebaseAuthRepository())
    }
    
    static func createWithRealFirebase(authRepository: AuthRepositoryProtocol) -> AppCoordinator {
        AppCoordinator(authRepository: authRepository)
    }
}

// MARK: - View Wrappers

struct CriticalStockViewWrapper: View {
    let dashboardViewModel: DashboardViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            
            if dashboardViewModel.criticalStockMedicines.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Aucun stock critique")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Tous vos médicaments ont des stocks suffisants.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(dashboardViewModel.criticalStockMedicines, id: \.id) { medicine in
                            CriticalStockMedicineRowWrapper(medicine: medicine) {
                                appCoordinator.navigateFromDashboard(.adjustStock(medicine.id))
                            } onAdjustStock: {
                                appCoordinator.navigateFromDashboard(.adjustStock(medicine.id))
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .navigationTitle("Stocks critiques")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await dashboardViewModel.fetchData()
            }
        }
    }
}

struct CriticalStockMedicineRowWrapper: View {
    let medicine: Medicine
    let onTap: () -> Void
    let onAdjustStock: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.name ?? "Nom non spécifié")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(medicine.dosage ?? "Dosage non spécifié")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(medicine.currentQuantity)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("/ \(medicine.maxQuantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Barre de progression
            ProgressView(value: Double(medicine.currentQuantity), total: Double(medicine.maxQuantity))
                .progressViewStyle(LinearProgressViewStyle(tint: .red))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("Seuil critique: \(medicine.criticalThreshold)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onAdjustStock) {
                    Label("Ajuster", systemImage: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentApp)
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Temporary Mock Classes for Compilation

@MainActor
func MockHistoryViewModel() -> HistoryViewModel {
    return HistoryViewModel(
        getHistoryUseCase: MockGetHistoryUseCase(),
        getMedicinesUseCase: MockGetMedicinesUseCase(),
        exportHistoryUseCase: MockExportHistoryUseCase()
    )
}

@MainActor
func MockProfileViewModel() -> ProfileViewModel {
    return ProfileViewModel(
        getUserUseCase: MockGetUserUseCase(),
        signOutUseCase: MockSignOutUseCase(),
        testDataService: TestMedicineDataService(
            getAislesUseCase: MockGetAislesUseCase(),
            addMedicineUseCase: MockAddMedicineUseCase()
        )
    )
}

// MARK: - ProfileViewModel

@MainActor
class ProfileViewModel: ObservableObject {
    private let getUserUseCase: GetUserUseCaseProtocol
    private let signOutUseCase: SignOutUseCaseProtocol
    private let testDataService: TestMedicineDataService
    
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isGeneratingTestData = false
    
    init(
        getUserUseCase: GetUserUseCaseProtocol, 
        signOutUseCase: SignOutUseCaseProtocol,
        testDataService: TestMedicineDataService
    ) {
        self.getUserUseCase = getUserUseCase
        self.signOutUseCase = signOutUseCase
        self.testDataService = testDataService
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
    
    @MainActor
    func generateTestMedicines() async {
        isGeneratingTestData = true
        errorMessage = nil
        
        do {
            try await testDataService.generateTestMedicines()
            // Success - maybe show a success message
        } catch {
            errorMessage = "Erreur lors de la génération des médicaments de test: \(error.localizedDescription)"
        }
        
        isGeneratingTestData = false
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
                        await viewModel.generateTestMedicines()
                    }
                }) {
                    HStack {
                        if viewModel.isGeneratingTestData {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "pills.fill")
                                .foregroundColor(.blue)
                        }
                        Text(viewModel.isGeneratingTestData ? "Génération en cours..." : "Générer médicaments de test")
                            .foregroundColor(.blue)
                    }
                }
                .disabled(viewModel.isGeneratingTestData)
                
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
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Expiring Medicines Inline View

struct ExpiringMedicinesInlineView: View {
    @ObservedObject var dashboardViewModel: DashboardViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            VStack {
                if dashboardViewModel.state == .loading {
                    Spacer()
                    ProgressView("Chargement des médicaments expirant...")
                    Spacer()
                } else if dashboardViewModel.expiringMedicines.isEmpty {
                    ExpiringMedicinesEmptyInlineView()
                } else {
                    expiringMedicinesList
                }
            }
            .navigationTitle("Expirations proches")
            .navigationBarTitleDisplayMode(.large)
            
            if case .error(let message) = dashboardViewModel.state {
                VStack {
                    Spacer()
                    MessageView(message: message, type: .error) {
                        dashboardViewModel.resetState()
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: dashboardViewModel.state)
                .zIndex(1)
            }
        }
        .onAppear {
            Task {
                await dashboardViewModel.fetchData()
            }
        }
        .refreshable {
            await performRefresh()
        }
    }
    
    private var expiringMedicinesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dashboardViewModel.expiringMedicines, id: \.id) { medicine in
                    ExpiringMedicineInlineRow(medicine: medicine) {
                        appCoordinator.navigateFromDashboard(.medicineDetail(medicine.id))
                    }
                }
            }
            .padding()
        }
    }
    
    private func performRefresh() async {
        isRefreshing = true
        await dashboardViewModel.fetchData()
        isRefreshing = false
    }
}

struct ExpiringMedicineInlineRow: View {
    let medicine: Medicine
    let onTap: () -> Void
    
    private var daysUntilExpiry: Int {
        guard let expiryDate = medicine.expiryDate else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        return max(0, days)
    }
    
    private var expiryColor: Color {
        let days = daysUntilExpiry
        if days <= 7 {
            return .red
        } else if days <= 14 {
            return .orange
        } else {
            return .yellow
        }
    }
    
    private var expiryText: String {
        let days = daysUntilExpiry
        if days == 0 {
            return "Expire aujourd'hui"
        } else if days == 1 {
            return "Expire demain"
        } else {
            return "Expire dans \(days) jours"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(medicine.dosage ?? "Dosage non spécifié")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let expiryDate = medicine.expiryDate {
                        Text(formatDate(expiryDate))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(expiryColor)
                    }
                    
                    Text("Stock: \(medicine.currentQuantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(expiryColor)
                
                Text(expiryText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(expiryColor)
                
                Spacer()
                
                Button(action: onTap) {
                    Label("Voir détails", systemImage: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentApp)
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            ProgressView(value: max(0, Double(30 - daysUntilExpiry)), total: 30.0)
                .progressViewStyle(LinearProgressViewStyle(tint: expiryColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

struct ExpiringMedicinesEmptyInlineView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Aucune expiration proche")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tous vos médicaments ont des dates d'expiration suffisamment éloignées.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
