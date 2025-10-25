# Tests MediStock - Guide Rapide

## 🚀 Démarrage Rapide

### Exécuter les tests unitaires (rapide - ~10s)
```bash
UNIT_TESTS_ONLY=1 ./Scripts/run_unit_tests.sh
```

### Depuis Xcode
1. Sélectionner le scheme `MediStock-UnitTests`
2. Appuyer sur `Cmd+U`

## 📁 Structure des Tests

```
MediStockTests/
├── UnitTests/          # Tests rapides sans dépendances
├── IntegrationTests/   # Tests avec Firebase
├── PerformanceTests/   # Tests de performance
├── Mocks/              # Mocks réutilisables
└── BaseTestCase.swift  # Classe de base
```

## ✅ Checklist Migration

### Pour migrer un test existant :

1. **Changer l'héritage**
   ```swift
   // Avant
   class MyTest: XCTestCase {
   
   // Après
   class MyTest: BaseTestCase {
   ```

2. **Remplacer le DataService**
   ```swift
   // Avant
   let service = FirebaseDataService()
   
   // Après
   let service = MockDataServiceAdapter()
   service.configure(medicines: TestData.mockMedicines)
   ```

3. **Supprimer cancellables**
   ```swift
   // Supprimer cette ligne (déjà dans BaseTestCase)
   var cancellables: Set<AnyCancellable>!
   ```

4. **Utiliser les helpers**
   ```swift
   // Créer des mocks facilement
   let repo = createMockMedicineRepository()
   
   // Attendre async avec timeout
   await waitForAsync(timeout: 3) {
       try await viewModel.loadData()
   }
   ```

## 🔥 Problèmes Courants

### "Cannot find type 'ValidationError'"
→ Ajouter `import Combine` en haut du fichier

### Tests timeout après 2 minutes
→ Vérifier que `UNIT_TESTS_ONLY=1` est défini
→ Utiliser MockDataServiceAdapter au lieu de Firebase

### "Firebase not configured"
→ Normal en mode unit test, Firebase est désactivé
→ Utiliser les mocks pour simuler les données

## 📊 Métriques

- **Tests unitaires :** < 30 secondes total
- **Tests d'intégration :** 2-5 minutes
- **Couverture cible :** 80%+

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