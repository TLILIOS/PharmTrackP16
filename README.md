# MediStock - Application de Gestion de Stock Pharmaceutique iOS

## 📱 Vue d'ensemble

MediStock est une application iOS native développée en SwiftUI pour digitaliser la gestion des stocks de médicaments en pharmacie. Elle offre une traçabilité complète des mouvements de stock avec une interface intuitive adaptée au personnel médical.

## ✨ Fonctionnalités principales

### 🔐 Authentification & Sécurité
- Connexion sécurisée avec Firebase Auth
- Support de la biométrie (Touch ID/Face ID)
- Gestion des sessions avec expiration automatique
- Règles de sécurité Firebase strictes

### 📦 Gestion des Médicaments
- CRUD complet (Créer, Lire, Mettre à jour, Supprimer)
- Organisation par rayons
- Gestion des quantités avec stepper intelligent (debounce)
- Alertes de stock (seuils d'alerte et critique)
- Suivi des dates d'expiration

### 🔍 Recherche & Filtrage Avancés
- Recherche en temps réel avec debounce
- Filtres multiples (rayon, statut stock, expiration, quantité)
- Tri personnalisable (nom, quantité, expiration, statut)
- Historique des recherches récentes

### 📊 Traçabilité & Historique
- Enregistrement automatique de toutes les actions
- Filtres par période et type d'action
- Statistiques mensuelles
- Export CSV des données
- Vue détaillée par médicament

### 🌓 Interface & Accessibilité
- Support complet du Dark Mode
- Accessibilité VoiceOver intégrée
- Support du Dynamic Type
- Interface responsive (iPhone & iPad)

### 🔔 Notifications
- Alertes pour les médicaments expirant bientôt
- Notifications de stock critique
- Rappels personnalisables

### 📱 Fonctionnalités Avancées
- Analytics avec Firebase
- Crashlytics pour le monitoring
- Cache local avec Firestore
- Pagination pour les grandes listes

## 🛠️ Stack Technique

### Frontend
- **SwiftUI** (iOS 15+) - Interface utilisateur déclarative
- **Combine** - Programmation réactive
- **Swift 5.7+** - Langage principal

### Backend
- **Firebase Firestore** - Base de données NoSQL temps réel
- **Firebase Auth** - Authentification
- **Firebase Analytics** - Suivi d'usage
- **Firebase Crashlytics** - Monitoring d'erreurs
- **Firebase Storage** - Stockage de fichiers

### Architecture
- **MVVM** strict avec séparation des responsabilités
- **Repository Pattern** pour l'accès aux données
- **Dependency Injection** pour la testabilité
- **Protocol-Oriented Programming**

## 📋 Prérequis

- macOS Monterey 12.0+
- Xcode 15.0+
- iOS 15.0+ (target de déploiement)
- Compte Firebase (plan Blaze recommandé)
- Apple Developer Account ($99/an)

## 🚀 Installation

1. **Cloner le repository**
   ```bash
   git clone https://github.com/your-username/medistock.git
   cd medistock
   ```

2. **Installer les dépendances**
   ```bash
   # Ouvrir le projet dans Xcode
   open MediStock.xcodeproj
   
   # Les packages Swift seront automatiquement téléchargés
   ```

3. **Configuration Firebase**
   - Créer un projet Firebase
   - Activer Authentication, Firestore, Analytics et Crashlytics
   - Télécharger `GoogleService-Info.plist`
   - Ajouter le fichier au projet Xcode

4. **Déployer les règles de sécurité**
   ```bash
   firebase login
   firebase init
   firebase deploy --only firestore:rules,storage:rules
   ```

5. **Build & Run**
   - Sélectionner un simulateur ou device
   - Cmd+R pour lancer l'application

## 📱 Structure du Projet

```
MediStock/
├── App/
│   ├── MediStockApp.swift          # Point d'entrée
│   ├── AppState.swift              # État global
│   └── NavigationDestinations.swift # Destinations de navigation
├── Models/
│   └── Models.swift                # Modèles de données
├── Views/
│   ├── Components.swift            # Composants réutilisables
│   ├── QuantityStepperView.swift   # Stepper personnalisé
│   ├── SearchView.swift            # Vue de recherche
│   ├── MedicineView.swift          # Vues médicaments
│   └── HistoryDetailView.swift     # Vue historique
├── ViewModels/
│   ├── MedicineListViewModel.swift # VM liste médicaments
│   ├── SearchViewModel.swift       # VM recherche
│   └── HistoryDetailViewModel.swift # VM historique
├── Services/
│   ├── AuthService.swift           # Service authentification
│   ├── DataService.swift           # Service données
│   ├── FirebaseService.swift       # Service Firebase
│   └── ThemeManager.swift          # Gestionnaire de thème
├── Repositories/
│   └── ...                         # Couche d'accès aux données
└── Extensions/
    ├── AccessibilityExtensions.swift # Extensions accessibilité
    └── ValidationExtensions.swift    # Validations
```

## 🧪 Tests

```bash
# Lancer les tests unitaires
cmd+U dans Xcode

# Lancer les tests UI
cmd+shift+U dans Xcode
```

## 📊 Firebase Rules

Les règles de sécurité Firebase sont définies dans :
- `firestore.rules` - Règles Firestore
- `storage.rules` - Règles Storage
- `firestore.indexes.json` - Index composés

## 🎨 Design System

### Couleurs
- Utilisation de `AppColors` pour la cohérence
- Support automatique Light/Dark mode
- Couleurs sémantiques pour les états

### Typography
- `AppFonts` pour les styles de texte
- Support complet du Dynamic Type
- Police système avec design arrondi

### Spacing
- Constantes définies dans `Spacing`
- Grille de 4pt pour la cohérence
- Padding et marges standardisés

## 📱 Captures d'écran

[À ajouter : captures d'écran de l'application]

## 🔧 Configuration

### Variables d'environnement
Créer un fichier `.env` (non versionné) :
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
```

### Settings utilisateur
Les préférences sont stockées dans UserDefaults :
- Thème (clair/sombre/système)
- Notifications activées/désactivées
- Recherches récentes

## 🚀 Déploiement

1. **TestFlight**
   - Archive dans Xcode (Product > Archive)
   - Upload vers App Store Connect
   - Inviter les testeurs beta

2. **App Store**
   - Préparer les métadonnées
   - Captures d'écran pour tous les devices
   - Soumettre pour review

## 📄 Licence

[À définir selon vos besoins]

## 👥 Contributeurs

- [Votre nom] - Développeur principal

## 📞 Support

Pour toute question ou problème :
- Issues GitHub : [lien vers issues]
- Email : support@medistock.app

---

Développé avec ❤️ pour les professionnels de santé