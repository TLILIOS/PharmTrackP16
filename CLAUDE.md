CLAUDE.md - Guide de Développement
Application de Gestion de Stock Pharmaceutique iOS
📋 Contexte du Projet
Application : Gestion de stock de médicaments en pharmacie Plateforme : iOS natif (SwiftUI + iOS 15+) Architecture : MVVM strict avec Firebase backend Objectif : Digitaliser la gestion des stocks pharmaceutiques avec traçabilité complète
🏗️ Architecture Technique
Stack Principal
swift
// Frontend
- SwiftUI (iOS 15+)
- Combine pour reactive programming
- Core Data pour cache local

// Backend  
- Firebase Firestore (base de données)
- Firebase Auth (authentification)
- Firebase Analytics + Crashlytics

// Architecture
- MVVM strict
- Repository Pattern
- Dependency Injection
- Protocol-Oriented Programming
Structure des Dossiers
text
PharmacyStock/
├── App/
│   ├── PharmacyStockApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Models/
│   ├── Services/
│   ├── Repositories/
│   └── Utilities/
├── Features/
│   ├── Authentication/
│   ├── Inventory/
│   ├── History/
│   └── Settings/
├── Shared/
│   ├── Components/
│   ├── Extensions/
│   └── Constants/
└── Resources/
    ├── Assets.xcassets
    └── Localizations/
🎯 Modules Principaux
1. Authentication Module
swift
// ViewModels requis
- LoginViewModel
- SignUpViewModel
- AuthenticationViewModel

// Fonctionnalités clés
- Login/logout sécurisé avec JWT
- Biométrie (Touch ID/Face ID)
- Gestion des sessions (24h)
- Profils utilisateur (Admin, Pharmacien, Préparateur)
2. Inventory Module
swift
// ViewModels requis
- InventoryViewModel
- MedicamentDetailViewModel
- AddMedicamentViewModel

// Fonctionnalités clés
- Affichage hiérarchique (rayons → médicaments)
- CRUD complet avec validation
- Gestion quantités (+/- avec debounce)
- Recherche et filtrage temps réel
3. History Module
swift
// ViewModels requis
- HistoryViewModel
- HistoryFilterViewModel

// Fonctionnalités clés
- Enregistrement automatique de toutes les actions
- Affichage chronologique avec filtres
- Métadonnées complètes (utilisateur, date, détails)
🧩 Composants Réutilisables à Développer
swift
// UI Components
struct MedicamentCardView: View {
    // Affichage standard d'un médicament
}

struct QuantityStepperView: View {
    // Boutons +/- avec debounce et validation
}

struct HistoryRowView: View {
    // Ligne d'historique avec métadonnées
}

struct CustomSearchBar: View {
    // Barre de recherche avec filtres
}

struct LoadingStateView: View {
    // États de chargement standardisés
}

struct ErrorView: View {
    // Affichage d'erreurs utilisateur
}
📱 Standards UI/UX
Design System
swift
// Colors
struct AppColors {
    static let primary = Color("PrimaryColor")
    static let secondary = Color("SecondaryColor")
    // Support automatique Light/Dark mode
}

// Typography
struct AppFonts {
    static let title = Font.title
    static let body = Font.body
    // Support Dynamic Type obligatoire
}

// Spacing
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
Accessibilité (Obligatoire)
swift
// Exemple d'implémentation VoiceOver
Button("Supprimer médicament") {
    // action
}
.accessibilityLabel("Supprimer le médicament \(medicament.nom)")
.accessibilityHint("Double-tap pour confirmer la suppression")

// Dynamic Type support
Text("Titre")
    .font(.title)
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
🔧 Patterns de Code Obligatoires
1. MVVM Implementation
swift
// ViewModel Template
@MainActor
class MedicamentViewModel: ObservableObject {
    @Published var medicaments: [Medicament] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: MedicamentRepositoryProtocol
    
    init(repository: MedicamentRepositoryProtocol) {
        self.repository = repository
    }
    
    func loadMedicaments() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            medicaments = try await repository.fetchMedicaments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
2. Repository Pattern
swift
protocol MedicamentRepositoryProtocol {
    func fetchMedicaments() async throws -> [Medicament]
    func saveMedicament(_ medicament: Medicament) async throws
    func deleteMedicament(id: String) async throws
}

class FirebaseMedicamentRepository: MedicamentRepositoryProtocol {
    private let firestore = Firestore.firestore()
    
    func fetchMedicaments() async throws -> [Medicament] {
        // Implémentation avec pagination (25 items/page)
        // Tri et filtrage côté serveur obligatoire
    }
}
3. Error Handling
swift
enum AppError: LocalizedError {
    case networkError(String)
    case validationError(String)
    case authenticationError
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Erreur réseau: \(message)"
        case .validationError(let message):
            return "Erreur de validation: \(message)"
        case .authenticationError:
            return "Erreur d'authentification"
        }
    }
}
🚀 Requirements de Performance
Lazy Loading Obligatoire
swift
// Pagination Firebase
func loadNextPage() async {
    let query = collection
        .order(by: "createdAt", descending: true)
        .limit(to: 25)
        .start(afterDocument: lastDocument)
}
Async Operations
swift
// Toutes les opérations réseau en arrière-plan
Task {
    await viewModel.loadData()
}

// Debounce pour les inputs utilisateur
.onReceive(searchText.debounce(for: .milliseconds(300), scheduler: RunLoop.main)) { value in
    Task {
        await searchMedicaments(query: value)
    }
}
✅ Checklist de Validation
Avant chaque commit :
*  Code respecte l'architecture MVVM
*  Composants réutilisables utilisés
*  Gestion d'erreurs implémentée
*  Support Light/Dark mode
*  Labels d'accessibilité présents
*  Dynamic Type supporté
*  Pas de force unwrapping (!)
*  Async/await utilisé pour le réseau
*  Tests unitaires ajoutés
Definition of Done :
*  Feature complète selon PRD
*  Tests unitaires 80%+ coverage
*  Interface responsive tous devices
*  VoiceOver fonctionnel
*  Aucune memory leak détectée
*  Performance < 2s chargement
*  Code review validé
🧪 Tests Obligatoires
swift
// Template test ViewModel
@MainActor
class MedicamentViewModelTests: XCTestCase {
    var viewModel: MedicamentViewModel!
    var mockRepository: MockMedicamentRepository!
    
    override func setUp() {
        mockRepository = MockMedicamentRepository()
        viewModel = MedicamentViewModel(repository: mockRepository)
    }
    
    func testLoadMedicaments_Success() async {
        // Test du cas de succès
    }
    
    func testLoadMedicaments_Error() async {
        // Test de la gestion d'erreur
    }
}
🔐 Sécurité & Bonnes Pratiques
swift
// Jamais de données sensibles en dur
struct Config {
    static let firebaseConfig = Bundle.main.object(forInfoDictionaryKey: "FirebaseConfig")
}

// Validation côté client ET serveur
func validateMedicament(_ medicament: Medicament) throws {
    guard !medicament.nom.isEmpty else {
        throw AppError.validationError("Le nom est obligatoire")
    }
    // Autres validations...
}

// Historisation automatique
func saveMedicament(_ medicament: Medicament) async throws {
    try await repository.save(medicament)
    await historyService.log(.medicamentUpdated(medicament))
}
Note importante : Ce guide doit être respecté strictement pour maintenir la cohérence du projet. Toute déviation doit être justifiée et documentée.
Always rend PLANNING.md at the start of every new conversation. Check TASKS.md before starting your work
Mark completed tasks immediately 
Add newly discovered tasks.
