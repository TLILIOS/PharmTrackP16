# Solution - Gestion Sécurisée des APIs Firebase & Architecture Testable

## 📋 Table des Matières

1. [Problèmes Identifiés](#problèmes-identifiés)
2. [Architecture Proposée](#architecture-proposée)
3. [Implémentation](#implémentation)
4. [Configuration Sécurisée](#configuration-sécurisée)
5. [Tests Unitaires](#tests-unitaires)
6. [Migration du Code Existant](#migration-du-code-existant)
7. [Best Practices](#best-practices)

---

## 🔴 Problèmes Identifiés

### 1. Sécurité - API Key Exposée

**Fichier**: `GoogleService-Info.plist:6`

```xml
<key>API_KEY</key>
<string>AIzaSyC7Wn2menru8zbgZtVPxF-u09JRrV1tNXs</string>
```

**Risques**:
- ⚠️ API Key visible dans le repository Git
- ⚠️ Utilisation abusive possible par des tiers
- ⚠️ Quotas Firebase dépassés = coûts non contrôlés
- ⚠️ Pas de séparation environnement dev/test/prod

### 2. Couplage Fort avec Firebase

**Services concernés**:
- `AuthService.swift:2` - Import direct `FirebaseAuth`
- `DataService.swift:2-3` - Imports directs `FirebaseFirestore`, `FirebaseAuth`

**Problème**: Impossible de tester sans connexion Firebase réelle

### 3. Tests d'Intégration Fragiles

**Fichiers**: `AuthServiceIntegrationTests.swift`, `IntegrationTests.swift`

**Problèmes**:
- Tests qui échouent avec erreurs d'API Key invalide
- Dépendance au réseau = tests lents et instables
- Pas de mocks = tests impossibles hors ligne

### 4. Architecture Non Testable

- ❌ Absence de protocoles pour abstraire Firebase
- ❌ Injection de dépendances insuffisante
- ❌ Mélange logique métier et appels API

---

## 🏗️ Architecture Proposée

### Principe: Protocol-Oriented Programming + Dependency Injection

```
┌─────────────────────────────────────────────────────┐
│                    Views (SwiftUI)                   │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              ViewModels (@Observable)                │
│         - Injecte AuthServiceProtocol               │
│         - Injecte DataServiceProtocol               │
└──────────────────────┬──────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼────────┐          ┌────────▼─────────┐
│   Production   │          │      Tests       │
│                │          │                  │
│ FirebaseAuth   │          │  MockAuthService │
│ Service        │          │                  │
│                │          │  MockDataService │
│ FirebaseData   │          │                  │
│ Service        │          └──────────────────┘
└────────────────┘
```

### Avantages

✅ **Testabilité**: Injection de mocks dans les tests
✅ **Découplage**: ViewModels indépendants de Firebase
✅ **Flexibilité**: Changement de backend sans refactoring
✅ **Sécurité**: API Keys séparées par environnement

---

## 🛠️ Implémentation

### 1. Protocoles d'Abstraction

#### `AuthServiceProtocol.swift`

```swift
@MainActor
protocol AuthServiceProtocol: ObservableObject {
    var currentUser: User? { get set }

    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, displayName: String) async throws
    func signOut() async throws
    func resetPassword(email: String) async throws
    func getAuthToken() async throws -> String?
}
```

#### `DataServiceProtocol.swift`

```swift
protocol DataServiceProtocol {
    func getMedicines() async throws -> [Medicine]
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine
    func deleteMedicine(id: String) async throws

    func getAisles() async throws -> [Aisle]
    func saveAisle(_ aisle: Aisle) async throws -> Aisle
    func deleteAisle(id: String) async throws

    func getHistory() async throws -> [HistoryEntry]
    func addHistoryEntry(_ entry: HistoryEntry) async throws
}
```

### 2. Implémentation Firebase (Production)

#### Mettre à jour `AuthService.swift`

```swift
import FirebaseAuth

@MainActor
class FirebaseAuthService: AuthServiceProtocol {
    @Published var currentUser: User?

    // Implémentation avec Firebase...
}
```

#### Mettre à jour `DataService.swift`

```swift
import FirebaseFirestore

class FirebaseDataService: DataServiceProtocol {
    private let db = Firestore.firestore()

    // Implémentation avec Firestore...
}
```

### 3. Mock Services (Tests)

Les mocks sont déjà créés dans:
- `MediStockTests/Mocks/MockAuthService.swift`
- `MediStockTests/Mocks/MockDataService.swift`

**Fonctionnalités**:
- ✅ Simule les appels réseau avec délai
- ✅ Gestion des erreurs configurables
- ✅ Compteurs d'appels pour assertions
- ✅ Données en mémoire (pas de Firebase)

---

## 🔒 Configuration Sécurisée

### 1. Fichiers xcconfig

#### Production: `Config.xcconfig`

```
FIREBASE_API_KEY = $(FIREBASE_API_KEY_PROD)
FIREBASE_PROJECT_ID = medistocks-384b0
// ... autres configs
```

#### Test: `Config-Test.xcconfig`

```
FIREBASE_API_KEY = $(FIREBASE_API_KEY_TEST)
FIREBASE_PROJECT_ID = medistock-test
// ... configs de test
```

### 2. Variables d'Environnement

**Dans Xcode**:
1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Ajouter:
   ```
   FIREBASE_API_KEY_PROD = votre_clé_prod
   FIREBASE_API_KEY_TEST = votre_clé_test
   ```

### 3. Configuration dans Info.plist

**Ajouter dans Info.plist**:

```xml
<key>FIREBASE_API_KEY</key>
<string>$(FIREBASE_API_KEY)</string>
<key>FIREBASE_PROJECT_ID</key>
<string>$(FIREBASE_PROJECT_ID)</string>
```

### 4. Chargement Dynamique

Utiliser `FirebaseConfigLoader.swift`:

```swift
// Dans AppDelegate ou App.swift
@main
struct MediStockApp: App {
    init() {
        #if DEBUG
        FirebaseConfigManager.shared.configureForTesting()
        #else
        FirebaseConfigManager.shared.configure(for: .production)
        #endif
    }
}
```

---

## ✅ Tests Unitaires

### Exemple de Test avec Mock

```swift
import XCTest
@testable import MediStock

@MainActor
final class AuthViewModelTests: XCTestCase {
    var viewModel: AuthViewModel!
    var mockAuthService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
    }

    func testSignInSuccess() async throws {
        // Arrange
        let email = "test@example.com"
        let password = "password123"

        // Act
        try await viewModel.signIn(email: email, password: password)

        // Assert
        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertEqual(mockAuthService.lastSignInEmail, email)
        XCTAssertNotNil(mockAuthService.currentUser)
        XCTAssertEqual(viewModel.isAuthenticated, true)
    }

    func testSignInFailure() async {
        // Arrange
        mockAuthService.shouldFailSignIn = true

        // Act & Assert
        do {
            try await viewModel.signIn(email: "test@example.com", password: "wrong")
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
            XCTAssertEqual(viewModel.errorMessage, "Mock sign in failed")
        }
    }
}
```

### Tests de DataService

```swift
@MainActor
final class MedicineViewModelTests: XCTestCase {
    var viewModel: MedicineListViewModel!
    var mockDataService: MockDataService!

    override func setUp() {
        super.setUp()
        mockDataService = MockDataService()
        mockDataService.seedTestData() // Ajoute des données de test
        viewModel = MedicineListViewModel(dataService: mockDataService)
    }

    func testFetchMedicines() async throws {
        // Act
        try await viewModel.fetchMedicines()

        // Assert
        XCTAssertEqual(mockDataService.getMedicinesCallCount, 1)
        XCTAssertEqual(viewModel.medicines.count, 1)
        XCTAssertEqual(viewModel.medicines.first?.name, "Doliprane 500mg")
    }

    func testUpdateStockSuccess() async throws {
        // Arrange
        let medicine = mockDataService.medicines.first!
        let newStock = 50

        // Act
        try await viewModel.updateStock(for: medicine.id, newStock: newStock)

        // Assert
        XCTAssertEqual(mockDataService.updateStockCallCount, 1)
        let updated = mockDataService.medicines.first { $0.id == medicine.id }
        XCTAssertEqual(updated?.currentQuantity, newStock)
    }
}
```

---

## 🔄 Migration du Code Existant

### Étape 1: Mettre à jour AuthService

**Avant**:

```swift
class AuthService: ObservableObject {
    @Published var currentUser: User?
    // ...
}
```

**Après**:

```swift
class FirebaseAuthService: AuthServiceProtocol {
    @Published var currentUser: User?
    // ... même implémentation
}

// Créer un typealias pour rétrocompatibilité
typealias AuthService = FirebaseAuthService
```

### Étape 2: Mettre à jour DataService

**Avant**:

```swift
class DataService {
    private let db = Firestore.firestore()
    // ...
}
```

**Après**:

```swift
class FirebaseDataService: DataServiceProtocol {
    private let db = Firestore.firestore()
    // ... même implémentation
}

typealias DataService = FirebaseDataService
```

### Étape 3: Injection dans ViewModels

**Avant**:

```swift
class MedicineListViewModel: ObservableObject {
    private let dataService = DataService()
}
```

**Après**:

```swift
class MedicineListViewModel: ObservableObject {
    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol = FirebaseDataService()) {
        self.dataService = dataService
    }
}
```

### Étape 4: Mettre à jour les Tests

**Avant**:

```swift
func testExample() {
    let viewModel = MedicineListViewModel()
    // Test échoue car appel Firebase réel
}
```

**Après**:

```swift
func testExample() {
    let mockService = MockDataService()
    mockService.seedTestData()
    let viewModel = MedicineListViewModel(dataService: mockService)
    // Test passe avec données mockées
}
```

---

## 📚 Best Practices

### Sécurité

1. ✅ **Ne jamais committer** les fichiers `Config.xcconfig`
2. ✅ Ajouter `.xcconfig` dans `.gitignore`
3. ✅ Utiliser des **projets Firebase séparés** pour dev/test/prod
4. ✅ Activer les **règles de sécurité Firestore** strictes
5. ✅ Utiliser **Cloud Functions** pour validation côté serveur

### Tests

1. ✅ Toujours injecter les dépendances via le constructeur
2. ✅ Utiliser des mocks pour tous les services externes
3. ✅ Ne jamais appeler Firebase dans les tests unitaires
4. ✅ Créer des tests d'intégration séparés (optionnels)
5. ✅ Mesurer la **couverture de code** (minimum 80%)

### Architecture

1. ✅ Respecter le principe **SOLID** (Single Responsibility)
2. ✅ Utiliser **Protocol-Oriented Programming**
3. ✅ Séparer **logique métier** et **appels API**
4. ✅ Centraliser la **gestion d'erreurs**
5. ✅ Documenter les **protocoles** et interfaces publiques

### Firebase

1. ✅ Utiliser **Firebase Emulators** pour développement local
2. ✅ Implémenter **retry logic** pour erreurs réseau
3. ✅ Gérer **offline persistence** Firestore
4. ✅ Optimiser les **requêtes** avec indexes
5. ✅ Monitorer les **coûts** avec Firebase Console

---

## 🚀 Prochaines Étapes

### Immédiat

1. [ ] Créer un projet Firebase de test séparé
2. [ ] Configurer les variables d'environnement Xcode
3. [ ] Migrer `AuthService` vers `FirebaseAuthService`
4. [ ] Migrer `DataService` vers `FirebaseDataService`
5. [ ] Mettre à jour tous les ViewModels avec injection

### Court Terme

1. [ ] Écrire tests unitaires pour tous les ViewModels
2. [ ] Configurer Firebase Emulators pour dev local
3. [ ] Implémenter gestion d'erreurs centralisée
4. [ ] Ajouter logging pour debugging
5. [ ] Documenter l'API avec commentaires Swift

### Long Terme

1. [ ] Implémenter Cloud Functions pour validation
2. [ ] Ajouter CI/CD pour tests automatiques
3. [ ] Configurer Firebase App Distribution
4. [ ] Monitorer performances avec Firebase Performance
5. [ ] Implémenter analytics avec Firebase Analytics

---

## 📞 Support

### Ressources

- [Documentation Firebase iOS](https://firebase.google.com/docs/ios/setup)
- [Protocol-Oriented Programming Guide](https://developer.apple.com/videos/play/wwdc2015/408/)
- [SwiftUI Testing Best Practices](https://developer.apple.com/documentation/xctest)

### Problèmes Courants

#### "Firebase not configured"

**Solution**: Vérifier que `FirebaseConfigManager.shared.configure()` est appelé dans `@main`

#### "API Key not valid"

**Solution**: Vérifier les variables d'environnement dans le scheme Xcode

#### "Tests fail with network error"

**Solution**: S'assurer d'utiliser les mocks dans les tests unitaires

---

## ✨ Conclusion

Cette solution propose une **architecture MVVM propre, testable et sécurisée** qui:

✅ Protège l'API Key Firebase
✅ Permet des tests unitaires rapides et fiables
✅ Facilite la maintenance et l'évolution
✅ Respecte les principes SOLID et Protocol-Oriented
✅ Sépare clairement les environnements dev/test/prod

**Temps de migration estimé**: 2-3 jours pour l'ensemble du projet.

**Bénéfices à long terme**:
- Tests 10x plus rapides
- Couverture de code > 80%
- Sécurité renforcée
- Flexibilité accrue
- Maintenance simplifiée

---

*Document créé le 13 octobre 2025*
*Architecture conforme aux guidelines Apple et principes MVVM*
