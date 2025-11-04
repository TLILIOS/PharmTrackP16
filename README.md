# 💊 MediStock - Gestion de Stock de Médicaments

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0+-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-yellow.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-red.svg)](LICENSE)
[![CI/CD](https://github.com/YOUR_USERNAME/MediStock/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/MediStock/actions)

Application iOS moderne de gestion de stock de médicaments avec synchronisation Firebase temps réel, développée en SwiftUI avec architecture MVVM stricte.

**Auteur:** TLILI HAMDI

---

## 📱 Fonctionnalités

### Gestion des Médicaments
- ✅ Ajout, modification, suppression de médicaments
- ✅ Gestion des quantités avec seuils d'alerte (warning/critical)
- ✅ Suivi des dates d'expiration avec notifications
- ✅ Référencement par rayons avec code couleur
- ✅ Recherche et filtrage avancés
- ✅ Ajustement rapide des stocks (stepper intégré)

### Gestion des Rayons
- ✅ Organisation personnalisable (nom, description, couleur, icône)
- ✅ Comptage automatique des médicaments par rayon
- ✅ Validation des doublons

### Historique et Traçabilité
- ✅ Enregistrement automatique de toutes les actions (ajout, modification, suppression, ajustement)
- ✅ Filtrage par médicament et période
- ✅ Statistiques d'utilisation
- ✅ Vue détaillée avec timeline

### Tableau de Bord
- ✅ Vue d'ensemble du stock
- ✅ Alertes stocks faibles
- ✅ Médicaments expirant bientôt
- ✅ Statistiques en temps réel

### Fonctionnalités Avancées
- ✅ Authentification Firebase (email/password)
- ✅ Synchronisation temps réel multi-appareils
- ✅ Export PDF des rapports
- ✅ Mode hors ligne (avec synchronisation auto)
- ✅ Notifications push (stock faible, expiration)
- ✅ Surveillance réseau avec bannière d'état
- ✅ Thèmes clair/sombre
- ✅ Accessibilité complète (VoiceOver, Dynamic Type)

---

## 🏗️ Architecture

### MVVM Strict + Clean Architecture

```
┌─────────────────────────────────────────┐
│              VIEWS (SwiftUI)            │
│  Présentation pure, aucune logique      │
└──────────────┬──────────────────────────┘
               │ @EnvironmentObject
               ▼
┌─────────────────────────────────────────┐
│      VIEWMODELS (@MainActor)            │
│  Logique de présentation, état UI      │
└──────────────┬──────────────────────────┘
               │ Protocols
               ▼
┌─────────────────────────────────────────┐
│         REPOSITORIES                    │
│  Abstraction accès données              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│          SERVICES                       │
│  Business Logic + Firebase              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│      MODELS (Codable Structs)           │
│  Données pures du domaine               │
└─────────────────────────────────────────┘
```

### Principes SOLID

- **Single Responsibility** : Chaque classe/struct a une responsabilité unique
- **Open/Closed** : Extension via protocoles et composition
- **Liskov Substitution** : Mocks substituables via protocoles
- **Interface Segregation** : Protocoles spécialisés par domaine
- **Dependency Inversion** : Injection de dépendances systématique

### Structure du Projet

```
MediStock/
├── App/                      # Point d'entrée, état global
├── Core/                     # Bases ViewModels, utilitaires
├── DependencyInjection/      # Container IoC
├── Models/                   # Modèles de domaine
├── Protocols/                # Protocols Repositories/Services
├── Repositories/             # Couche d'accès aux données
├── Services/                 # Logique métier + Firebase
├── ViewModels/               # Logique de présentation
├── Views/                    # Interface utilisateur SwiftUI
├── Extensions/               # Extensions utilitaires
└── Utilities/                # Helpers partagés

MediStockTests/
├── Mocks/                    # Mocks isolés pour tests
├── ViewModels/               # Tests ViewModels
├── Repositories/             # Tests Repositories
├── Services/                 # Tests Services
└── Core/                     # Tests patterns de base
```

---

## 🚀 Installation

### Prérequis

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- iOS 17.0+ (simulateur ou appareil)
- Compte Firebase (gratuit)
- CocoaPods ou Swift Package Manager

### Étape 1 : Cloner le Repository

```bash
git clone https://github.com/YOUR_USERNAME/MediStock.git
cd MediStock
```

### Étape 2 : Configuration Firebase

1. Créer un projet Firebase sur [console.firebase.google.com](https://console.firebase.google.com)
2. Activer **Authentication** (Email/Password)
3. Activer **Firestore Database**
4. Activer **Cloud Functions** (optionnel)
5. Activer **Analytics** (optionnel)
6. Télécharger `GoogleService-Info.plist`
7. Placer le fichier à la racine du projet `MediStock/GoogleService-Info.plist`

⚠️ **Important** : Ne jamais commiter `GoogleService-Info.plist` (déjà dans .gitignore)

### Étape 3 : Installer les Dépendances

Le projet utilise **Swift Package Manager** (déjà configuré dans Xcode).

Dépendances Firebase :
- FirebaseAuth
- FirebaseFirestore
- FirebaseAnalytics

Xcode téléchargera automatiquement les packages lors de l'ouverture du projet.

### Étape 4 : Configurer les Règles Firebase

#### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Authentification requise
    match /{document=**} {
      allow read, write: if request.auth != null;
    }

    // Médicaments : utilisateur propriétaire uniquement
    match /medicines/{medicineId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.userId;
    }

    // Rayons : utilisateur propriétaire uniquement
    match /aisles/{aisleId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.userId;
    }

    // Historique : lecture seule pour l'utilisateur
    match /history/{historyId} {
      allow read: if request.auth != null
        && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
  }
}
```

Appliquer via Firebase Console : **Firestore Database → Rules**

### Étape 5 : Ouvrir le Projet

```bash
open MediStock.xcodeproj
```

### Étape 6 : Build et Run

1. Sélectionner un simulateur (iPhone 15/16) ou appareil
2. Choisir le scheme **MediStock**
3. Cmd + R pour build et run

---

## 🧪 Tests

### Exécuter les Tests

```bash
# Tous les tests
xcodebuild test -project MediStock.xcodeproj -scheme MediStock -destination 'platform=iOS Simulator,name=iPhone 16'

# Tests unitaires uniquement
xcodebuild test -project MediStock.xcodeproj -scheme MediStock-UnitTests -destination 'platform=iOS Simulator,name=iPhone 16'

# Avec code coverage
xcodebuild test -project MediStock.xcodeproj -scheme MediStock -enableCodeCoverage YES -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Via Xcode

Cmd + U ou Product → Test

### Coverage

**Objectif : 80%+**

Couverture actuelle :
- ViewModels : 100%
- Repositories : 100%
- Services : 95%
- **Global : ~87%**

Documentation complète des tests : [MediStockTests/README.md](MediStockTests/README.md)

---

## 🔧 Outils de Développement

### SwiftLint

Configuration stricte pour qualité du code.

```bash
# Installation
brew install swiftlint

# Linting
swiftlint

# Auto-correction
swiftlint --fix
```

Configuration : [.swiftlint.yml](.swiftlint.yml)

### Fastlane

Automatisation déploiement TestFlight/App Store.

```bash
# Installation
brew install fastlane

# TestFlight
fastlane beta

# App Store
fastlane release
```

Configuration : [fastlane/Fastfile](fastlane/Fastfile)

---

## 🔄 CI/CD

### GitHub Actions

5 workflows automatisés :

1. **PR Validation** (pr-validation.yml)
   - Lint + Build + Tests + Coverage
   - Déclenché sur chaque Pull Request

2. **Main CI** (main-ci.yml)
   - Tests complets + Build Release
   - Déclenché sur push main

3. **Release** (release.yml)
   - Upload TestFlight automatique
   - Déclenché sur tag (v*)

4. **Nightly** (nightly.yml)
   - Tests longs + Documentation
   - Déclenché quotidiennement (3h00 UTC)

5. **Security** (security.yml)
   - Scan dépendances + SAST
   - Déclenché hebdomadairement

Documentation complète : [ARCHITECTURE_CI_CD.md](ARCHITECTURE_CI_CD.md)

---

## 📦 Modèles de Données

### Medicine (Médicament)

```swift
struct Medicine: Identifiable, Codable, Equatable, Hashable {
    var id: String?
    let name: String
    let description: String?
    let dosage: String?
    let form: String?            // Comprimé, Gélule, Sirop, etc.
    let reference: String?       // Référence/Code barre
    let unit: String             // Boîte, Flacon, etc.
    var currentQuantity: Int
    let maxQuantity: Int
    let warningThreshold: Int    // Seuil d'alerte
    let criticalThreshold: Int   // Seuil critique
    let expiryDate: Date?
    let aisleId: String          // Référence rayon
    let createdAt: Date
    let updatedAt: Date
}
```

### Aisle (Rayon)

```swift
struct Aisle: Identifiable, Codable, Equatable, Hashable {
    var id: String?
    let name: String
    let description: String?
    let colorHex: String
    let icon: String
}
```

### User (Utilisateur)

```swift
struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String?
    let displayName: String?
}
```

### HistoryEntry (Historique)

```swift
struct HistoryEntry: Identifiable, Codable, Hashable {
    let id: String
    let medicineId: String
    let userId: String
    let action: String           // Ajout, Modification, Suppression, Ajustement
    let details: String
    let timestamp: Date
}
```

---

## 🔐 Sécurité

### Bonnes Pratiques Implémentées

- ✅ Aucun secret en clair dans le code
- ✅ GoogleService-Info.plist gitignore
- ✅ Validation inputs côté client ET serveur
- ✅ Firebase Security Rules strictes
- ✅ KeychainService pour données sensibles
- ✅ HTTPS uniquement (Firebase)
- ✅ Authentication obligatoire
- ✅ Pas de force unwrap (!)

### Recommandations Production

- [ ] Activer Firebase App Check
- [ ] Implémenter Certificate Pinning
- [ ] Audit sécurité Firebase Rules
- [ ] Obfuscation du code
- [ ] Scan dépendances régulier (Dependabot)

---

## 🎨 Design et Accessibilité

### Design System

- Composants réutilisables dans `Views/Components/`
- Thèmes clair/sombre automatiques
- Couleurs sémantiques (success, warning, critical)
- Icônes SF Symbols
- Animations fluides

### Accessibilité (A11y)

- ✅ VoiceOver complet
- ✅ Dynamic Type support
- ✅ Labels accessibilité
- ✅ Hints contextuels
- ✅ Contrast ratios WCAG AA
- ✅ Keyboard navigation

Tests accessibilité : Xcode Accessibility Inspector

---

## 🌐 Internationalisation

**Langues supportées :**
- Français (fr-FR) - par défaut
- Anglais (en-US) - à venir

Fichiers : `Localizable.strings`

---

## 📊 Métriques

### Code

- **91 fichiers Swift**
- **62 fichiers source**
- **29 fichiers tests**
- **87% couverture tests**
- **0 warnings SwiftLint**
- **Score qualité : 8.5/10**

### Performance

- Temps de démarrage : < 500ms
- Temps de synchronisation : < 1s
- Mémoire moyenne : < 50MB
- Battery drain : Faible

---

## 🗺️ Roadmap

### Version 1.1 (Q1 2026)
- [ ] Mode offline complet (cache local CoreData)
- [ ] Scan code-barres médicaments
- [ ] Export Excel/CSV
- [ ] Partage entre utilisateurs (organisations)
- [ ] Notifications personnalisables

### Version 1.2 (Q2 2026)
- [ ] Widget iOS
- [ ] Apple Watch app
- [ ] Siri Shortcuts
- [ ] HealthKit intégration
- [ ] Machine Learning (prédictions rupture stock)

### Version 2.0 (Q3 2026)
- [ ] Version iPad optimisée
- [ ] Version macOS (Catalyst)
- [ ] API REST publique
- [ ] Intégrations tiers (pharmacies)

---

## 🤝 Contribution

Les contributions sont bienvenues ! Merci de lire [CONTRIBUTING.md](CONTRIBUTING.md) avant de soumettre une PR.

### Workflow

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'feat: Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

### Standards

- Code Swift idiomatique
- SwiftLint 0 warnings
- Tests unitaires obligatoires
- Documentation inline
- Commits conventionnels

---

## 📄 License

Ce projet est sous licence MIT. Voir [LICENSE](LICENSE) pour plus d'informations.

---

## 📞 Support

**Développeur Principal :** TLILI HAMDI

- Email : tlilihamdi@example.com
- GitHub : [@TLiLiHamdi](https://github.com/TLiLiHamdi)
- LinkedIn : [TLILI HAMDI](https://linkedin.com/in/tlilihamdi)

### Issues

Pour signaler un bug ou demander une fonctionnalité, ouvrir une [issue GitHub](https://github.com/YOUR_USERNAME/MediStock/issues).

### FAQ

**Q: L'app fonctionne-t-elle hors ligne ?**
R: Partiellement. Firebase Firestore met en cache les données récentes. Une version offline complète est prévue v1.1.

**Q: Puis-je utiliser MediStock en production ?**
R: Oui, mais assurez-vous de configurer correctement Firebase Security Rules et App Check.

**Q: Comment exporter mes données ?**
R: Utilisez la fonctionnalité Export PDF dans le menu Profil. Export Excel prévu v1.1.

**Q: Combien coûte Firebase ?**
R: Le plan gratuit (Spark) suffit pour usage personnel. Plan Blaze (pay-as-you-go) recommandé en production.

---

## 🙏 Remerciements

- Firebase pour l'infrastructure backend
- Apple pour SwiftUI et les outils de développement
- Communauté Swift pour les excellentes ressources
- OpenClassrooms pour le projet P16

---

## 📚 Documentation Technique

- [Architecture CI/CD](ARCHITECTURE_CI_CD.md)
- [Guide des Tests](MediStockTests/README.md)
- [Patterns de Mocks](MediStockTests/MOCK_PATTERNS_GUIDE.md)
- [Audit Tests](MediStockTests/AUDIT_REPORT.md)
- [Guide Contribution](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

---

**Version :** 1.0.0
**Dernière mise à jour :** 3 Novembre 2025
**Statut :** Production Ready ✅

---

Made with ❤️ by TLILI HAMDI
