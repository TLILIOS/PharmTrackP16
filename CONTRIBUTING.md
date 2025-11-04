# Guide de Contribution - MediStock

Merci de contribuer à MediStock ! Ce document fournit les guidelines pour contribuer efficacement au projet.

**Auteur:** TLILI HAMDI

---

## 📋 Table des Matières

- [Code de Conduite](#code-de-conduite)
- [Comment Contribuer](#comment-contribuer)
- [Standards de Code](#standards-de-code)
- [Workflow Git](#workflow-git)
- [Pull Requests](#pull-requests)
- [Tests](#tests)
- [Documentation](#documentation)
- [Rapporter un Bug](#rapporter-un-bug)
- [Proposer une Fonctionnalité](#proposer-une-fonctionnalité)

---

## 🤝 Code de Conduite

### Nos Engagements

- Respect et bienveillance envers tous les contributeurs
- Accueil des perspectives et expériences diverses
- Acceptation constructive des critiques
- Focus sur l'intérêt du projet et de la communauté

### Comportements Inacceptables

- Langage ou imagerie à caractère sexuel
- Trolling, commentaires insultants ou attaques personnelles
- Harcèlement public ou privé
- Publication d'informations privées sans permission

### Application

Les violations du code de conduite peuvent être signalées à tlilihamdi@example.com. Toutes les plaintes seront examinées et traiteront de manière appropriée.

---

## 🚀 Comment Contribuer

### 1. Fork & Clone

```bash
# Fork le repository sur GitHub
# Puis clonez votre fork
git clone https://github.com/YOUR_USERNAME/MediStock.git
cd MediStock

# Ajoutez le repository original comme remote
git remote add upstream https://github.com/ORIGINAL_OWNER/MediStock.git
```

### 2. Créer une Branche

```bash
# Synchronisez avec upstream
git fetch upstream
git checkout main
git merge upstream/main

# Créez une branche feature
git checkout -b feature/amazing-feature

# Ou pour un bugfix
git checkout -b fix/bug-description
```

### 3. Développer

- Suivez les [Standards de Code](#standards-de-code)
- Écrivez des tests pour votre code
- Documentez les fonctions publiques
- Testez localement avant de commit

### 4. Commit

```bash
# Ajoutez vos changements
git add .

# Commit avec message conventionnel
git commit -m "feat: Add amazing feature"

# Push vers votre fork
git push origin feature/amazing-feature
```

### 5. Pull Request

Ouvrez une Pull Request depuis votre fork vers `main` du repository original.

---

## 📐 Standards de Code

### Architecture MVVM Stricte

```swift
// ✅ BIEN - ViewModel avec @MainActor
@MainActor
class MedicineListViewModel: ObservableObject {
    @Published private(set) var medicines: [Medicine] = []

    private let repository: MedicineRepositoryProtocol

    init(repository: MedicineRepositoryProtocol) {
        self.repository = repository
    }

    func loadMedicines() async {
        // Logique de présentation uniquement
    }
}

// ❌ MAL - Logique métier dans le ViewModel
class BadViewModel: ObservableObject {
    func saveMedicine() {
        // Accès direct Firebase - NON !
        Firestore.firestore().collection("medicines").addDocument(...)
    }
}
```

### Injection de Dépendances

```swift
// ✅ BIEN - Injection par constructeur
init(
    repository: MedicineRepositoryProtocol,
    networkMonitor: NetworkMonitorProtocol
) {
    self.repository = repository
    self.networkMonitor = networkMonitor
}

// ❌ MAL - Dépendances hardcodées
init() {
    self.repository = MedicineRepository() // Couplage fort !
}
```

### Gestion d'Erreurs

```swift
// ✅ BIEN - Erreurs typées et do-catch
enum MedicineError: LocalizedError {
    case invalidData
    case networkError
}

func loadMedicines() async {
    do {
        medicines = try await repository.fetchMedicines()
    } catch {
        handleError(error)
    }
}

// ❌ MAL - Force try ou force unwrap
func badLoad() {
    medicines = try! repository.fetchMedicines() // Crash potentiel !
}
```

### Async/Await

```swift
// ✅ BIEN - Async/await moderne
func loadData() async {
    isLoading = true
    defer { isLoading = false }

    do {
        data = try await service.fetch()
    } catch {
        handleError(error)
    }
}

// ❌ MAL - Closures imbriquées
func badLoad() {
    service.fetch { result in
        DispatchQueue.main.async {
            // Callback hell...
        }
    }
}
```

### SwiftUI Best Practices

```swift
// ✅ BIEN - Vue minimaliste
struct MedicineRow: View {
    let medicine: Medicine

    var body: some View {
        HStack {
            Text(medicine.name)
            Spacer()
            Text("\(medicine.currentQuantity)")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(medicine.name), quantity: \(medicine.currentQuantity)")
    }
}

// ❌ MAL - Logique dans la vue
struct BadView: View {
    var body: some View {
        Button("Save") {
            // Accès direct Firebase - NON !
            Firestore.firestore()...
        }
    }
}
```

### Naming Conventions

- **Classes/Structs/Enums:** PascalCase (`MedicineViewModel`, `UserModel`)
- **Fonctions/Variables:** camelCase (`loadMedicines`, `currentQuantity`)
- **Constantes:** UPPER_SNAKE_CASE ou camelCase selon contexte
- **Protocols:** Suffixe "Protocol" si nécessaire (`RepositoryProtocol`)
- **Tests:** Nom descriptif (`testFetchMedicinesSuccess`)

---

## 🌳 Workflow Git

### Branches

- **`main`** - Branche de production, toujours stable
- **`develop`** - Branche de développement (optionnel)
- **`feature/*`** - Nouvelles fonctionnalités
- **`fix/*`** - Corrections de bugs
- **`hotfix/*`** - Corrections urgentes pour production
- **`chore/*`** - Tâches de maintenance

### Messages de Commit (Conventional Commits)

Format: `<type>(<scope>): <description>`

**Types:**
- `feat` - Nouvelle fonctionnalité
- `fix` - Correction de bug
- `docs` - Documentation uniquement
- `style` - Formatage, point-virgules manquants, etc.
- `refactor` - Refactoring sans changement fonctionnel
- `perf` - Amélioration performance
- `test` - Ajout/modification tests
- `chore` - Maintenance (build, CI, dépendances)
- `ci` - Changements CI/CD

**Exemples:**

```bash
feat(medicine): Add expiration date filtering
fix(auth): Resolve login crash on iOS 17
docs(readme): Update installation instructions
refactor(viewmodel): Extract loading state to base class
test(repository): Add unit tests for medicine CRUD
chore(deps): Update Firebase SDK to 10.20.0
ci(workflow): Add nightly build job
```

**Scope (optionnel):** medicine, auth, ui, repository, viewmodel, etc.

### Rebase vs Merge

- **Rebase** pour garder un historique linéaire (préféré)
- **Merge** pour préserver l'historique complet

```bash
# Rebase depuis main
git fetch upstream
git rebase upstream/main

# Si conflits
git rebase --continue  # Après résolution

# Force push (attention !)
git push origin feature/my-feature --force-with-lease
```

---

## 🔍 Pull Requests

### Checklist Avant PR

- [ ] Code conforme aux standards
- [ ] Tests unitaires ajoutés/mis à jour
- [ ] Tests passent localement (`⌘ + U`)
- [ ] SwiftLint 0 warnings (`swiftlint`)
- [ ] Documentation inline ajoutée
- [ ] CHANGELOG.md mis à jour (si pertinent)
- [ ] Captures d'écran ajoutées (si changement UI)
- [ ] Mocks créés pour nouvelles dépendances

### Template PR

```markdown
## 📝 Description

Brève description des changements.

## 🎯 Type de Changement

- [ ] 🐛 Bug fix (changement non-breaking qui corrige un problème)
- [ ] ✨ New feature (changement non-breaking qui ajoute une fonctionnalité)
- [ ] 💥 Breaking change (correction ou fonctionnalité qui casserait l'existant)
- [ ] 📚 Documentation update

## 🧪 Comment Tester

1. Étape 1
2. Étape 2
3. Résultat attendu

## 📸 Screenshots (si applicable)

Avant | Après
--- | ---
![before](url) | ![after](url)

## ✅ Checklist

- [ ] Mon code suit les guidelines du projet
- [ ] J'ai effectué une self-review
- [ ] J'ai commenté les parties complexes
- [ ] J'ai mis à jour la documentation
- [ ] Mes changements ne génèrent pas de warnings
- [ ] J'ai ajouté des tests
- [ ] Les tests existants passent
- [ ] J'ai vérifié l'accessibilité

## 🔗 Issues Liées

Closes #123
Relates to #456
```

### Processus de Review

1. **Automated Checks** - CI/CD valide automatiquement
2. **Code Review** - Au moins 1 approbation requise
3. **Testing** - Reviewer teste localement si nécessaire
4. **Approval** - Approuvé et prêt à merge
5. **Merge** - Squash and merge (préféré)

### Répondre aux Comments

- Soyez réceptif aux feedbacks
- Discutez constructivement des désaccords
- Résolvez les conversations une fois traitées
- Remerciez les reviewers

---

## 🧪 Tests

### Couverture Minimale

- **Objectif:** 80%+ code coverage
- **Obligatoire:** Tests pour ViewModels, Repositories, Services
- **Recommandé:** Tests UI pour flows critiques

### Types de Tests

#### Tests Unitaires

```swift
class MedicineListViewModelTests: XCTestCase {
    var sut: MedicineListViewModel!
    var mockRepository: MockMedicineRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockMedicineRepository()
        sut = MedicineListViewModel(repository: mockRepository)
    }

    func testFetchMedicinesSuccess() async throws {
        // Given
        mockRepository.medicines = [Medicine.mock()]

        // When
        await sut.loadMedicines()

        // Then
        XCTAssertEqual(sut.medicines.count, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
}
```

#### Tests d'Intégration

```swift
class MedicineRepositoryIntegrationTests: XCTestCase {
    func testFullCRUDCycle() async throws {
        // Test complet Create -> Read -> Update -> Delete
    }
}
```

### Running Tests

```bash
# Tous les tests
xcodebuild test -project MediStock.xcodeproj -scheme MediStock -destination 'platform=iOS Simulator,name=iPhone 16'

# Tests spécifiques
xcodebuild test -project MediStock.xcodeproj -scheme MediStock -only-testing:MediStockTests/MedicineListViewModelTests

# Avec coverage
xcodebuild test -project MediStock.xcodeproj -scheme MediStock -enableCodeCoverage YES
```

### Mocks

- Créer un mock pour chaque protocol de dépendance
- Placer les mocks dans `MediStockTests/Mocks/`
- Voir [MOCK_PATTERNS_GUIDE.md](MediStockTests/MOCK_PATTERNS_GUIDE.md)

---

## 📚 Documentation

### Documentation Inline

```swift
/// Charge la liste des médicaments depuis le repository.
///
/// Cette méthode affiche un indicateur de chargement pendant la récupération
/// et gère automatiquement les erreurs.
///
/// - Throws: `RepositoryError` si la récupération échoue
/// - Note: Cette méthode doit être appelée depuis le main actor
func loadMedicines() async throws {
    // Implementation
}
```

### README Updates

- Mettre à jour README.md pour nouvelles features majeures
- Ajouter des exemples d'utilisation
- Mettre à jour les screenshots si UI change

### CHANGELOG

- Ajouter entry dans CHANGELOG.md pour chaque PR significative
- Suivre le format [Keep a Changelog](https://keepachangelog.com/)

---

## 🐛 Rapporter un Bug

### Template Issue

```markdown
**Description du Bug**
Description claire et concise du bug.

**Étapes pour Reproduire**
1. Aller sur '...'
2. Cliquer sur '...'
3. Scroller jusqu'à '...'
4. Voir l'erreur

**Comportement Attendu**
Description de ce qui devrait se passer.

**Comportement Actuel**
Description de ce qui se passe réellement.

**Screenshots**
Si applicable, ajoutez des screenshots.

**Environnement:**
- iOS Version: [e.g. 17.2]
- Device: [e.g. iPhone 16 Pro]
- App Version: [e.g. 1.0.0]

**Logs/Stack Trace**
```
Collez les logs ici
```

**Contexte Additionnel**
Tout autre contexte utile.
```

---

## ✨ Proposer une Fonctionnalité

### Template Feature Request

```markdown
**Problème à Résoudre**
Description claire du problème que cette feature résoudrait.

**Solution Proposée**
Description de la solution que vous aimeriez voir.

**Alternatives Considérées**
Description des alternatives que vous avez envisagées.

**Contexte Additionnel**
Tout autre contexte, screenshots, mockups utiles.

**Effort Estimé**
- [ ] Small (< 1 jour)
- [ ] Medium (1-3 jours)
- [ ] Large (> 3 jours)

**Impact Utilisateur**
- [ ] High - Fonctionnalité critique
- [ ] Medium - Nice to have
- [ ] Low - Amélioration mineure
```

---

## 🛠️ Configuration Développement

### Prérequis

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9+
- SwiftLint (`brew install swiftlint`)
- Fastlane (`brew install fastlane`)

### Setup

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/MediStock.git
cd MediStock

# Install SwiftLint
brew install swiftlint

# Install Fastlane (optionnel)
brew install fastlane

# Open in Xcode
open MediStock.xcodeproj
```

### Firebase Setup

1. Créer projet Firebase
2. Télécharger `GoogleService-Info.plist`
3. Placer dans `MediStock/` (ne pas commit!)

### Running

1. Sélectionner iPhone 16 Simulator
2. Cmd + R

---

## 📞 Support

- **Issues:** https://github.com/OWNER/MediStock/issues
- **Discussions:** https://github.com/OWNER/MediStock/discussions
- **Email:** tlilihamdi@example.com

---

## 🙏 Remerciements

Merci à tous les contributeurs qui rendent ce projet meilleur !

Contributors: [@TLiLiHamdi](https://github.com/TLiLiHamdi)

---

## 📄 License

En contribuant, vous acceptez que vos contributions soient licensées sous la même licence que le projet (MIT License).

---

**Made with ❤️ by TLILI HAMDI**
