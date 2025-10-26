# Guide des Patterns de Mock - MediStock

## 📋 Table des matières

1. [Principes fondamentaux](#principes-fondamentaux)
2. [Architecture des mocks](#architecture-des-mocks)
3. [Mocks disponibles](#mocks-disponibles)
4. [Patterns d'utilisation](#patterns-dutilisation)
5. [Bonnes pratiques](#bonnes-pratiques)
6. [Exemples complets](#exemples-complets)
7. [Checklist d'isolation](#checklist-disolation)

---

## Principes fondamentaux

### Pourquoi isoler les tests ?

**AUCUN test unitaire ne doit effectuer d'appels réseau réels.**

❌ **Interdictions absolues** :
- Firebase Auth réel
- Firestore réel
- URLSession vers des APIs externes
- Initialisation de services qui contactent le réseau

✅ **Solutions** :
- Utiliser des mocks pour tous les services
- Injection de dépendances via protocoles
- Tests isolés, rapides et fiables

---

## Architecture des mocks

### Structure en couches

```
┌─────────────────────────────────────────┐
│         ViewModels (Tests)              │
│  ↓ utilisent                            │
│         Mock Repositories               │
│  ↓ qui utilisent                        │
│         Mock Data Services              │
│  ↓ qui stockent en                      │
│         Mémoire (Arrays/Dictionaries)   │
└─────────────────────────────────────────┘
```

### Principe d'injection de dépendances

**Au lieu de** :
```swift
// ❌ Mauvais - crée une dépendance réelle
class MyViewModel {
    let repository = MedicineRepository() // Appelle Firebase !
}
```

**Faire** :
```swift
// ✅ Bon - injection de dépendance
class MyViewModel {
    let repository: MedicineRepositoryProtocol

    init(repository: MedicineRepositoryProtocol) {
        self.repository = repository
    }
}

// Dans les tests
let mockRepo = MockMedicineRepository()
let viewModel = MyViewModel(repository: mockRepo)
```

---

## Mocks disponibles

### 1. MockAuthServiceProtocol

**Fichier** : `MediStockTests/Mocks/MockAuthServiceProtocol.swift`

**Utilisation** :
```swift
@MainActor
class AuthViewModelTests: XCTestCase {
    var mockAuthService: MockAuthServiceProtocol!
    var sut: AuthViewModel!

    override func setUp() {
        mockAuthService = MockAuthServiceProtocol()
        // Injecter dans Repository ou ViewModel
    }
}
```

**Fonctionnalités** :
- ✅ Simule toutes les opérations d'authentification
- ✅ Compteurs d'appels (signInCallCount, signUpCallCount, etc.)
- ✅ Configuration d'erreurs personnalisées
- ✅ Délai réseau simulé (configurable)
- ✅ État utilisateur publié via Combine

**Exemple de configuration** :
```swift
// Succès
mockAuthService.setupSuccessfulSignIn(email: "test@example.com")

// Échec avec erreur personnalisée
mockAuthService.setupFailedSignIn(error: AuthError.invalidEmail)

// Configuration manuelle
mockAuthService.shouldFailSignUp = true
mockAuthService.errorToThrow = AuthError.emailAlreadyInUse

// Désactiver le délai pour des tests plus rapides
mockAuthService.disableNetworkDelay()
```

---

### 2. MockMedicineDataService

**Fichier** : `MediStockTests/Mocks/MockMedicineDataService.swift`

**Utilisation** :
```swift
func testFetchMedicines() async throws {
    // Given
    let mockService = MockMedicineDataService()
    mockService.medicines = [
        Medicine.mock(id: "1", name: "Doliprane"),
        Medicine.mock(id: "2", name: "Aspirine")
    ]

    let repository = MockMedicineRepository(medicineService: mockService)

    // When
    let result = try await repository.fetchMedicines()

    // Then
    XCTAssertEqual(result.count, 2)
    XCTAssertEqual(mockService.getAllMedicinesCallCount, 1)
}
```

**Fonctionnalités** :
- ✅ Stockage en mémoire (Array)
- ✅ Toutes les opérations CRUD
- ✅ Pagination simulée
- ✅ Listeners temps réel simulés
- ✅ Validation automatique
- ✅ Historique automatique

**Méthodes clés** :
```swift
// Configuration
mockService.seedTestData()  // Données de test pré-remplies
mockService.reset()          // Réinitialisation complète

// Simulation d'erreurs
mockService.configureFailures(
    getMedicines: true,
    saveMedicine: false,
    deleteMedicine: true
)

// ou
mockService.shouldFailGetMedicines = true
```

---

### 3. MockAisleDataService

**Fichier** : `MediStockTests/Mocks/MockAisleDataService.swift`

**Utilisation** :
```swift
func testCreateAisle() async throws {
    // Given
    let mockService = MockAisleDataService()
    let repository = MockAisleRepository(aisleService: mockService)

    let aisle = Aisle(
        name: "Pharmacie",
        description: "Rayons généraux",
        colorHex: "#4CAF50",
        icon: "pills"
    )

    // When
    let saved = try await repository.saveAisle(aisle)

    // Then
    XCTAssertNotNil(saved.id)
    XCTAssertEqual(mockService.saveAisleCallCount, 1)
}
```

**Fonctionnalités** :
- ✅ Gestion des rayons en mémoire
- ✅ Validation de doublons
- ✅ Comptage de médicaments par rayon
- ✅ Listeners temps réel

**Configuration spécifique** :
```swift
// Simuler des médicaments dans un rayon
mockService.setMedicineCount(for: "aisle-id", count: 5)

// Tenter de supprimer → erreur car rayon contient des médicaments
```

---

### 4. MockHistoryDataService

**Fichier** : `MediStockTests/Mocks/MockHistoryDataService.swift`

**Utilisation** :
```swift
func testRecordHistory() async throws {
    // Given
    let mockService = MockHistoryDataService()

    // When
    try await mockService.recordMedicineAction(
        medicineId: "med-1",
        medicineName: "Doliprane",
        action: "Création",
        details: "Stock initial: 100"
    )

    // Then
    XCTAssertEqual(mockService.recordMedicineActionCallCount, 1)
    XCTAssertEqual(mockService.history.count, 1)
}
```

**Fonctionnalités** :
- ✅ Enregistrement d'actions
- ✅ Filtrage par médicament, date, limite
- ✅ Statistiques d'historique
- ✅ Nettoyage d'anciennes entrées

---

### 5. MockRepositories (Centralisé)

**Fichier** : `MediStockTests/Mocks/MockRepositories.swift`

**Contient** :
- `MockMedicineRepository`
- `MockAisleRepository`
- `MockHistoryRepository`
- `MockAuthRepository`
- `MockNotificationService`
- `MockPDFExportService`

**Avantage** : Tous les mocks de repository en un seul endroit avec API simplifiée.

**Utilisation** :
```swift
let medicineRepo = MockMedicineRepository()
medicineRepo.shouldThrowError = true  // Facile à configurer

let aisleRepo = MockAisleRepository()
aisleRepo.aisles = [/* données de test */]
```

---

## Patterns d'utilisation

### Pattern 1 : Test de ViewModel avec Mock Repository

```swift
@MainActor
final class MedicineListViewModelTests: XCTestCase {
    private var sut: MedicineListViewModel!
    private var mockMedicineRepo: MockMedicineRepository!
    private var mockHistoryRepo: MockHistoryRepository!
    private var mockNotificationService: MockNotificationService!

    override func setUp() async throws {
        // 1. Créer les mocks
        mockMedicineRepo = MockMedicineRepository()
        mockHistoryRepo = MockHistoryRepository()
        mockNotificationService = MockNotificationService()

        // 2. Injecter dans le ViewModel
        sut = MedicineListViewModel(
            medicineRepository: mockMedicineRepo,
            historyRepository: mockHistoryRepo,
            notificationService: mockNotificationService
        )
    }

    func testLoadMedicines() async {
        // Given - Préparer des données de test
        mockMedicineRepo.medicines = [
            Medicine.mock(id: "1", name: "Test Medicine")
        ]

        // When - Exécuter l'action
        await sut.loadMedicines()

        // Then - Vérifier les résultats
        XCTAssertEqual(sut.medicines.count, 1)
        XCTAssertEqual(mockMedicineRepo.fetchMedicinesCallCount, 1)
    }
}
```

---

### Pattern 2 : Test de Repository avec Mock DataService

```swift
@MainActor
final class MedicineRepositoryTests: XCTestCase {
    private var sut: MockMedicineRepository!
    private var mockService: MockMedicineDataService!

    override func setUp() async throws {
        mockService = MockMedicineDataService()
        sut = MockMedicineRepository(medicineService: mockService)
    }

    func testSaveMedicine() async throws {
        // Given
        let medicine = Medicine.mock(name: "New Medicine")

        // When
        let saved = try await sut.saveMedicine(medicine)

        // Then
        XCTAssertNotNil(saved.id)
        XCTAssertEqual(mockService.saveMedicineCallCount, 1)
    }
}
```

---

### Pattern 3 : Test d'erreurs

```swift
func testHandleNetworkError() async {
    // Given - Configurer une erreur
    mockMedicineRepo.shouldThrowError = true

    // When
    await sut.loadMedicines()

    // Then - Vérifier la gestion d'erreur
    XCTAssertNotNil(sut.errorMessage)
    XCTAssertTrue(sut.medicines.isEmpty)
}
```

---

### Pattern 4 : Test de flux asynchrone avec Publishers

```swift
func testUserPublisher() async {
    // Given
    let expectation = XCTestExpectation(description: "User updated")
    var receivedUser: User?

    mockAuthService.$currentUser
        .dropFirst()
        .sink { user in
            receivedUser = user
            expectation.fulfill()
        }
        .store(in: &cancellables)

    // When
    try? await mockAuthService.signIn(email: "test@test.com", password: "pass")

    // Then
    await fulfillment(of: [expectation], timeout: 1.0)
    XCTAssertNotNil(receivedUser)
}
```

---

### Pattern 5 : Test de listeners temps réel

```swift
func testRealtimeListener() {
    // Given
    let expectation = XCTestExpectation(description: "Listener triggered")
    var receivedMedicines: [Medicine] = []

    mockMedicineRepo.startListeningToMedicines { medicines in
        receivedMedicines = medicines
        expectation.fulfill()
    }

    // When - Le listener est déclenché immédiatement

    // Then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertNotNil(receivedMedicines)
}
```

---

## Bonnes pratiques

### ✅ DO (À faire)

1. **Toujours injecter les dépendances**
```swift
// ✅ Bon
init(repository: MedicineRepositoryProtocol) {
    self.repository = repository
}
```

2. **Utiliser les helpers de mock**
```swift
// ✅ Bon - API fluide et lisible
mockService.seedTestData()
mockService.configureFailures(getMedicines: true)
```

3. **Réinitialiser entre les tests**
```swift
override func tearDown() async throws {
    mockService.reset()
    sut = nil
    try await super.tearDown()
}
```

4. **Vérifier les compteurs d'appels**
```swift
// ✅ Bon - Garantit que le mock a été appelé
XCTAssertEqual(mockService.getAllMedicinesCallCount, 1)
```

5. **Tester les erreurs**
```swift
// ✅ Bon - Couvrir les cas d'erreur
mockRepo.shouldThrowError = true
do {
    try await sut.saveMedicine(medicine)
    XCTFail("Should throw error")
} catch {
    XCTAssertNotNil(error)
}
```

---

### ❌ DON'T (À éviter)

1. **Ne pas créer de services réels**
```swift
// ❌ Mauvais - Appelle Firebase !
let authService = AuthService()
```

2. **Ne pas hériter de classes réelles**
```swift
// ❌ Mauvais - Peut initialiser Firebase
class MockAuthService: AuthService {
    // ...
}

// ✅ Bon - Utiliser le protocole
class MockAuthService: AuthServiceProtocol {
    // ...
}
```

3. **Ne pas oublier de configurer les mocks**
```swift
// ❌ Mauvais - Mock vide, test inutile
let mockRepo = MockMedicineRepository()
let result = try await mockRepo.fetchMedicines()
// result sera toujours []

// ✅ Bon - Préparer les données
mockRepo.medicines = [Medicine.mock()]
```

4. **Ne pas ignorer les async/await**
```swift
// ❌ Mauvais - Pas d'await
func testLoad() {
    sut.loadMedicines() // Ne fait rien !
}

// ✅ Bon
func testLoad() async {
    await sut.loadMedicines()
}
```

---

## Exemples complets

### Exemple 1 : Test complet d'un ViewModel

```swift
@MainActor
final class MedicineListViewModelTests: XCTestCase {
    private var sut: MedicineListViewModel!
    private var mockMedicineRepo: MockMedicineRepository!
    private var mockHistoryRepo: MockHistoryRepository!
    private var mockNotificationService: MockNotificationService!

    override func setUp() async throws {
        try await super.setUp()

        mockMedicineRepo = MockMedicineRepository()
        mockHistoryRepo = MockHistoryRepository()
        mockNotificationService = MockNotificationService()

        sut = MedicineListViewModel(
            medicineRepository: mockMedicineRepo,
            historyRepository: mockHistoryRepo,
            notificationService: mockNotificationService
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockMedicineRepo = nil
        mockHistoryRepo = nil
        mockNotificationService = nil
        try await super.tearDown()
    }

    // MARK: - Tests de chargement

    func testLoadMedicinesSuccess() async {
        // Given
        mockMedicineRepo.medicines = [
            Medicine.mock(id: "1", name: "Doliprane", currentQuantity: 50),
            Medicine.mock(id: "2", name: "Aspirine", currentQuantity: 30)
        ]

        // When
        await sut.loadMedicines()

        // Then
        XCTAssertEqual(sut.medicines.count, 2)
        XCTAssertEqual(mockMedicineRepo.fetchMedicinesCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadMedicinesFailure() async {
        // Given
        mockMedicineRepo.shouldThrowError = true

        // When
        await sut.loadMedicines()

        // Then
        XCTAssertTrue(sut.medicines.isEmpty)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Tests d'ajustement de stock

    func testAdjustStockSuccess() async {
        // Given
        let medicine = Medicine.mock(id: "1", currentQuantity: 50)
        mockMedicineRepo.medicines = [medicine]

        // When
        await sut.adjustStock(medicine: medicine, adjustment: 10, reason: "Réception")

        // Then
        XCTAssertEqual(mockMedicineRepo.updateStockCallCount, 1)
        XCTAssertEqual(mockHistoryRepo.addHistoryEntryCallCount, 1)
        XCTAssertNil(sut.errorMessage)
    }

    func testAdjustStockNegativeResultClampsToZero() async {
        // Given
        let medicine = Medicine.mock(id: "1", currentQuantity: 5)
        mockMedicineRepo.medicines = [medicine]

        // When
        await sut.adjustStock(medicine: medicine, adjustment: -10, reason: "Sortie")

        // Then
        let updated = mockMedicineRepo.medicines.first { $0.id == "1" }
        XCTAssertEqual(updated?.currentQuantity, 0)
        XCTAssertGreaterThanOrEqual(updated?.currentQuantity ?? -1, 0)
    }

    // MARK: - Tests de suppression

    func testDeleteMedicineSuccess() async {
        // Given
        let medicine = Medicine.mock(id: "1", name: "ToDelete")
        mockMedicineRepo.medicines = [medicine]

        // When
        await sut.deleteMedicine(medicine)

        // Then
        XCTAssertEqual(mockMedicineRepo.deleteMedicineCallCount, 1)
        XCTAssertTrue(mockMedicineRepo.medicines.isEmpty)
    }
}
```

---

### Exemple 2 : Test d'intégration sans réseau

```swift
@MainActor
final class AuthFlowIntegrationTests: XCTestCase {
    var mockAuthService: MockAuthServiceProtocol!
    var authRepository: AuthRepository!
    var authViewModel: AuthViewModel!

    override func setUp() async throws {
        // 1. Créer le mock au niveau service
        mockAuthService = MockAuthServiceProtocol()

        // 2. Injecter dans le repository
        // Note: AuthRepository devrait accepter AuthServiceProtocol
        // Pour l'instant, on utilise MockAuthRepository
        let mockAuthRepo = MockAuthRepository()

        // 3. Injecter dans le ViewModel
        authViewModel = AuthViewModel(repository: mockAuthRepo)
    }

    func testCompleteSignUpAndSignInFlow() async {
        // Step 1: Sign up
        await authViewModel.signUp(
            email: "newuser@test.com",
            password: "SecurePass123",
            displayName: "New User"
        )
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertNotNil(authViewModel.currentUser)

        // Step 2: Sign out
        await authViewModel.signOut()
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.currentUser)

        // Step 3: Sign in
        await authViewModel.signIn(
            email: "newuser@test.com",
            password: "SecurePass123"
        )
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertNotNil(authViewModel.currentUser)
    }
}
```

---

## Checklist d'isolation

Avant de valider un test, vérifier :

- [ ] **Aucun service réel n'est instancié directement**
- [ ] **Tous les repositories sont injectés via protocoles**
- [ ] **Les mocks sont configurés avec des données de test**
- [ ] **Les compteurs d'appels sont vérifiés**
- [ ] **Les cas d'erreur sont testés**
- [ ] **Les tests sont rapides (< 1 seconde en général)**
- [ ] **Pas d'imports Firebase dans les tests unitaires** (sauf dans les mocks)
- [ ] **setUp() et tearDown() réinitialisent proprement**
- [ ] **Aucun test ne dépend de l'ordre d'exécution**
- [ ] **Les tests async utilisent bien `async`/`await`**

---

## Migration des tests existants

### Avant (avec Firebase réel)

```swift
// ❌ AuthServiceIntegrationTests.swift - PROBLÈME
class AuthServiceIntegrationTests: XCTestCase {
    var authService: AuthService!  // Initialise Firebase !

    override func setUp() {
        authService = AuthService()  // ⚠️ Appel réseau réel
    }

    func testSignIn() async {
        try await authService.signIn(email: "test@test.com", password: "pass")
        // Test qui fait un vrai appel Firebase Auth
    }
}
```

### Après (isolé avec mock)

```swift
// ✅ AuthServiceTests.swift - ISOLÉ
@MainActor
class AuthServiceTests: XCTestCase {
    var mockAuthService: MockAuthServiceProtocol!

    override func setUp() {
        mockAuthService = MockAuthServiceProtocol()
    }

    func testSignInSuccess() async throws {
        // Given - Configuration du mock
        mockAuthService.setupSuccessfulSignIn()

        // When
        try await mockAuthService.signIn(email: "test@test.com", password: "pass")

        // Then
        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertNotNil(mockAuthService.currentUser)
    }

    func testSignInFailure() async {
        // Given
        mockAuthService.setupFailedSignIn(error: AuthError.invalidEmail)

        // When & Then
        do {
            try await mockAuthService.signIn(email: "", password: "pass")
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(mockAuthService.signInCallCount, 1)
        }
    }
}
```

---

## Ressources supplémentaires

### Fichiers importants

- **BaseTestCase.swift** : Classe de base pour tous les tests avec helpers
- **TestConfiguration.swift** : Configuration globale des tests
- **FirebaseTestStubs.swift** : Stubs pour éviter l'initialisation Firebase

### Commandes utiles

```bash
# Lancer uniquement les tests unitaires (isolés)
xcodebuild test -scheme MediStock-UnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:MediStockTests/UnitTests

# Vérifier la couverture de code
xcodebuild test -scheme MediStock -enableCodeCoverage YES
```

---

## Conclusion

**L'isolation des tests garantit** :
- ✅ Tests rapides (pas de latence réseau)
- ✅ Tests fiables (pas d'échecs aléatoires)
- ✅ Tests déterministes (résultats reproductibles)
- ✅ CI/CD efficace (pas de credentials nécessaires)
- ✅ Développement hors ligne possible

**En cas de doute, se poser la question** :
> "Est-ce que ce test pourrait fonctionner sans connexion Internet ?"

Si la réponse est non → utiliser un mock !

---

**Dernière mise à jour** : 2025-10-26
**Version** : 1.0
**Auteur** : TLILI HAMDI
