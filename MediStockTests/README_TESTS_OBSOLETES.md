# Tests obsolètes à refactoriser

## Contexte
Suite à la migration vers les services modulaires (MedicineDataService, AisleDataService, HistoryDataService),
la classe `DataServiceAdapter` a été supprimée.

## Tests affectés
Les tests suivants utilisent `MockDataServiceAdapter` et doivent être refactorisés pour utiliser
les nouveaux services modulaires:

- `MediStockTests/Mocks/MockDataServiceAdapter.swift`
- `MediStockTests/Mocks/MockDataServiceAdapterForIntegration.swift`
- Tous les tests qui importent ces mocks

## Action nécessaire
Ces tests ont été temporairement désactivés pour permettre le merge de la branche feature/modular-services-migration.

**TODO**: Refactoriser ces tests pour utiliser les nouveaux services modulaires :
- MockMedicineDataService
- MockAisleDataService  
- MockHistoryDataService

## Date
2025-10-25
