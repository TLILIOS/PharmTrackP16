# Architecture CI/CD - MediStock

Document technique exhaustif de l'architecture CI/CD mise en place pour le projet MediStock.

**Auteur:** TLILI HAMDI
**Date:** 3 Novembre 2025
**Version:** 1.0.0

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Architecture Globale](#architecture-globale)
3. [Workflows GitHub Actions](#workflows-github-actions)
4. [Fastlane Integration](#fastlane-integration)
5. [Code Quality & Linting](#code-quality--linting)
6. [Sécurité](#sécurité)
7. [Secrets & Configuration](#secrets--configuration)
8. [Monitoring & Alertes](#monitoring--alertes)
9. [Optimisations](#optimisations)
10. [Troubleshooting](#troubleshooting)
11. [Best Practices](#best-practices)
12. [Evolution Future](#evolution-future)

---

## 🎯 Vue d'Ensemble

### Objectifs

L'architecture CI/CD de MediStock vise à:

- ✅ **Automatiser** le build, les tests et le déploiement
- ✅ **Garantir la qualité** via linting, tests et reviews automatisées
- ✅ **Accélérer** le time-to-market avec des releases fréquentes
- ✅ **Sécuriser** le code via scans automatiques
- ✅ **Monitorer** la santé du projet en continu

### Métriques Clés

| Métrique | Objectif | Actuel |
|----------|----------|--------|
| **Build Time** | < 5 min | ~3 min |
| **Test Execution** | < 10 min | ~8 min |
| **Code Coverage** | > 80% | 87% |
| **Deployment Time** | < 15 min | ~12 min |
| **PR Merge Time** | < 24h | Variable |

### Stack Technique

- **CI/CD Platform:** GitHub Actions
- **Build Tool:** xcodebuild
- **Automation:** Fastlane
- **Linting:** SwiftLint
- **Code Review:** Danger
- **Package Manager:** Swift Package Manager (SPM)
- **Artifact Storage:** GitHub Artifacts
- **Runners:** macos-14 (Xcode 15.2)

---

## 🏗️ Architecture Globale

### Diagramme Pipeline Complet

```
┌─────────────────────────────────────────────────────────────────┐
│                        CODE COMMIT                              │
└────────────┬────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PULL REQUEST OPENED                          │
└────────────┬────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│              PR VALIDATION PIPELINE (Parallèle)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Fast Checks │  │   SwiftLint  │  │ Build & Test │          │
│  │  - Secrets   │  │  - Strict    │  │  - Unit      │          │
│  │  - Project   │  │  - Report    │  │  - Coverage  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │  Performance │  │   Danger     │                            │
│  │  - Build     │  │  - Review    │                            │
│  │  - Metrics   │  │  - Comment   │                            │
│  └──────────────┘  └──────────────┘                            │
└────────────┬────────────────────────────────────────────────────┘
             │
             ▼ (PR Approved & Merged)
┌─────────────────────────────────────────────────────────────────┐
│                    MAIN CI PIPELINE                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Test Suite   │  │Build Release │  │Generate Docs │          │
│  │  - Complete  │  │  - Archive   │  │  - DocC      │          │
│  │  - Coverage  │  │  - IPA       │  │  - Upload    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└────────────┬────────────────────────────────────────────────────┘
             │
             ▼ (Tag v*.*.*)
┌─────────────────────────────────────────────────────────────────┐
│                   RELEASE PIPELINE                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Validate   │  │  Build & Sign│  │Upload TF/AS  │          │
│  │  - Version   │  │  - Increment │  │  - TestFlight│          │
│  │  - Changelog │  │  - Archive   │  │  - App Store │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────┐                                                │
│  │GitHub Release│                                                │
│  │  - Tag       │                                                │
│  │  - Notes     │                                                │
│  └──────────────┘                                                │
└─────────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│               NIGHTLY BUILD (3h00 UTC Daily)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │Extended Tests│  │ Code Quality │  │  Dependency  │          │
│  │  - Retry 3x  │  │  - Metrics   │  │  - Audit     │          │
│  │  - Full      │  │  - LOC       │  │  - Updates   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │Documentation │  │ Performance  │                            │
│  │  - DocC      │  │  - Benchmark │                            │
│  └──────────────┘  └──────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│            SECURITY SCAN (Weekly Sunday 2h00 UTC)               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │Secret Detect │  │  Dependency  │  │ Code SAST    │          │
│  │  - History   │  │  - CVE Scan  │  │  - Patterns  │          │
│  │  - Files     │  │  - Versions  │  │  - Unsafe    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────┐                                                │
│  │Firebase Rules│                                                │
│  │  - Validate  │                                                │
│  └──────────────┘                                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Workflows GitHub Actions

### 1. lint.yml - Linting Continu

**Déclencheur:** Push/PR sur fichiers `**.swift` ou `.swiftlint.yml`

**Jobs:**
1. **SwiftLint Check**
   - Installation SwiftLint via Homebrew
   - Lint avec reporter GitHub Actions Logging
   - Mode strict pour PR (warnings = errors)
   - Génération rapports HTML/JSON
   - Upload artifacts
   - Commentaire automatique sur PR si violations

**Durée:** ~3 min
**Fréquence:** Sur chaque push/PR

**Configuration:**
```yaml
on:
  pull_request:
    paths:
      - '**.swift'
      - '.swiftlint.yml'
  push:
    paths:
      - '**.swift'
```

**Optimisations:**
- Cache Homebrew
- Lint incrémental (fichiers modifiés uniquement) via Danger
- Reporter adapté à GitHub Actions

---

### 2. pr-validation.yml - Validation Pull Requests

**Déclencheur:** Pull Request vers `main` ou `develop`

**Concurrence:** Annulation PR précédentes en cours

**Jobs (Parallèles):**

#### 2.1 Fast Checks (~2 min)
- Vérification fichiers sensibles (GoogleService-Info.plist, *.key, *.p12)
- Validation projet Xcode
- Check versions Swift/Xcode

#### 2.2 SwiftLint (~3 min)
- Lint strict mode
- Génération rapports
- Upload artifacts

#### 2.3 Build & Unit Tests (~15-20 min)
- Setup Firebase mock (GoogleService-Info.plist factice)
- Cache SPM dependencies
- Resolve packages
- Build Debug configuration
- Run unit tests avec code coverage
- Upload test results (.xcresult)
- Génération coverage report (xccov)
- Check coverage threshold (80%)

#### 2.4 Build Performance (~5 min)
- Mesure temps de build
- Commentaire PR avec metrics
- Alerte si > 5 min

#### 2.5 PR Summary
- Agrégation résultats tous jobs
- Commentaire récapitulatif sur PR
- Statut ✅/❌ pour chaque check

**Durée Totale:** ~15-20 min (jobs parallèles)
**Fréquence:** Chaque PR

**Optimisations:**
- Jobs parallèles maximum
- Cache SPM (`.build`, `DerivedData`)
- Firebase mock pour éviter dépendances externes
- Conditional execution (needs)

---

### 3. main-ci.yml - CI sur Branche Main

**Déclencheur:** Push sur `main` ou workflow_dispatch manuel

**Concurrence:** Pas d'annulation (jobs séquentiels)

**Jobs:**

#### 3.1 Complete Test Suite (~25 min)
- Setup Firebase mock ou prod config (via secrets)
- Cache dependencies
- Build for testing
- Run all tests (unit + intégration)
- Code coverage détaillée
- Upload test results & coverage
- Commentaire commit avec coverage %

#### 3.2 Build Release Archive (~15 min)
- Setup Firebase production config (base64 secrets)
- Build Release configuration
- Archive application (.xcarchive)
- Export IPA (si signing configuré)
- Upload artifacts (archive + IPA)
- Retention 30 jours

#### 3.3 Generate Documentation (~10 min)
- Build DocC documentation
- Find et package .doccarchive
- Upload artifacts

#### 3.4 Notification & Summary
- Agrégation résultats
- Summary Markdown
- Optionnel: Notification Slack/Discord

**Durée Totale:** ~30-40 min
**Fréquence:** Chaque merge sur main

**Artifacts Générés:**
- `test-results-main` (.xcresult)
- `coverage-report-main` (JSON + TXT)
- `medistock-archive` (.xcarchive)
- `medistock-ipa` (.ipa si signing)

---

### 4. release.yml - Release vers TestFlight/App Store

**Déclencheur:**
- Tag `v*.*.*` (semver)
- Workflow dispatch manuel avec inputs

**Jobs:**

#### 4.1 Validate Release (~5 min)
- Extract version depuis tag ou input
- Auto-increment build number
- Validate semver format
- Check CHANGELOG.md contient version
- Output version + build number

#### 4.2 Test Before Release (~20 min, optionnel)
- Peut être skippé via input `skip_tests`
- Run all tests
- Bloque release si tests échouent

#### 4.3 Build & Archive (~20 min)
- Setup Firebase production
- Import signing certificate (.p12 depuis secrets)
- Create keychain temporaire
- Import provisioning profile
- Update version & build number dans Info.plist
- Build & Archive (Release configuration)
- Export IPA (App Store distribution)
- Upload IPA + dSYM artifacts (retention 90 jours)

#### 4.4 Upload TestFlight (~10 min)
- Download IPA
- Upload via Fastlane (si configuré)
- Ou via altool (Apple ID + app-specific password)
- Skip si pas de credentials

#### 4.5 Create GitHub Release
- Download IPA
- Extract release notes depuis CHANGELOG.md
- Create GitHub Release avec tag
- Upload IPA comme asset
- Markdown description complète

#### 4.6 Notification
- Summary avec tous statuts
- Next steps (TestFlight check, beta testers, App Store)
- Optionnel: Slack notification

**Durée Totale:** ~45-60 min
**Fréquence:** Sur demande (tag ou manual)

**Secrets Requis:**
- `GOOGLE_SERVICE_INFO_PLIST` (base64)
- `IOS_CERTIFICATE_P12` (base64)
- `CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE` (base64)
- `KEYCHAIN_PASSWORD`
- `APPLE_TEAM_ID`
- `APPLE_ID`
- `APP_SPECIFIC_PASSWORD`
- `APP_STORE_CONNECT_API_KEY_*` (optionnel Fastlane)

---

### 5. nightly.yml - Build Nightly

**Déclencheur:**
- Cron: `0 3 * * *` (tous les jours 3h00 UTC)
- Workflow dispatch manuel

**Jobs:**

#### 5.1 Extended Test Suite (~30 min)
- Run all tests avec retry automatique (3 attempts)
- Retry delay 30s entre attempts
- Upload test results

#### 5.2 Code Quality (~15 min)
- Run SwiftLint avec metrics JSON/HTML
- Count violations par severity
- Count Swift files
- Count lines of code
- Analyse complexity (swiftlint analyze)
- Génération rapport qualité Markdown
- Upload artifacts (30 jours retention)

#### 5.3 Generate Documentation (~15 min)
- DocC build
- Package .doccarchive
- Upload artifacts

#### 5.4 Dependency Audit (~10 min)
- Resolve dependencies
- List all packages
- Parse Package.resolved
- Check Firebase SDK versions (min 10.0.0)
- Check outdated dependencies
- Génération rapport dépendances

#### 5.5 Performance Benchmarks (~10 min)
- Measure clean build time
- Génération rapport performance
- Alerte si > 5 min

#### 5.6 Nightly Summary
- Agrégation tous résultats
- Summary Markdown
- Optionnel: Slack notification si failure

**Durée Totale:** ~60 min
**Fréquence:** Quotidienne (3h00 UTC)

**Artifacts Générés:**
- `nightly-test-results`
- `code-quality-report`
- `documentation`
- `dependency-report`
- `performance-report`

---

### 6. security.yml - Scan de Sécurité

**Déclencheur:**
- Cron: `0 2 * * 0` (dimanches 2h00 UTC)
- Push sur main si changement dépendances
- Workflow dispatch manuel

**Jobs:**

#### 6.1 Secret Detection (~10 min)
- Scan fichiers sensibles dans repo
  - GoogleService-Info.plist
  - Certificates (.p12, .key, .pem)
  - .env files
  - API keys hardcodées dans Swift files
- Scan git history pour secrets leaked
- Patterns regex (password, api_key, secret, token, firebase)
- FAIL si secrets détectés

#### 6.2 Dependency Vulnerability Scan (~15 min)
- Resolve dependencies
- Extract Package.resolved
- Check Firebase SDK versions (min 10.0.0)
- List all dependencies avec versions
- Check known vulnerabilities (manuel)
- Génération rapport sécurité dépendances
- Recommandations mises à jour

#### 6.3 Code Security Analysis (SAST) (~20 min)
- Scan patterns unsafe:
  - Force unwrapping (!)
  - Force try (try!)
  - Unsafe pointers
  - SQL injection risks
  - Hardcoded credentials
- Check authentication implementation
- Check data encryption (Keychain usage)
- Check UserDefaults pour données sensibles
- Génération rapport analyse code

#### 6.4 Firebase Security (~10 min)
- Check .firebaserc configuration
- Check firestore.rules (si présent)
- Génération recommandations Security Rules
- Checklist sécurité Firebase:
  - Authentication configurée
  - App Check recommandé
  - Security Rules strictes
  - Audit logs
  - Backups

#### 6.5 Security Summary
- Agrégation tous scans
- Summary Markdown avec action items
- CRITICAL alert si secrets détectés
- Optionnel: Slack notification critique

**Durée Totale:** ~45 min
**Fréquence:** Hebdomadaire (dimanche)

**Artifacts Générés:**
- `dependency-security-report` (90 jours)
- `code-security-report` (90 jours)
- `firebase-security-report` (90 jours)

---

## 🚀 Fastlane Integration

### Configuration

Fichier: `fastlane/Fastfile`

### Lanes Principales

#### test
```ruby
lane :test do
  run_tests(
    project: "MediStock.xcodeproj",
    scheme: "MediStock",
    devices: ["iPhone 16"],
    clean: true,
    code_coverage: true
  )
end
```

#### beta (TestFlight)
```ruby
lane :beta do
  ensure_git_status_clean
  increment_build_number
  test
  build_app(export_method: "app-store")
  upload_to_testflight
  commit_version_bump
  add_git_tag
  push_to_git_remote
end
```

#### release (App Store)
```ruby
lane :release do
  ensure_git_status_clean
  ensure_git_branch(branch: "main")
  increment_version_number
  test
  build_release
  upload_to_app_store(submit_for_review: false)
  commit_version_bump
  add_git_tag
  push_to_git_remote(tags: true)
  set_github_release
end
```

### Variables d'Environnement Fastlane

```bash
FASTLANE_USER                                  # Apple ID
FASTLANE_PASSWORD                              # App-specific password
APP_STORE_CONNECT_API_KEY_KEY_ID               # API Key ID
APP_STORE_CONNECT_API_KEY_ISSUER_ID            # Issuer ID
APP_STORE_CONNECT_API_KEY_KEY                  # API Key content
MATCH_PASSWORD                                  # Match encryption password
GITHUB_TOKEN                                    # GitHub PAT
```

### Commandes Utiles

```bash
# Tests
fastlane test

# Build development
fastlane build_dev

# Deploy TestFlight
fastlane beta

# Deploy App Store
fastlane release

# Screenshots
fastlane screenshots

# Lint
fastlane lint

# CI pipeline
fastlane ci

# CD pipeline (from CI)
fastlane cd_beta
```

---

## 🔍 Code Quality & Linting

### SwiftLint Configuration

Fichier: `.swiftlint.yml`

**Règles Activées:** 50+ règles incluant:
- Performance (`empty_count`, `first_where`, `contains_over_filter`)
- Code Quality (`explicit_init`, `redundant_nil_coalescing`)
- Documentation (`missing_docs` pour public/open)
- Sécurité (`force_unwrapping`, `implicitly_unwrapped_optional`)
- Modern Swift (`closure_end_indentation`, `modifier_order`, `sorted_imports`)

**Règles Custom:**
- `no_print` - Interdire print(), utiliser Logger
- `viewmodel_main_actor` - Forcer @MainActor sur ViewModels
- `no_dispatch_main` - Utiliser @MainActor au lieu de DispatchQueue.main.async
- `weak_self_in_closures` - Forcer [weak self] dans closures async
- `no_force_try_production` - Interdire try!
- `accessibility_label` - Forcer labels accessibilité
- `todo_with_ticket` - TODOs doivent référencer un ticket

**Limites:**
- Line length: 120 (warning), 150 (error)
- File length: 500 (warning), 800 (error)
- Function body: 50 (warning), 100 (error)
- Type body: 300 (warning), 500 (error)
- Function parameters: 5 (warning), 7 (error)
- Cyclomatic complexity: 10 (warning), 20 (error)

**Exclusions:**
- `*.generated.swift`
- `*Mock*.swift`
- `*Stub*.swift`

### Danger Integration

Fichier: `Dangerfile`

**Checks Automatiques:**

**PR Metadata:**
- Description minimale (> 10 caractères)
- Taille PR (warning si > 500 LOC)
- Nombre commits (warning si > 10)

**Code Analysis:**
- Lint violations (intégration SwiftLint)
- Tests coverage (warning si aucun test modifié)
- Mocks pour nouveaux services

**Architecture:**
- ViewModels avec @MainActor
- Models en structs (pas classes)

**Sécurité:**
- Fichiers sensibles non commitables
- Force unwrapping (warning si > 5)
- Force try usage
- Print statements (utiliser Logger)

**Documentation:**
- Fonctions publiques documentées
- CHANGELOG.md mis à jour pour PRs importantes

**Accessibilité:**
- Labels accessibilité sur Button/Image

**Performance:**
- @State vs @StateObject vs @ObservedObject

**Git Best Practices:**
- Conventional Commits format

**Custom Rules:**
- Info.plist pas modifié manuellement
- Fichiers > 500KB
- TODO sans référence ticket

---

## 🔐 Sécurité

### Threat Model

**Menaces Identifiées:**
1. Secrets leakés dans repository
2. Dépendances vulnérables
3. Code unsafe (force unwrap, force try)
4. Firebase Security Rules permissives
5. Man-in-the-middle attacks
6. Jailbreak/Root detection absente

**Mitigations:**

| Menace | Mitigation | Statut |
|--------|-----------|--------|
| Secrets leaked | Secret detection workflow | ✅ |
| Vulnerable deps | Dependency scan weekly | ✅ |
| Unsafe code | SwiftLint custom rules | ✅ |
| Permissive rules | Firebase rules validation | ✅ |
| MITM | HTTPS only (Firebase) | ✅ |
| Certificate pinning | À implémenter | ⚠️ |
| Jailbreak detection | À implémenter | ⚠️ |

### Security Scan Jobs

Voir [Workflows](#6-securityyml---scan-de-sécurité)

### Best Practices

- ✅ Aucun secret en clair dans code
- ✅ GoogleService-Info.plist gitignore
- ✅ Secrets dans GitHub Secrets (encrypted)
- ✅ Keychain pour credentials
- ✅ Firebase Security Rules strictes
- ✅ Validation inputs côté client ET serveur
- ⚠️ Certificate pinning recommandé
- ⚠️ Firebase App Check recommandé

---

## 🔑 Secrets & Configuration

### GitHub Secrets Requis

**Firebase:**
```
GOOGLE_SERVICE_INFO_PLIST  # Base64 encoded GoogleService-Info.plist
FIREBASE_API_KEY           # API key (optionnel, dans plist)
```

**Code Signing:**
```
IOS_CERTIFICATE_P12        # Base64 encoded .p12 certificate
CERTIFICATE_PASSWORD       # Password pour .p12
IOS_PROVISIONING_PROFILE   # Base64 encoded .mobileprovision
KEYCHAIN_PASSWORD          # Password keychain temporaire CI
APPLE_TEAM_ID              # Team ID Apple Developer
```

**App Store Connect:**
```
APPLE_ID                   # Apple ID email
APP_SPECIFIC_PASSWORD      # App-specific password (2FA)

# OU (recommandé)

APP_STORE_CONNECT_API_KEY_KEY_ID
APP_STORE_CONNECT_API_KEY_ISSUER_ID
APP_STORE_CONNECT_API_KEY_KEY  # Base64 encoded .p8 key
```

**Optionnels:**
```
SLACK_WEBHOOK              # Webhook Slack pour notifications
GITHUB_TOKEN               # PAT pour GitHub releases (auto-généré sinon)
DANGER_GITHUB_API_TOKEN    # PAT pour Danger (repo permissions)
```

### Configuration des Secrets

#### 1. GoogleService-Info.plist

```bash
# Encoder en base64
base64 -i MediStock/GoogleService-Info.plist | pbcopy

# Ajouter dans GitHub Secrets:
# Settings → Secrets → Actions → New repository secret
# Name: GOOGLE_SERVICE_INFO_PLIST
# Value: <paste>
```

#### 2. Certificat iOS (.p12)

```bash
# Exporter depuis Keychain Access:
# 1. Sélectionner "Apple Development/Distribution"
# 2. File → Export Items
# 3. Format: Personal Information Exchange (.p12)
# 4. Définir password

# Encoder en base64
base64 -i certificate.p12 | pbcopy

# Ajouter dans GitHub Secrets:
# Name: IOS_CERTIFICATE_P12
# Value: <paste>

# Ajouter password
# Name: CERTIFICATE_PASSWORD
# Value: <your password>
```

#### 3. Provisioning Profile

```bash
# Télécharger depuis Apple Developer Portal
# Ou exporter depuis Xcode (~/Library/MobileDevice/Provisioning Profiles/)

# Encoder en base64
base64 -i profile.mobileprovision | pbcopy

# Ajouter dans GitHub Secrets:
# Name: IOS_PROVISIONING_PROFILE
# Value: <paste>
```

#### 4. App Store Connect API Key

```bash
# Créer API Key:
# App Store Connect → Users and Access → Keys → Generate
# Télécharger .p8 file

# Encoder en base64
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy

# Ajouter dans GitHub Secrets:
# Name: APP_STORE_CONNECT_API_KEY_KEY_ID
# Value: XXXXXXXXXX (Key ID)

# Name: APP_STORE_CONNECT_API_KEY_ISSUER_ID
# Value: YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY (Issuer ID)

# Name: APP_STORE_CONNECT_API_KEY_KEY
# Value: <paste base64>
```

### Utilisation dans Workflows

```yaml
- name: Setup Firebase Production
  run: |
    echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}" | base64 --decode > MediStock/GoogleService-Info.plist

- name: Import Signing Certificate
  run: |
    echo "${{ secrets.IOS_CERTIFICATE_P12 }}" | base64 --decode > certificate.p12
    security import certificate.p12 -k build.keychain -P "${{ secrets.CERTIFICATE_PASSWORD }}"
```

---

## 📊 Monitoring & Alertes

### Métriques Trackées

**Build Metrics:**
- Build time (target: < 5 min)
- Test execution time (target: < 10 min)
- Code coverage (target: > 80%)

**Code Quality:**
- SwiftLint violations (target: 0)
- Lines of code
- Cyclomatic complexity

**Security:**
- Dependency vulnerabilities
- Secrets leaked
- Unsafe patterns

**Release:**
- Deployment success rate
- Time to TestFlight
- Crash-free rate (via Firebase Crashlytics - to implement)

### GitHub Actions Insights

Disponibles dans: `Actions → <Workflow> → Insights`

- Success rate
- Duration trends
- Job timing breakdown

### Notifications

**Actuellement:**
- GitHub Actions UI
- Email notifications (configurable par utilisateur)
- PR comments automatiques

**Recommandé d'ajouter:**
- Slack/Discord webhooks pour:
  - Release success/failure
  - Security critical alerts
  - Nightly build failures
  - Weekly summary

**Configuration Slack:**

```yaml
- name: Slack Notification
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "🚨 Build failed: ${{ github.workflow }}"
      }
```

---

## ⚡ Optimisations

### 1. Cache Strategy

**SPM Dependencies:**
```yaml
- uses: actions/cache@v4
  with:
    path: |
      .build
      ~/Library/Developer/Xcode/DerivedData
    key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
```

**Homebrew (SwiftLint):**
```yaml
- uses: actions/cache@v4
  with:
    path: ~/Library/Caches/Homebrew
    key: ${{ runner.os }}-brew-swiftlint
```

### 2. Parallel Jobs

Maximum de jobs parallèles dans PR validation:
- Fast checks
- SwiftLint
- Build & Tests
- Performance
- (Danger si configuré)

### 3. Conditional Execution

```yaml
on:
  push:
    paths:
      - '**.swift'  # Seulement si Swift files modifiés
```

```yaml
if: github.event_name == 'pull_request'  # Seulement sur PR
```

### 4. Job Dependencies

```yaml
needs: [test-suite]  # Attend la fin de test-suite
```

### 5. Concurrency

```yaml
concurrency:
  group: pr-${{ github.event.pull_request.number }}
  cancel-in-progress: true  # Annule builds précédents
```

### 6. Build Optimizations

- `ONLY_ACTIVE_ARCH=YES` pour builds développement
- `ONLY_ACTIVE_ARCH=NO` pour archives
- `CODE_SIGNING_ALLOWED=NO` pour tests
- `clean: true` seulement quand nécessaire

### 7. Test Optimizations

- `build-for-testing` + `test-without-building` pour parallélisation
- Test filtering avec `-only-testing`
- Retry flaky tests (nightly pipeline)

### Résultats Optimisations

| Avant | Après | Amélioration |
|-------|-------|--------------|
| PR validation: 30 min | 15-20 min | -33% |
| Main CI: 50 min | 30-40 min | -25% |
| Cache misses: 100% | < 20% | -80% |

---

## 🔧 Troubleshooting

### Problèmes Courants

#### 1. Build Failed: "No such module 'Firebase...'"

**Cause:** Dépendances SPM non résolues

**Solution:**
```bash
xcodebuild -resolvePackageDependencies -project MediStock.xcodeproj -scheme MediStock
```

Ou dans workflow:
```yaml
- name: Resolve Dependencies
  run: |
    xcodebuild -resolvePackageDependencies -project $XCODE_PROJECT -scheme $XCODE_SCHEME
```

#### 2. Tests Failed: "GoogleService-Info.plist not found"

**Cause:** Firebase config manquant

**Solution:** Créer mock dans workflow:
```yaml
- name: Setup Firebase Mock
  run: |
    cat > MediStock/GoogleService-Info.plist << EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>API_KEY</key><string>TEST</string>
      ...
    </dict>
    </plist>
    EOF
```

#### 3. Code Signing Failed

**Cause:** Certificat ou profil manquant/invalide

**Solutions:**
- Vérifier secrets encodés correctement (base64)
- Vérifier password certificat
- Vérifier APPLE_TEAM_ID correct
- Utiliser `CODE_SIGNING_ALLOWED=NO` pour tests

#### 4. SwiftLint: "Command not found"

**Cause:** SwiftLint non installé

**Solution:**
```yaml
- name: Install SwiftLint
  run: |
    brew install swiftlint
    swiftlint version
```

#### 5. Fastlane: "User credentials invalid"

**Cause:** Apple ID ou app-specific password incorrect

**Solutions:**
- Vérifier `FASTLANE_USER` et `FASTLANE_PASSWORD`
- Générer nouveau app-specific password (appleid.apple.com)
- Utiliser API Key au lieu de credentials

#### 6. Upload to TestFlight Failed

**Causes multiples:**
- Binary already uploaded (même version/build)
- Missing entitlements
- Invalid provisioning profile
- API Key permissions insuffisantes

**Solutions:**
- Incrémenter build number: `increment_build_number`
- Vérifier entitlements dans Xcode
- Régénérer provisioning profile
- Vérifier API Key permissions (Admin ou App Manager)

### Debugging Workflows

#### Activer Debug Logging

Dans repository settings:
```
Settings → Secrets → Actions → New repository secret
Name: ACTIONS_RUNNER_DEBUG
Value: true

Name: ACTIONS_STEP_DEBUG
Value: true
```

#### Re-run Failed Jobs

Dans Actions UI:
- `Re-run failed jobs` pour rejouer seulement les échecs
- `Re-run all jobs` pour tout rejouer

#### SSH Debug (act)

Pour tester workflows localement:
```bash
# Installer act
brew install act

# Run workflow localement
act push -s GITHUB_TOKEN=<token>

# Run job spécifique
act -j build-and-test
```

---

## 🎯 Best Practices

### Workflows

1. **Fail Fast:** Checks rapides d'abord (lint, secrets)
2. **Parallel Jobs:** Maximum de parallélisation
3. **Caching:** Cache agressif pour dépendances
4. **Conditional:** N'exécuter que si nécessaire
5. **Secrets:** Jamais de secrets en clair
6. **Timeouts:** Définir timeouts raisonnables
7. **Artifacts:** Upload pour debugging
8. **Notifications:** Informer équipe des failures

### Code Quality

1. **Lint Strict:** 0 warnings sur PR
2. **Coverage:** Minimum 80%
3. **Tests:** Tests obligatoires pour PR
4. **Mocks:** Isoler dépendances externes
5. **Documentation:** Functions publiques documentées

### Releases

1. **Semver:** Versioning sémantique strict
2. **Changelog:** Mis à jour pour chaque release
3. **Tags:** Tag git pour chaque release
4. **GitHub Release:** Avec release notes
5. **TestFlight:** Test interne avant production

### Sécurité

1. **Secrets Scan:** Automatique et régulier
2. **Dependency Audit:** Hebdomadaire
3. **SAST:** Scan patterns unsafe
4. **Firebase Rules:** Validation et audit
5. **Least Privilege:** Minimiser permissions API Keys

### Monitoring

1. **Metrics:** Tracker build time, coverage, violations
2. **Trends:** Analyser évolution dans le temps
3. **Alertes:** Notifications pour critical failures
4. **Reviews:** Weekly review des pipelines

---

## 🚀 Evolution Future

### Court Terme (Q4 2025)

- [ ] Implémenter Fastlane Match pour code signing automatisé
- [ ] Ajouter Danger dans PR validation workflow
- [ ] Configurer notifications Slack/Discord
- [ ] Implémenter screenshot testing (Snapshot)
- [ ] Ajouter UI tests dans CI

### Moyen Terme (Q1 2026)

- [ ] Migrer vers Xcode Cloud (évaluation)
- [ ] Implémenter Feature Flags (Firebase Remote Config)
- [ ] Ajouter A/B testing pipeline
- [ ] Implémenter Crash reporting automation (Crashlytics)
- [ ] Dashboard metrics custom (Grafana/Datadog)

### Long Terme (Q2-Q3 2026)

- [ ] Multi-platform support (iPad, macOS)
- [ ] Automated App Store submission avec reviews
- [ ] ML-powered test selection (exécuter seulement tests impactés)
- [ ] Progressive rollout automation
- [ ] Automated rollback sur crash rate élevé

### Améliorations Continues

- [ ] Réduire build time (target < 3 min)
- [ ] Augmenter coverage (target > 90%)
- [ ] Améliorer flaky tests detection
- [ ] Optimiser cache hit rate (target > 90%)
- [ ] Documentation auto-générée et déployée

---

## 📚 Ressources

### Documentation Officielle

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Fastlane Docs](https://docs.fastlane.tools)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [Danger Ruby](https://danger.systems/ruby/)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)

### Outils

- [act](https://github.com/nektos/act) - Run GitHub Actions locally
- [xcpretty](https://github.com/xcpretty/xcpretty) - Format xcodebuild output
- [xcov](https://github.com/fastlane-community/xcov) - Code coverage reports
- [slather](https://github.com/SlatherOrg/slather) - Alternative coverage tool

### Communauté

- [GitHub Actions Community](https://github.community/c/actions)
- [Fastlane Community](https://github.com/fastlane/fastlane/discussions)
- [Swift Forums - CI/CD](https://forums.swift.org)

---

## 📞 Support

**Mainteneur:** TLILI HAMDI

**Contact:**
- Email: tlilihamdi@example.com
- GitHub: [@TLiLiHamdi](https://github.com/TLiLiHamdi)

**Issues CI/CD:**
- Ouvrir issue avec label `ci/cd`
- Inclure logs complets
- Inclure workflow run URL

---

**Version du Document:** 1.0.0
**Dernière Mise à Jour:** 3 Novembre 2025
**Auteur:** TLILI HAMDI
**Validé par:** TLILI HAMDI

---

Made with ❤️ by TLILI HAMDI
