# Guide de Migration - Architecture Testable avec Mocks

## 🎯 Objectif

Migrer le projet MediStock d'une architecture couplée à Firebase vers une architecture MVVM testable avec injection de dépendances et mocks.

---

## ⏱️ Temps Estimé

- **Total**: 2-3 jours
- **Étape 1-3**: 4 heures
- **Étape 4-5**: 1 jour
- **Étape 6-7**: 1 jour
- **Tests**: 4 heures

---

## 📋 Checklist de Migration

### Phase 1: Préparation (1 heure)

- [ ] Lire la documentation complète (`SOLUTION-APIS-FIREBASE.md`)
- [ ] Créer une branche Git: `git checkout -b feature/testable-architecture`
- [ ] Faire un backup du projet actuel
- [ ] Créer un projet Firebase de test séparé

### Phase 2: Configuration Sécurité (1 heure)

- [ ] Ajouter les fichiers de config au `.gitignore` ✅ (Déjà fait)
- [ ] Créer les variables d'environnement dans Xcode
- [ ] Configurer les schemes (Debug/Release/Test)
- [ ] Tester le chargement de configuration

### Phase 3: Création des Protocoles (30 minutes)

- [ ] Ajouter `AuthServiceProtocol.swift` au projet ✅ (Déjà créé)
- [ ] Ajouter `DataServiceProtocol.swift` au projet ✅ (Déjà créé)
- [ ] Compiler pour vérifier les erreurs

### Phase 4: Migration des Services (2 heures)

- [ ] Renommer `AuthService` → `FirebaseAuthService`
- [ ] Implémenter `AuthServiceProtocol` dans `FirebaseAuthService`
- [ ] Renommer `DataService` → `FirebaseDataService`
- [ ] Implémenter `DataServiceProtocol` dans `FirebaseDataService`
- [ ] Créer des typealias pour rétrocompatibilité

### Phase 5: Création des Mocks (30 minutes)

- [ ] Ajouter `MockAuthService.swift` aux tests ✅ (Déjà créé)
- [ ] Ajouter `MockDataService.swift` aux tests ✅ (Déjà créé)
- [ ] Compiler les tests pour vérifier

### Phase 6: Migration des ViewModels (1 jour)

Pour **chaque ViewModel**:

- [ ] `AuthViewModel`
  - [ ] Ajouter propriété `authService: AuthServiceProtocol`
  - [ ] Ajouter initializer avec injection
  - [ ] Remplacer appels directs par appels via protocole
  - [ ] Créer tests unitaires avec mock

- [ ] `MedicineListViewModel`
  - [ ] Ajouter propriété `dataService: DataServiceProtocol`
  - [ ] Ajouter initializer avec injection
  - [ ] Remplacer appels directs par appels via protocole
  - [ ] Créer tests unitaires avec mock

- [ ] `AisleListViewModel`
  - [ ] Ajouter propriété `dataService: DataServiceProtocol`
  - [ ] Ajouter initializer avec injection
  - [ ] Remplacer appels directs par appels via protocole
  - [ ] Créer tests unitaires avec mock

- [ ] `HistoryViewModel`
  - [ ] Ajouter propriété `dataService: DataServiceProtocol`
  - [ ] Ajouter initializer avec injection
  - [ ] Remplacer appels directs par appels via protocole
  - [ ] Créer tests unitaires avec mock

### Phase 7: Migration des Tests (1 jour)

- [ ] Supprimer les tests d'intégration Firebase (ou les marquer comme optionnels)
- [ ] Créer tests unitaires pour tous les ViewModels
- [ ] Créer tests unitaires pour les Repositories
- [ ] Vérifier la couverture de code (objectif: >80%)

### Phase 8: Configuration Firebase (1 heure)

- [ ] Intégrer `FirebaseConfigLoader.swift` ✅ (Déjà créé)
- [ ] Mettre à jour `@main App` pour utiliser le config manager
- [ ] Tester en Debug (mocks)
- [ ] Tester en Release (Firebase réel)

### Phase 9: Validation (2 heures)

- [ ] Exécuter tous les tests unitaires (doivent passer à 100%)
- [ ] Tester l'app en mode Debug
- [ ] Tester l'app en mode Release
- [ ] Vérifier les performances
- [ ] Code review

### Phase 10: Déploiement (30 minutes)

- [ ] Créer une Pull Request
- [ ] Documenter les changements
- [ ] Merger dans main après validation
- [ ] Créer un tag de version

---

## 🔧 Instructions Détaillées

### Étape 1: Configuration des Variables d'Environnement

**Dans Xcode**:

1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Ajouter:

```
FIREBASE_API_KEY_PROD = [Votre clé production]
FIREBASE_API_KEY_TEST = [Votre clé test]
```

4. Répéter pour Test et Release schemes

### Étape 2: Migration d'un Service

**Avant** (`AuthService.swift`):

```swift
import FirebaseAuth

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?

    func signIn(email: String, password: String) async throws {
        // Implémentation Firebase
    }
}
```

**Après** (`FirebaseAuthService.swift`):

```swift
import FirebaseAuth

@MainActor
class FirebaseAuthService: AuthServiceProtocol {
    @Published var currentUser: User?

    // Garder la même implémentation
    func signIn(email: String, password: String) async throws {
        // Même code qu'avant
    }
}

// Rétrocompatibilité
typealias AuthService = FirebaseAuthService
```

### Étape 3: Migration d'un ViewModel

**Avant**:

```swift
@Observable
class MedicineListViewModel {
    var medicines: [Medicine] = []
    private let dataService = DataService()

    func loadMedicines() async throws {
        medicines = try await dataService.getMedicines()
    }
}
```

**Après**:

```swift
@Observable
class MedicineListViewModel {
    var medicines: [Medicine] = []
    private let dataService: DataServiceProtocol

    // Injection de dépendances avec valeur par défaut
    init(dataService: DataServiceProtocol = FirebaseDataService()) {
        self.dataService = dataService
    }

    func loadMedicines() async throws {
        medicines = try await dataService.getMedicines()
    }
}
```

### Étape 4: Création d'un Test Unitaire

**Nouveau fichier**: `MedicineListViewModelTests.swift`

```swift
import XCTest
@testable import MediStock

@MainActor
final class MedicineListViewModelTests: XCTestCase {
    var viewModel: MedicineListViewModel!
    var mockDataService: MockDataService!

    override func setUp() {
        super.setUp()
        mockDataService = MockDataService()
        mockDataService.seedTestData()
        viewModel = MedicineListViewModel(dataService: mockDataService)
    }

    override func tearDown() {
        viewModel = nil
        mockDataService = nil
        super.tearDown()
    }

    func testLoadMedicinesSuccess() async throws {
        // When
        try await viewModel.loadMedicines()

        // Then
        XCTAssertEqual(viewModel.medicines.count, 1)
        XCTAssertEqual(mockDataService.getMedicinesCallCount, 1)
    }
}
```

### Étape 5: Configuration de l'App

**Mettre à jour** `MediStockApp.swift`:

```swift
import SwiftUI
import FirebaseCore

@main
struct MediStockApp: App {

    init() {
        configureFirebase()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(createAuthService())
        }
    }

    private func configureFirebase() {
        #if DEBUG
        // En mode Debug, utiliser les mocks ou l'émulateur
        FirebaseConfigManager.shared.configureForTesting()
        #else
        // En mode Release, utiliser Firebase production
        FirebaseConfigManager.shared.configure(for: .production)
        #endif
    }

    private func createAuthService() -> FirebaseAuthService {
        return FirebaseAuthService()
    }
}
```

---

## 🧪 Validation des Tests

### Commandes Terminal

```bash
# Exécuter tous les tests
xcodebuild test -scheme MediStock -destination 'platform=iOS Simulator,name=iPhone 15'

# Mesurer la couverture de code
xcodebuild test -scheme MediStock -enableCodeCoverage YES

# Tests uniquement (rapide)
xcodebuild test -scheme MediStockTests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Vérifier la Couverture

1. Product → Test (⌘U)
2. Report Navigator (⌘9)
3. Coverage tab
4. Vérifier: ViewModels > 80%, Repositories > 80%

---

## ⚠️ Points d'Attention

### Erreurs Courantes

#### 1. "Cannot find 'AuthServiceProtocol' in scope"

**Solution**: Vérifier que les protocoles sont dans le target principal

#### 2. "Type 'FirebaseAuthService' does not conform to protocol 'AuthServiceProtocol'"

**Solution**: Implémenter toutes les méthodes du protocole

#### 3. Tests qui échouent avec "Firebase not configured"

**Solution**: Utiliser les mocks dans les tests, pas FirebaseService

#### 4. "Ambiguous use of 'authService'"

**Solution**: Spécifier le type explicitement

```swift
private let authService: AuthServiceProtocol
```

### Bonnes Pratiques

✅ **Faire** un commit après chaque étape validée
✅ **Tester** fréquemment pendant la migration
✅ **Documenter** les changements non évidents
✅ **Demander** un code review avant le merge

❌ **Ne pas** tout migrer d'un coup
❌ **Ne pas** skipper les tests
❌ **Ne pas** committer les API keys
❌ **Ne pas** casser la compatibilité existante

---

## 🚀 Après la Migration

### Tests de Non-Régression

1. [ ] Tester toutes les fonctionnalités principales
2. [ ] Vérifier l'authentification (sign in/out)
3. [ ] Vérifier CRUD médicaments
4. [ ] Vérifier CRUD rayons
5. [ ] Vérifier historique
6. [ ] Tester sur device réel
7. [ ] Tester en mode offline

### Optimisations Futures

- [ ] Configurer Firebase Emulators pour dev local
- [ ] Ajouter retry logic pour erreurs réseau
- [ ] Implémenter cache local
- [ ] Ajouter analytics pour suivre les erreurs
- [ ] Configurer CI/CD pour tests automatiques

---

## 📞 Aide & Support

### Ressources

- Documentation complète: `SOLUTION-APIS-FIREBASE.md`
- Exemples de tests: `ExampleMigratedViewModelTest.swift`
- Mocks: `MediStockTests/Mocks/`

### Questions Fréquentes

**Q: Dois-je supprimer les anciens tests d'intégration Firebase?**
R: Non, vous pouvez les garder mais les marquer comme optionnels ou les déplacer dans un groupe séparé.

**Q: Comment tester avec Firebase réel occasionnellement?**
R: Créer un scheme "Integration" qui utilise FirebaseService au lieu des mocks.

**Q: Que faire si un test échoue après migration?**
R: Vérifier que vous utilisez bien le mock et pas le service réel.

**Q: Faut-il migrer tous les ViewModels en même temps?**
R: Non, migrez-les un par un et testez après chaque migration.

---

## ✅ Validation Finale

Avant de marquer la migration comme terminée:

- [ ] ✅ Tous les tests unitaires passent
- [ ] ✅ Couverture de code > 80%
- [ ] ✅ Aucune API key dans le code source
- [ ] ✅ L'app fonctionne en Debug et Release
- [ ] ✅ Documentation à jour
- [ ] ✅ Code review effectué
- [ ] ✅ Pull Request mergée

**Félicitations! Votre projet est maintenant testable et sécurisé! 🎉**

---

*Guide créé le 15 octobre 2025*
*Compatible avec Swift 6.0 et SwiftUI*
