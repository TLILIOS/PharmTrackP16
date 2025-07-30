# Guide de migration vers DataServiceRefactored

## 🚀 Migration court terme - Checklist

### ✅ Étape 1 : Intégration du service refactorisé (FAIT)
- [x] Remplacer `DataService` par `DataServiceRefactored` dans `DependencyContainer`
- [x] Mettre à jour `AppState` pour utiliser `DataServiceRefactored`
- [x] Adapter tous les repositories (Medicine, Aisle, History)
- [x] Ajouter les extensions pour gérer les `ValidationError`

### ✅ Étape 2 : Tests de validation
Exécuter les commandes suivantes pour valider l'intégration :

```bash
# Tests unitaires de validation
xcodebuild test -project MediStock.xcodeproj -scheme MediStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:MediStockTests/RefactoredFunctionsTests

# Tests d'intégration des workflows
xcodebuild test -project MediStock.xcodeproj -scheme MediStock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:MediStockTests/ValidationIntegrationTests
```

### ✅ Étape 3 : Gestion des erreurs dans l'UI

#### Utiliser les helpers de validation dans vos vues :

```swift
struct MedicineFormView: View {
    @State private var validationError: ValidationError?
    @State private var toastMessage: ToastMessage?
    
    var body: some View {
        Form {
            // Votre formulaire...
        }
        .validationErrorAlert(error: $validationError)
        .toast(message: $toastMessage)
    }
    
    func saveMedicine() async {
        do {
            let saved = try await dataService.saveMedicine(medicine)
            toastMessage = ToastMessage(message: "Médicament enregistré", isError: false)
        } catch let error as ValidationError {
            validationError = error
        } catch {
            toastMessage = ToastMessage(message: error.localizedDescription, isError: true)
        }
    }
}
```

## 🛡️ Migration moyen terme - Backend

### Étape 4 : Déployer les Cloud Functions

```bash
cd MediStock/CloudFunctions
npm install
firebase login
firebase init functions
firebase deploy --only functions
```

### Étape 5 : Déployer les règles Firestore

```bash
firebase deploy --only firestore:rules
```

### Étape 6 : Tester la sécurité

Utilisez le Firebase Emulator pour tester les règles :

```bash
firebase emulators:start --only firestore
# Exécuter les tests de sécurité
npm test
```

## 📊 Migration long terme - Données

### Étape 7 : Script de migration des données

```javascript
// Script pour migrer les données existantes
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

async function migrateAisles() {
  const aisles = await db.collection('aisles').get();
  const batch = db.batch();
  
  aisles.forEach(doc => {
    const data = doc.data();
    // Ajouter les timestamps manquants
    if (!data.createdAt) {
      batch.update(doc.ref, {
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });
  
  await batch.commit();
  console.log('Aisles migrated successfully');
}

async function validateMedicines() {
  const medicines = await db.collection('medicines').get();
  const issues = [];
  
  medicines.forEach(doc => {
    const data = doc.data();
    // Vérifier les incohérences
    if (data.criticalThreshold >= data.warningThreshold) {
      issues.push({
        id: doc.id,
        issue: 'Invalid thresholds',
        data: data
      });
    }
    if (data.currentQuantity < 0) {
      issues.push({
        id: doc.id,
        issue: 'Negative quantity',
        data: data
      });
    }
  });
  
  console.log('Found', issues.length, 'issues');
  return issues;
}

// Exécuter les migrations
migrateAisles().then(() => validateMedicines());
```

## ⚠️ Points d'attention

### Gestion des erreurs de validation

Les `ValidationError` sont maintenant localisées et user-friendly. Assurez-vous de :
- Ne pas wrapper ces erreurs dans d'autres messages
- Les afficher directement à l'utilisateur
- Utiliser les helpers fournis (`validationErrorAlert`, `toast`)

### Breaking changes

1. **Timestamps obligatoires** : Les rayons ont maintenant `createdAt` et `updatedAt`
2. **Validation stricte** : Les données invalides sont rejetées
3. **Unicité des noms** : Les noms de rayons doivent être uniques par utilisateur

### Performance

- Les transactions ajoutent ~50-100ms de latence
- La validation est quasi-instantanée (<1ms)
- Les vérifications d'unicité nécessitent une requête supplémentaire

## 📝 Exemples de code

### Créer un rayon avec gestion d'erreur

```swift
func createAisle() async {
    let newAisle = Aisle(
        id: "",
        name: aisleName.trimmingCharacters(in: .whitespacesAndNewlines),
        description: aisleDescription,
        colorHex: selectedColor.toHex(),
        icon: selectedIcon
    )
    
    do {
        let saved = try await dataService.saveAisle(newAisle)
        print("Rayon créé avec succès : \(saved.id)")
        dismiss()
    } catch ValidationError.emptyName {
        showError("Le nom du rayon est obligatoire")
    } catch ValidationError.nameAlreadyExists(let name) {
        showError("Un rayon '\(name)' existe déjà")
    } catch ValidationError.invalidColorFormat {
        showError("Couleur invalide")
    } catch {
        showError("Erreur : \(error.localizedDescription)")
    }
}
```

### Ajuster le stock avec validation

```swift
func adjustStock(medicine: Medicine, adjustment: Int) async {
    do {
        let newStock = max(0, medicine.currentQuantity + adjustment)
        let updated = try await dataService.updateMedicineStock(
            id: medicine.id,
            newStock: newStock
        )
        print("Stock mis à jour : \(updated.currentQuantity)")
    } catch ValidationError.negativeQuantity {
        showError("La quantité ne peut pas être négative")
    } catch {
        showError("Erreur : \(error.localizedDescription)")
    }
}
```

## 🎯 Métriques de succès

- [ ] 0 erreur de validation en production après 1 semaine
- [ ] 100% des sauvegardes passent par validation
- [ ] Temps de réponse < 1s pour 95% des requêtes
- [ ] Aucune donnée invalide en base

## 📞 Support

En cas de problème :
1. Vérifier les logs Firebase
2. Consulter `REFACTORING_IMPLEMENTATION_GUIDE.md`
3. Contacter l'équipe backend pour les Cloud Functions

---

Dernière mise à jour : [Date]
Version : 1.0