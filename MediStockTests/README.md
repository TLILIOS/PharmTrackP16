# Tests MediStock - Documentation Complète

**Auteur:** TLILI HAMDI
**Dernière mise à jour:** 28 octobre 2025

---

## 🚀 Démarrage Rapide

### Exécuter les tests unitaires (rapide - ~10s)
```bash
UNIT_TESTS_ONLY=1 ./Scripts/run_unit_tests.sh
```

### Depuis Xcode
1. Sélectionner le scheme `MediStock-UnitTests`
2. Appuyer sur `Cmd+U`

---

## 📁 Structure des Tests

```
MediStockTests/
├── ViewModels/         # Tests des ViewModels (ACTIF)
├── Repositories/       # Tests des Repositories (ACTIF)
├── Services/           # Tests des Services (ACTIF)
├── Mocks/              # Mocks réutilisables (ACTIF)
├── Core/               # Tests des patterns et bases
├── Examples/           # Exemples de tests
└── BaseTestCase.swift  # Classe de base pour tous les tests
```

---

## ✅ Architecture Modulaire (Migration terminée - 25 octobre 2025)

### Contexte
Suite à la migration vers les services modulaires (MedicineDataService, AisleDataService, HistoryDataService),
les anciens mocks unifiés ont été remplacés par des services spécialisés conformes au principe SOLID.

### Nouveaux Mocks Disponibles

#### 1. MockMedicineDataService
Simule `MedicineDataService` pour les tests de gestion des médicaments.

**Méthodes principales:**
- `getAllMedicines()` - Récupère tous les médicaments
- `getMedicinesPaginated(limit:refresh:)` - Récupération paginée
- `getMedicine(by:)` - Récupère un médicament par ID
- `saveMedicine(_:)` - Sauvegarde/met à jour un médicament
- `deleteMedicine(_:)` - Supprime un médicament
- `updateMedicineStock(id:newStock:)` - Met à jour le stock
- `adjustStock(medicineId:adjustment:)` - Ajuste le stock (+/-)
- `createMedicinesListener(completion:)` - Listener temps réel

**Configuration des tests:**
```swift
let mockMedicineService = MockMedicineDataService()
mockMedicineService.seedTestData() // Ajoute des données de test
mockMedicineService.configureFailures(getMedicines: true) // Simule une erreur
```

#### 2. MockAisleDataService
Simule `AisleDataService` pour les tests de gestion des rayons.

**Méthodes principales:**
- `getAllAisles()` - Récupère tous les rayons
- `getAislesPaginated(limit:refresh:)` - Récupération paginée
- `getAisle(by:)` - Récupère un rayon par ID
- `checkAisleExists(_:)` - Vérifie l'existence d'un rayon
- `saveAisle(_:)` - Sauvegarde/met à jour un rayon
- `deleteAisle(_:)` - Supprime un rayon
- `countMedicinesInAisle(_:)` - Compte les médicaments dans un rayon
- `createAislesListener(completion:)` - Listener temps réel

**Configuration des tests:**
```swift
let mockAisleService = MockAisleDataService()
mockAisleService.seedTestData() // Ajoute des rayons de test
mockAisleService.setMedicineCount(for: "aisle-1", count: 5) // Configure le compte
```

#### 3. MockHistoryDataService
Simule `HistoryDataService` pour les tests d'historique.

**Méthodes principales:**
- `getHistory(medicineId:startDate:endDate:limit:)` - Récupère l'historique
- `recordMedicineAction(medicineId:medicineName:action:details:)` - Enregistre action médicament
- `recordAisleAction(aisleId:aisleName:action:details:)` - Enregistre action rayon
- `recordStockAdjustment(medicineId:medicineName:adjustment:newStock:details:)` - Enregistre ajustement
- `recordDeletion(itemType:itemId:itemName:details:)` - Enregistre suppression
- `getHistoryStats(days:)` - Récupère les statistiques

**Configuration des tests:**
```swift
let mockHistoryService = MockHistoryDataService()
mockHistoryService.seedTestData() // Ajoute des entrées d'historique
```

---

## 📝 Guide de Migration

### Exemple: Migrer un test de ViewModel

**Après (architecture modulaire actuelle):**
```swift
class MedicineListViewModelTests: XCTestCase {
    var viewModel: MedicineListViewModel!
    var mockMedicineService: MockMedicineDataService!
    var mockAisleService: MockAisleDataService!
    var mockHistoryService: MockHistoryDataService!

    override func setUp() {
        // Créer les mocks
        mockHistoryService = MockHistoryDataService()
        mockMedicineService = MockMedicineDataService(historyService: mockHistoryService)
        mockAisleService = MockAisleDataService(historyService: mockHistoryService)

        // Seed data
        mockAisleService.seedTestData() // Rayons d'abord
        mockMedicineService.seedTestData(aisleId: "aisle-1") // Puis médicaments

        // Créer le ViewModel avec injection des services
        let repository = MedicineRepository(medicineService: mockMedicineService)
        viewModel = MedicineListViewModel(
            medicineRepository: repository,
            notificationService: NotificationService()
        )
    }

    func testFetchMedicines() async throws {
        viewModel.startListening()

        await Task.yield() // Laisser le temps au listener de s'initialiser

        XCTAssertEqual(viewModel.medicines.count, 1)
        XCTAssertEqual(mockMedicineService.getAllMedicinesCallCount, 1)
    }
}
```

### Checklist pour migrer un test existant

1. **Changer l'héritage (optionnel)**
   ```swift
   // Avant
   class MyTest: XCTestCase {

   // Après (si vous avez besoin des helpers)
   class MyTest: BaseTestCase {
   ```

2. **Utiliser les nouveaux mocks modulaires**
   ```swift
   let mockMedicineService = MockMedicineDataService()
   let mockAisleService = MockAisleDataService()
   let mockHistoryService = MockHistoryDataService()
   ```

3. **Utiliser les helpers de BaseTestCase**
   ```swift
   // Créer des mocks facilement
   let repo = createMockMedicineRepository()

   // Attendre async avec timeout
   await waitForAsync(timeout: 3) {
       try await viewModel.loadData()
   }
   ```

---

## 🎯 Compteurs de Calls (Vérification des Appels)

Chaque mock expose des compteurs pour vérifier les appels dans les tests:

### MockMedicineDataService
- `getAllMedicinesCallCount`
- `getMedicinesPaginatedCallCount`
- `getMedicineCallCount`
- `saveMedicineCallCount`
- `updateStockCallCount`
- `deleteMedicineCallCount`
- `adjustStockCallCount`

### MockAisleDataService
- `getAllAislesCallCount`
- `getAislesPaginatedCallCount`
- `getAisleCallCount`
- `checkAisleExistsCallCount`
- `saveAisleCallCount`
- `deleteAisleCallCount`
- `countMedicinesInAisleCallCount`

### MockHistoryDataService
- `getHistoryCallCount`
- `recordMedicineActionCallCount`
- `recordAisleActionCallCount`
- `recordStockAdjustmentCallCount`
- `recordDeletionCallCount`
- `getHistoryStatsCallCount`

---

## 🔥 Problèmes Courants et Solutions

### "Cannot find type 'ValidationError'"
→ Ajouter `import Combine` en haut du fichier

### Tests timeout après 2 minutes
→ Vérifier que `UNIT_TESTS_ONLY=1` est défini
→ Utiliser les mocks au lieu de Firebase

### "Firebase not configured"
→ Normal en mode unit test, Firebase est désactivé
→ Utiliser les mocks pour simuler les données

### Listener ne reçoit pas les données
→ Utiliser `await Task.yield()` après `startListening()` pour laisser le temps au listener de s'initialiser

---

## 📊 Métriques de Performance

- **Tests unitaires:** < 30 secondes total
- **Tests d'intégration:** 2-5 minutes
- **Couverture cible:** 80%+

---

## 🛠️ Commandes Utiles

```bash
# Tests unitaires seulement
./Scripts/run_unit_tests.sh

# Tests d'intégration
./Scripts/run_integration_tests.sh

# Tous les tests
./Scripts/run_all_tests.sh

# Nettoyer et reconstruire
rm -rf ~/Library/Developer/Xcode/DerivedData
```

---

## ✨ Avantages de l'Architecture Modulaire

1. **Séparation des responsabilités** - Chaque mock gère un domaine spécifique
2. **Tests plus ciblés** - Vous pouvez tester chaque service indépendamment
3. **Meilleure lisibilité** - Code plus clair et explicite
4. **Flexibilité** - Facile de configurer des scénarios de test complexes
5. **Conformité SOLID** - Respect du Single Responsibility Principle

---

## 📅 Historique des Migrations

- **25 octobre 2025:** Migration vers les services modulaires terminée
- **Mocks créés:** MockMedicineDataService, MockAisleDataService, MockHistoryDataService
- **Ancien code supprimé:** DataServiceAdapter, MockDataService, tests désactivés

---

**Document maintenu par:** TLILI HAMDI
**Pour toute question:** Consulter les exemples dans `MediStockTests/Examples/`
