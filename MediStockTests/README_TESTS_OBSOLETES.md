# Migration vers les services modulaires - Guide complet

## ✅ Statut: Migration terminée (2025-10-25)

## Contexte
Suite à la migration vers les services modulaires (MedicineDataService, AisleDataService, HistoryDataService),
la classe `DataServiceAdapter` et `MockDataService` ont été remplacées par des services spécialisés.

## Nouveaux Mocks Disponibles

Les mocks suivants sont maintenant disponibles dans `MediStockTests/Mocks/`:

### 1. MockMedicineDataService
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

### 2. MockAisleDataService
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

### 3. MockHistoryDataService
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

## Guide de Migration

### Exemple: Migrer un test de MedicineListViewModel

**Avant (avec MockDataService):**
```swift
class MedicineListViewModelTests: XCTestCase {
    var viewModel: MedicineListViewModel!
    var mockDataService: MockDataService!

    override func setUp() {
        mockDataService = MockDataService()
        mockDataService.seedTestData()
        viewModel = MedicineListViewModel(dataService: mockDataService)
    }

    func testFetchMedicines() async throws {
        try await viewModel.fetchMedicines()
        XCTAssertEqual(viewModel.medicines.count, 1)
    }
}
```

**Après (avec MockMedicineDataService):**
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
        viewModel = MedicineListViewModel(
            medicineService: mockMedicineService,
            aisleService: mockAisleService,
            historyService: mockHistoryService
        )
    }

    func testFetchMedicines() async throws {
        try await viewModel.fetchMedicines()
        XCTAssertEqual(viewModel.medicines.count, 1)
        XCTAssertEqual(mockMedicineService.getAllMedicinesCallCount, 1)
    }
}
```

## Avantages de la nouvelle architecture

1. **Séparation des responsabilités** - Chaque mock gère un domaine spécifique
2. **Tests plus ciblés** - Vous pouvez tester chaque service indépendamment
3. **Meilleure lisibilité** - Code plus clair et explicite
4. **Flexibilité** - Facile de configurer des scénarios de test complexes
5. **Conformité SOLID** - Respect du Single Responsibility Principle

## Compteurs de calls disponibles

Chaque mock expose des compteurs pour vérifier les appels:

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

## Fichiers obsolètes (désactivés)

Les fichiers suivants ont été désactivés (.disabled) et peuvent être supprimés après vérification:

- `MediStockTests/Mocks/MockDataServiceAdapter.swift.disabled`
- `MediStockTests/Mocks/MockDataServiceAdapterForIntegration.swift.disabled`
- `MediStockTests/Mocks/MockDataService.swift` (peut être conservé temporairement comme référence)

## Prochaines étapes

1. ✅ Nouveaux mocks créés
2. ⏳ Migrer les tests existants pour utiliser les nouveaux mocks
3. ⏳ Mettre à jour les ViewModels/Repositories pour accepter l'injection des services modulaires
4. ⏳ Supprimer les anciens mocks une fois la migration terminée
5. ⏳ Supprimer la branche `feature/modular-services-migration`

## Date de migration
- Début: 2025-10-25
- Fin: 2025-10-25
- Mocks créés: MockMedicineDataService, MockAisleDataService, MockHistoryDataService
