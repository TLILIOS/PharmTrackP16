# Guide Configuration GitHub Secrets - MediStock CI/CD

**Projet** : MediStock - Application iOS
**Auteur** : TLILI HAMDI
**Date** : 2025-11-04
**Version** : 1.0.0

---

## Table des matières

1. [Introduction](#introduction)
2. [Accès GitHub Secrets](#accès-github-secrets)
3. [Secrets Essentiels (CI/CD Basique)](#secrets-essentiels-cicd-basique)
4. [Secrets Release (TestFlight/App Store)](#secrets-release-testflight--app-store)
5. [Secrets Optionnels](#secrets-optionnels)
6. [Procédures de Configuration](#procédures-de-configuration)
7. [Validation et Tests](#validation-et-tests)
8. [Rotation et Sécurité](#rotation-et-sécurité)
9. [Troubleshooting](#troubleshooting)

---

## Introduction

Ce guide détaille la configuration complète des **GitHub Secrets** nécessaires au bon fonctionnement du pipeline CI/CD de MediStock.

### Niveaux de Configuration

Le pipeline CI/CD fonctionne à plusieurs niveaux selon les secrets configurés :

| Niveau | Secrets requis | Fonctionnalités disponibles |
|--------|---------------|----------------------------|
| **Basique** | Firebase uniquement | ✅ Build, ✅ Tests unitaires, ✅ SwiftLint |
| **Standard** | + Signing minimal | ✅ + Archive Release |
| **Complet** | + TestFlight | ✅ + Upload TestFlight, ✅ GitHub Releases |
| **Premium** | + Notifications | ✅ + Alertes Slack/Discord |

### Prérequis

Avant de commencer, assurez-vous d'avoir :

- [ ] Accès admin au repository GitHub
- [ ] Compte Apple Developer (pour secrets release)
- [ ] Accès Firebase Console (pour secrets Firebase)
- [ ] Certificats iOS de distribution
- [ ] Profils de provisioning configurés
- [ ] (Optionnel) Workspace Slack/Discord

---

## Accès GitHub Secrets

### Navigation

1. Accédez au repository GitHub : `https://github.com/<owner>/MediStock`
2. Cliquez sur **Settings** (onglet en haut)
3. Dans le menu latéral gauche :
   - **Security** → **Secrets and variables** → **Actions**
4. Cliquez sur **New repository secret**

### Interface

```
Repository Settings
├── Security
│   ├── Secrets and variables
│   │   ├── Actions
│   │   │   ├── Secrets (🔐 configuration secrets)
│   │   │   └── Variables (📝 configuration variables)
│   │   ├── Codespaces
│   │   └── Dependabot
```

### Permissions Requises

- **Admin** : Peut créer, modifier, supprimer tous les secrets
- **Write** : Peut déclencher workflows (les secrets sont masqués)
- **Read** : Lecture seule (pas d'accès aux secrets)

### Bonnes Pratiques Sécurité

✅ **À FAIRE** :
- Utiliser secrets pour toutes les données sensibles
- Rotation régulière (tous les 6 mois minimum)
- Documentation accès (qui a configuré quoi)
- Audit logs actif

❌ **À ÉVITER** :
- Hard-coder secrets dans code source
- Commiter secrets dans Git (même temporairement)
- Partager secrets via email/Slack
- Réutiliser mêmes secrets pour dev/prod

---

## Secrets Essentiels (CI/CD Basique)

Ces secrets sont **requis** pour le fonctionnement minimal du pipeline (build + tests).

### 1. FIREBASE_API_KEY

**Description** : Clé API Firebase pour environnement CI/CD (staging)

**Obtention** :

1. Accédez à [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet MediStock
3. **Project Settings** (⚙️) → **General**
4. Descendez à **Your apps** → Section iOS app
5. Copiez la valeur `apiKey` depuis `GoogleService-Info.plist`

Exemple de `GoogleService-Info.plist` :
```xml
<key>API_KEY</key>
<string>AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567</string>
```

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `FIREBASE_API_KEY` |
| **Secret** | `AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567` (votre clé) |

**Utilisation dans workflow** :
```yaml
- name: Setup Firebase
  env:
    FIREBASE_API_KEY: ${{ secrets.FIREBASE_API_KEY }}
  run: |
    echo "Setting up Firebase with API key"
```

**⚠️ Sécurité** :
- Utilisez une clé dédiée pour CI (pas production)
- Configurez restrictions Firebase Console (quota, IP, etc.)
- Rotation tous les 6 mois

---

### 2. GOOGLE_SERVICE_INFO_PLIST

**Description** : Fichier `GoogleService-Info.plist` encodé en base64 pour configuration Firebase complète

**Obtention** :

1. Téléchargez `GoogleService-Info.plist` depuis Firebase Console :
   - **Project Settings** → **General** → **Your apps**
   - Cliquez sur iOS app
   - **Download GoogleService-Info.plist**

2. Encodez en base64 :
```bash
# macOS/Linux
base64 -i GoogleService-Info.plist | tr -d '\n' | pbcopy

# Résultat copié dans clipboard
# Exemple : PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0...
```

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `GOOGLE_SERVICE_INFO_PLIST` |
| **Secret** | `PD94bWwgdmVyc2lvbj0iMS4wIi...` (chaîne base64 complète) |

**Utilisation dans workflow** :
```yaml
- name: Setup Firebase Config
  run: |
    echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}" | base64 --decode > MediStock/GoogleService-Info.plist
```

**⚠️ Important** :
- Utilisez fichier staging/CI (pas production)
- Ne committez jamais ce fichier dans Git
- Ajoutez dans `.gitignore` :
```
# Firebase
GoogleService-Info.plist
```

---

## Secrets Release (TestFlight / App Store)

Ces secrets sont requis pour :
- Création archive release
- Code signing
- Upload TestFlight
- Distribution App Store

### 3. IOS_CERTIFICATE_P12

**Description** : Certificat de distribution iOS au format .p12 (PKCS#12) encodé base64

**Obtention** :

#### Étape 1 : Exporter certificat depuis Keychain

1. Ouvrez **Keychain Access** (Trousseau d'accès) sur macOS
2. Sélectionnez keychain **login**
3. Catégorie **My Certificates** (Mes certificats)
4. Trouvez certificat **"Apple Distribution: <Votre Nom/Organisation>"**
5. Faites clic droit → **Export "Apple Distribution..."**
6. Format : **Personal Information Exchange (.p12)**
7. Nom fichier : `ios_distribution.p12`
8. **Définissez un mot de passe fort** (vous en aurez besoin pour `CERTIFICATE_PASSWORD`)

#### Étape 2 : Encoder en base64

```bash
# macOS/Linux
base64 -i ios_distribution.p12 | tr -d '\n' | pbcopy

# Résultat copié dans clipboard
```

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `IOS_CERTIFICATE_P12` |
| **Secret** | `MIIKfAIBAzCCCjoGCSqGSIb3DQEHA...` (chaîne base64) |

**Utilisation dans workflow** :
```yaml
- name: Import Certificate
  env:
    CERTIFICATE_P12: ${{ secrets.IOS_CERTIFICATE_P12 }}
    CERTIFICATE_PASSWORD: ${{ secrets.CERTIFICATE_PASSWORD }}
  run: |
    echo "$CERTIFICATE_P12" | base64 --decode > certificate.p12
    security import certificate.p12 \
      -k ~/Library/Keychains/build.keychain-db \
      -P "$CERTIFICATE_PASSWORD" \
      -T /usr/bin/codesign
```

**⚠️ Sécurité** :
- Protégez le fichier .p12 source (ne pas partager)
- Mot de passe complexe (12+ caractères)
- Supprimez fichier .p12 local après usage
- Rotation annuelle (ou lors de renouvellement certificat)

---

### 4. IOS_PROVISIONING_PROFILE

**Description** : Profil de provisioning (distribution) encodé base64

**Obtention** :

#### Étape 1 : Télécharger depuis Apple Developer

1. Accédez à [Apple Developer Portal](https://developer.apple.com/account)
2. **Certificates, IDs & Profiles**
3. **Profiles** (menu gauche)
4. Sélectionnez votre profil **App Store** ou **Ad Hoc**
   - Type : Distribution
   - App ID : correspondant à MediStock
5. Cliquez **Download**
6. Fichier téléchargé : `MediStock_AppStore.mobileprovision`

#### Étape 2 : Encoder en base64

```bash
# macOS/Linux
base64 -i MediStock_AppStore.mobileprovision | tr -d '\n' | pbcopy
```

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `IOS_PROVISIONING_PROFILE` |
| **Secret** | `MIIQPQYJKoZIhvcNAQcCoIIQLj...` (chaîne base64) |

**Utilisation dans workflow** :
```yaml
- name: Import Provisioning Profile
  env:
    PROVISIONING_PROFILE: ${{ secrets.IOS_PROVISIONING_PROFILE }}
  run: |
    PP_PATH="$HOME/Library/MobileDevice/Provisioning Profiles"
    mkdir -p "$PP_PATH"
    echo "$PROVISIONING_PROFILE" | base64 --decode > "$PP_PATH/profile.mobileprovision"
```

**⚠️ Important** :
- Profil doit correspondre au Bundle ID app
- Doit inclure certificat de distribution
- Vérifier date d'expiration (renouveler avant)
- Devices enregistrés (pour Ad Hoc)

---

### 5. CERTIFICATE_PASSWORD

**Description** : Mot de passe du certificat .p12

**Obtention** : Le mot de passe que vous avez défini lors de l'export du certificat (étape 3)

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `CERTIFICATE_PASSWORD` |
| **Secret** | `VotreMotDePasseFort123!` |

**⚠️ Sécurité** :
- Minimum 12 caractères
- Combinaison majuscules, minuscules, chiffres, symboles
- Ne pas réutiliser de mot de passe existant
- Stockage sécurisé (gestionnaire mots de passe)

---

### 6. KEYCHAIN_PASSWORD

**Description** : Mot de passe du keychain temporaire créé par GitHub Actions

**Obtention** : Générez un mot de passe aléatoire fort (ne sera jamais utilisé localement)

```bash
# Générer mot de passe aléatoire
openssl rand -base64 32
# Exemple : a8sKx93jLm2pQrT5vWyZ4fB1nC6hD9eE
```

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `KEYCHAIN_PASSWORD` |
| **Secret** | `a8sKx93jLm2pQrT5vWyZ4fB1nC6hD9eE` |

**Utilisation dans workflow** :
```yaml
- name: Create Keychain
  env:
    KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
  run: |
    security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
    security set-keychain-settings -lut 21600 build.keychain
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
```

---

### 7. APPLE_TEAM_ID

**Description** : Identifiant unique de votre Apple Developer Team

**Obtention** :

**Méthode 1 : Apple Developer Portal**
1. [Apple Developer Account](https://developer.apple.com/account)
2. **Membership** (menu gauche)
3. Section **Team ID** : `A1B2C3D4E5` (10 caractères alphanumériques)

**Méthode 2 : Depuis Xcode**
1. Ouvrez projet dans Xcode
2. Sélectionnez target app
3. **Signing & Capabilities**
4. Team : dropdown affiche nom et **(A1B2C3D4E5)**

**Méthode 3 : Depuis certificat**
```bash
# Afficher détails certificat
security find-identity -v -p codesigning | grep "Apple Distribution"
# Output contient : (A1B2C3D4E5)
```

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `APPLE_TEAM_ID` |
| **Secret** | `A1B2C3D4E5` (votre Team ID) |

**Utilisation dans workflow** :
```yaml
- name: Build with Code Signing
  run: |
    xcodebuild archive \
      -scheme MediStock \
      DEVELOPMENT_TEAM=${{ secrets.APPLE_TEAM_ID }}
```

---

### 8. APPLE_ID

**Description** : Email Apple ID utilisé pour App Store Connect

**Obtention** : Votre email Apple Developer account

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `APPLE_ID` |
| **Secret** | `votre.email@example.com` |

**⚠️ Important** :
- Utilisez email principal Apple Developer
- Doit avoir rôle **Admin** ou **App Manager** dans App Store Connect
- Authentification 2-facteurs activée (requis)

---

### 9. APP_SPECIFIC_PASSWORD

**Description** : Mot de passe spécifique à l'app pour authentification CI/CD

**Obtention** :

1. Accédez à [appleid.apple.com](https://appleid.apple.com)
2. Connectez-vous avec votre Apple ID
3. Section **Security** → **App-Specific Passwords**
4. Cliquez **Generate an app-specific password...**
5. Label : `GitHub Actions MediStock CI`
6. Copiez mot de passe généré : `abcd-efgh-ijkl-mnop` (format avec tirets)

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `APP_SPECIFIC_PASSWORD` |
| **Secret** | `abcd-efgh-ijkl-mnop` |

**Utilisation dans workflow** :
```yaml
- name: Upload to TestFlight
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    APP_PASSWORD: ${{ secrets.APP_SPECIFIC_PASSWORD }}
  run: |
    xcrun altool --upload-app \
      --type ios \
      --file MediStock.ipa \
      --username "$APPLE_ID" \
      --password "$APP_PASSWORD"
```

**⚠️ Sécurité** :
- Un mot de passe par service (créez-en un dédié pour GitHub Actions)
- Révocable à tout moment depuis appleid.apple.com
- Expiration : aucune (mais rotation recommandée annuellement)
- Ne fonctionne que pour CLI tools (pas login web)

---

## Secrets Optionnels

Ces secrets activent des fonctionnalités avancées mais ne sont pas requis pour le fonctionnement basique.

### 10. SLACK_WEBHOOK (Optionnel)

**Description** : URL webhook pour notifications Slack

**Obtention** :

1. Accédez à votre workspace Slack
2. [Slack Apps](https://api.slack.com/apps) → **Create New App**
3. **From scratch** :
   - App Name : `MediStock CI/CD`
   - Workspace : sélectionnez votre workspace
4. **Incoming Webhooks** :
   - Activez **Activate Incoming Webhooks**
   - **Add New Webhook to Workspace**
   - Sélectionnez channel : `#ci-cd` ou `#dev`
5. Copiez **Webhook URL** :
   ```
   https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
   ```

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `SLACK_WEBHOOK` |
| **Secret** | `https://hooks.slack.com/services/...` |

**Utilisation dans workflow** :
```yaml
- name: Notify Slack
  if: always()
  env:
    SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
  run: |
    curl -X POST "$SLACK_WEBHOOK" \
      -H 'Content-Type: application/json' \
      -d '{
        "text": "🚀 MediStock Build: SUCCESS",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Status*: ✅ Success\n*Duration*: 15m 32s"
            }
          }
        ]
      }'
```

**Exemple message Slack** :
```
🚀 MediStock Build: SUCCESS

Status: ✅ Success
Duration: 15m 32s
Coverage: 84.2%
Branch: feature/ci-cd-pipeline
Commit: 2fb7b83 - cleanUpWarnings

View logs: [Link to GitHub Actions run]
```

---

### 11. DISCORD_WEBHOOK (Optionnel)

**Description** : URL webhook pour notifications Discord

**Obtention** :

1. Accédez à votre serveur Discord
2. Sélectionnez channel (ex: `#ci-cd`)
3. **Channel Settings** → **Integrations** → **Webhooks**
4. **New Webhook**
   - Name : `MediStock CI`
   - Channel : `#ci-cd`
   - Avatar : (optionnel)
5. **Copy Webhook URL** :
   ```
   https://discord.com/api/webhooks/123456789/abcdefghijklmnopqrstuvwxyz
   ```

**Configuration GitHub** :

| Champ | Valeur |
|-------|--------|
| **Name** | `DISCORD_WEBHOOK` |
| **Secret** | `https://discord.com/api/webhooks/...` |

**Utilisation dans workflow** :
```yaml
- name: Notify Discord
  if: always()
  env:
    DISCORD_WEBHOOK: ${{ secrets.DISCORD_WEBHOOK }}
  run: |
    curl -X POST "$DISCORD_WEBHOOK" \
      -H 'Content-Type: application/json' \
      -d '{
        "content": "🚀 **MediStock Build**",
        "embeds": [{
          "title": "Build Success",
          "description": "Branch: feature/ci-cd-pipeline",
          "color": 3066993,
          "fields": [
            {"name": "Status", "value": "✅ Success", "inline": true},
            {"name": "Duration", "value": "15m 32s", "inline": true},
            {"name": "Coverage", "value": "84.2%", "inline": true}
          ]
        }]
      }'
```

---

### 12. GITHUB_TOKEN (Auto-fourni)

**Description** : Token authentification GitHub (géré automatiquement)

**⚠️ Important** : Ce secret est **automatiquement fourni** par GitHub Actions. Vous n'avez PAS besoin de le configurer manuellement.

**Utilisation dans workflow** :
```yaml
- name: Comment on PR
  uses: actions/github-script@v6
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    script: |
      github.rest.issues.createComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.issue.number,
        body: '✅ Build successful!'
      })
```

**Permissions** :
- Configurables dans workflow :
```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
```

---

## Procédures de Configuration

### Configuration Complète Étape par Étape

#### Phase 1 : Secrets Basiques (CI/CD minimal)

**Durée estimée** : 15 minutes

1. **Firebase Configuration**
   ```bash
   # 1. Télécharger GoogleService-Info.plist depuis Firebase Console
   # 2. Encoder en base64
   base64 -i GoogleService-Info.plist | tr -d '\n' | pbcopy
   # 3. Ajouter secret GOOGLE_SERVICE_INFO_PLIST dans GitHub

   # 4. Extraire API key
   API_KEY=$(plutil -extract API_KEY xml1 -o - GoogleService-Info.plist | grep -oP '(?<=<string>)[^<]+')
   echo $API_KEY | pbcopy
   # 5. Ajouter secret FIREBASE_API_KEY dans GitHub
   ```

2. **Validation**
   ```bash
   # Déclencher workflow ci.yml
   # Vérifier que build + tests passent
   ```

**✅ Checkpoint** : À ce stade, vous pouvez exécuter builds et tests unitaires.

---

#### Phase 2 : Secrets Release (Archives)

**Durée estimée** : 30 minutes

1. **Certificat iOS**
   ```bash
   # 1. Exporter certificat depuis Keychain (ios_distribution.p12)
   # 2. Encoder
   base64 -i ios_distribution.p12 | tr -d '\n' | pbcopy
   # 3. Ajouter secret IOS_CERTIFICATE_P12

   # 4. Ajouter secret CERTIFICATE_PASSWORD (mot de passe défini lors export)
   ```

2. **Provisioning Profile**
   ```bash
   # 1. Télécharger depuis Apple Developer Portal
   # 2. Encoder
   base64 -i MediStock_AppStore.mobileprovision | tr -d '\n' | pbcopy
   # 3. Ajouter secret IOS_PROVISIONING_PROFILE
   ```

3. **Apple Team**
   ```bash
   # 1. Récupérer Team ID depuis developer.apple.com
   # 2. Ajouter secret APPLE_TEAM_ID
   ```

4. **Keychain Password**
   ```bash
   # 1. Générer mot de passe aléatoire
   openssl rand -base64 32 | pbcopy
   # 2. Ajouter secret KEYCHAIN_PASSWORD
   ```

5. **Validation**
   ```bash
   # Déclencher workflow main-ci.yml
   # Vérifier que job "Build Release Archive" passe
   ```

**✅ Checkpoint** : À ce stade, vous pouvez créer archives et IPA signés.

---

#### Phase 3 : Secrets TestFlight (Distribution)

**Durée estimée** : 15 minutes

1. **Apple ID**
   ```bash
   # 1. Confirmer email Apple Developer account
   # 2. Ajouter secret APPLE_ID
   ```

2. **App-Specific Password**
   ```bash
   # 1. Générer depuis appleid.apple.com
   # 2. Ajouter secret APP_SPECIFIC_PASSWORD
   ```

3. **Validation**
   ```bash
   # 1. Créer tag release test
   git tag -a v0.0.1-test -m "Test release"
   git push origin v0.0.1-test

   # 2. Vérifier workflow release.yml
   # 3. Confirmer upload TestFlight dans App Store Connect
   ```

**✅ Checkpoint** : À ce stade, pipeline complet fonctionnel (build → test → release → TestFlight).

---

#### Phase 4 : Secrets Optionnels (Notifications)

**Durée estimée** : 10 minutes

1. **Slack**
   ```bash
   # 1. Créer webhook Slack (voir section 10)
   # 2. Ajouter secret SLACK_WEBHOOK
   # 3. Tester notification
   ```

2. **Discord**
   ```bash
   # 1. Créer webhook Discord (voir section 11)
   # 2. Ajouter secret DISCORD_WEBHOOK
   # 3. Tester notification
   ```

**✅ Checkpoint** : Notifications actives pour événements CI/CD.

---

### Script d'Aide Configuration

Script bash pour vérifier et préparer les secrets :

```bash
#!/bin/bash
# setup_secrets.sh - Helper script pour configuration secrets GitHub

echo "🔐 MediStock CI/CD - GitHub Secrets Setup Helper"
echo "================================================"
echo ""

# Fonction helper base64
encode_file() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo "❌ File not found: $file"
        return 1
    fi
    base64 -i "$file" | tr -d '\n'
}

# 1. Firebase
echo "📱 Firebase Configuration"
if [ -f "GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist found"
    echo "🔑 GOOGLE_SERVICE_INFO_PLIST (base64):"
    encode_file "GoogleService-Info.plist"
    echo ""

    echo "🔑 FIREBASE_API_KEY:"
    plutil -extract API_KEY xml1 -o - GoogleService-Info.plist | grep -oP '(?<=<string>)[^<]+'
    echo ""
else
    echo "❌ GoogleService-Info.plist not found"
    echo "   Download from Firebase Console"
fi
echo ""

# 2. iOS Certificate
echo "🔒 iOS Certificate"
if [ -f "ios_distribution.p12" ]; then
    echo "✅ ios_distribution.p12 found"
    echo "🔑 IOS_CERTIFICATE_P12 (base64):"
    encode_file "ios_distribution.p12"
    echo ""
    echo "⚠️  Don't forget to set CERTIFICATE_PASSWORD secret!"
else
    echo "❌ ios_distribution.p12 not found"
    echo "   Export from Keychain Access"
fi
echo ""

# 3. Provisioning Profile
echo "📄 Provisioning Profile"
PROFILE=$(find . -name "*.mobileprovision" -print -quit)
if [ -n "$PROFILE" ]; then
    echo "✅ Provisioning profile found: $PROFILE"
    echo "🔑 IOS_PROVISIONING_PROFILE (base64):"
    encode_file "$PROFILE"
    echo ""
else
    echo "❌ .mobileprovision not found"
    echo "   Download from Apple Developer Portal"
fi
echo ""

# 4. Apple Team ID
echo "🍎 Apple Developer"
echo "🔑 APPLE_TEAM_ID:"
security find-identity -v -p codesigning | grep "Apple Distribution" | sed -E 's/.*\(([A-Z0-9]{10})\).*/\1/' | head -1
echo ""

# 5. Keychain Password
echo "🔐 Keychain Password (generate random)"
echo "🔑 KEYCHAIN_PASSWORD:"
openssl rand -base64 32
echo ""

echo "✅ Configuration complete!"
echo ""
echo "Next steps:"
echo "1. Copy each value above"
echo "2. Add as secret in GitHub repository settings"
echo "3. Set APPLE_ID (your Apple Developer email)"
echo "4. Generate APP_SPECIFIC_PASSWORD at appleid.apple.com"
echo "5. Validate with workflow run"
```

**Usage** :
```bash
chmod +x setup_secrets.sh
./setup_secrets.sh > secrets_output.txt

# ⚠️ IMPORTANT : Supprimez ce fichier après usage !
# Il contient des valeurs sensibles
rm secrets_output.txt
```

---

## Validation et Tests

### Checklist Validation

Après configuration des secrets, validez chaque niveau :

#### ✅ Niveau 1 : CI Basique

- [ ] Secret `FIREBASE_API_KEY` configuré
- [ ] Secret `GOOGLE_SERVICE_INFO_PLIST` configuré
- [ ] Workflow `ci.yml` s'exécute sans erreur
- [ ] Tests unitaires passent
- [ ] Logs ne révèlent pas de secrets (vérifier masking)

**Test** :
```bash
# Créer PR test
git checkout -b test/secrets-validation
git commit --allow-empty -m "test: validate CI secrets"
git push origin test/secrets-validation
gh pr create --title "Test CI Secrets" --body "Validation configuration"

# Vérifier logs GitHub Actions
gh run list --workflow=ci.yml --limit 1
gh run view --log
```

---

#### ✅ Niveau 2 : Release Archive

- [ ] Secrets niveau 1 ✅
- [ ] Secret `IOS_CERTIFICATE_P12` configuré
- [ ] Secret `CERTIFICATE_PASSWORD` configuré
- [ ] Secret `IOS_PROVISIONING_PROFILE` configuré
- [ ] Secret `APPLE_TEAM_ID` configuré
- [ ] Secret `KEYCHAIN_PASSWORD` configuré
- [ ] Workflow `main-ci.yml` job "Build Release Archive" réussit
- [ ] Artefact IPA généré et téléchargeable

**Test** :
```bash
# Merge vers main (ou push direct si permis)
git checkout main
git merge test/secrets-validation
git push origin main

# Vérifier job Archive
gh run list --workflow=main-ci.yml --limit 1
gh run view

# Télécharger artefacts
gh run download <run-id> --name MediStock-ipa
```

---

#### ✅ Niveau 3 : TestFlight

- [ ] Secrets niveau 2 ✅
- [ ] Secret `APPLE_ID` configuré
- [ ] Secret `APP_SPECIFIC_PASSWORD` configuré
- [ ] Workflow `release.yml` s'exécute complètement
- [ ] Upload TestFlight réussit
- [ ] Build visible dans App Store Connect

**Test** :
```bash
# Créer tag release test
git tag -a v0.0.1-test -m "Test release secrets"
git push origin v0.0.1-test

# Vérifier workflow
gh run list --workflow=release.yml --limit 1
gh run view

# Vérifier App Store Connect
# → TestFlight → Builds → MediStock → Version 0.0.1-test doit apparaître
```

---

#### ✅ Niveau 4 : Notifications

- [ ] Secrets niveau 3 ✅
- [ ] Secret `SLACK_WEBHOOK` configuré (optionnel)
- [ ] Secret `DISCORD_WEBHOOK` configuré (optionnel)
- [ ] Notification reçue dans Slack/Discord après workflow

**Test** :
```bash
# Déclencher workflow avec notification
# Vérifier réception message dans channel configuré
```

---

### Tests de Sécurité

#### Vérification Masking Secrets

GitHub Actions masque automatiquement les secrets dans les logs. Vérifiez :

```yaml
# Workflow de test (NE PAS utiliser en production)
- name: Test Secret Masking
  env:
    TEST_SECRET: ${{ secrets.FIREBASE_API_KEY }}
  run: |
    echo "Secret value: $TEST_SECRET"
    # Output attendu : Secret value: ***
```

**❌ Si le secret apparaît en clair** :
1. Secret mal configuré (espace/retour ligne)
2. Révéler via `set -x` (désactiver)
3. Secret trop court (<3 caractères, non masqué)

---

#### Audit Logs

Consultez l'audit trail pour changements secrets :

1. Repository **Settings**
2. **Security** → **Audit log**
3. Filtrer par actions :
   - `secret.created`
   - `secret.updated`
   - `secret.removed`

**Vérifiez** :
- Qui a créé/modifié secrets
- Quand (détection accès non autorisé)
- Patterns suspects

---

## Rotation et Sécurité

### Planning Rotation

| Secret | Fréquence | Déclencheurs |
|--------|-----------|--------------|
| `FIREBASE_API_KEY` | 6 mois | Changement équipe, incident sécurité |
| `GOOGLE_SERVICE_INFO_PLIST` | 6 mois | Mise à jour config Firebase |
| `IOS_CERTIFICATE_P12` | 1 an | Expiration certificat |
| `CERTIFICATE_PASSWORD` | 1 an | Avec certificat |
| `IOS_PROVISIONING_PROFILE` | 3-12 mois | Expiration profil |
| `APPLE_TEAM_ID` | Jamais | (Immuable) |
| `APPLE_ID` | Jamais | Changement compte Apple |
| `APP_SPECIFIC_PASSWORD` | 1 an | Compromission suspectée |
| `KEYCHAIN_PASSWORD` | 6 mois | Incident sécurité |
| `SLACK_WEBHOOK` | 1 an | Changement canal/équipe |
| `DISCORD_WEBHOOK` | 1 an | Changement serveur |

### Procédure Rotation

#### Exemple : Rotation APP_SPECIFIC_PASSWORD

1. **Générer nouveau mot de passe**
   - appleid.apple.com → App-Specific Passwords
   - Generate new password : `wxyz-abcd-efgh-ijkl`

2. **Mettre à jour secret GitHub**
   - Settings → Secrets → `APP_SPECIFIC_PASSWORD`
   - Update : coller nouvelle valeur

3. **Tester workflow**
   ```bash
   # Déclencher release test
   gh workflow run release.yml --ref main
   ```

4. **Révoquer ancien mot de passe**
   - appleid.apple.com → App-Specific Passwords
   - Supprimer ancien password

5. **Documenter**
   - Noter date rotation dans documentation interne
   - Mettre à jour inventaire secrets

---

### Gestion Incidents

#### Scénario : Secret Compromis

**Symptômes** :
- Secret commité dans Git
- Partagé via canal non sécurisé
- Détecté dans logs publics
- Suspicion accès non autorisé

**Actions immédiates** :

1. **Révoquer secret compromis**
   ```bash
   # Exemple : Certificate compromis
   # → Révoquer via Apple Developer Portal

   # App-specific password
   # → Révoquer via appleid.apple.com
   ```

2. **Supprimer de GitHub**
   - Settings → Secrets → Delete secret compromis

3. **Générer nouveau secret**
   - Suivre procédure configuration initiale

4. **Audit commits**
   ```bash
   # Rechercher secret dans historique Git
   git log --all --source --full-history -S "SECRET_VALUE"

   # Si trouvé : considérer git-filter-repo pour nettoyage
   ```

5. **Notification équipe**
   - Informer tous les membres
   - Documenter incident
   - Review procédures sécurité

---

### Backup Secrets

**⚠️ IMPORTANT** : Ne sauvegardez JAMAIS les secrets en clair dans des fichiers non chiffrés.

**Options sécurisées** :

1. **Gestionnaire mots de passe entreprise**
   - 1Password Teams/Business
   - LastPass Enterprise
   - Dashlane Business

2. **Vault (HashiCorp)**
   - Chiffrement end-to-end
   - Audit logs complets
   - Rotation automatique

3. **AWS Secrets Manager / Azure Key Vault**
   - Intégration cloud
   - Gestion accès IAM

**Format documentation** (sans valeurs) :
```yaml
# secrets_inventory.yml
# Date: 2025-11-04
# Maintainer: TLILI HAMDI

secrets:
  - name: FIREBASE_API_KEY
    type: API Key
    source: Firebase Console
    location: 1Password vault "MediStock CI"
    last_rotation: 2025-11-04
    next_rotation: 2025-05-04

  - name: IOS_CERTIFICATE_P12
    type: Certificate
    source: Apple Developer
    location: 1Password vault "MediStock CI"
    expiration: 2026-11-03
    last_rotation: 2025-11-04
```

---

## Troubleshooting

### Problème : Import Certificate Failed

**Symptôme** :
```
Error: security: SecKeychainItemImport: MAC verification failed during PKCS12 import
```

**Causes** :
1. `CERTIFICATE_PASSWORD` incorrect
2. Fichier .p12 corrompu lors encodage base64
3. Keychain déjà verrouillé

**Solutions** :
```bash
# 1. Vérifier password
# → Tester import localement avec même password

# 2. Re-encoder certificat
base64 -i ios_distribution.p12 | tr -d '\n' > cert_base64.txt
# Vérifier pas de retours ligne

# 3. Unlock keychain explicitement
security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
```

---

### Problème : Provisioning Profile Invalid

**Symptôme** :
```
error: No profiles for 'com.medistock.app' were found
```

**Causes** :
1. Bundle ID mismatch
2. Profil expiré
3. Certificat non inclus dans profil
4. Profil non importé correctement

**Solutions** :
```bash
# 1. Vérifier Bundle ID
# Info.plist : CFBundleIdentifier doit correspondre

# 2. Vérifier expiration profil
security cms -D -i profile.mobileprovision | grep -A 1 "ExpirationDate"

# 3. Lister certificats dans profil
security cms -D -i profile.mobileprovision | grep -A 40 "DeveloperCertificates"

# 4. Télécharger nouveau profil depuis Apple Developer Portal
```

---

### Problème : TestFlight Upload Failed

**Symptôme** :
```
Error: Unable to authenticate. Invalid username/password.
```

**Causes** :
1. `APPLE_ID` incorrect
2. `APP_SPECIFIC_PASSWORD` invalide/expiré
3. 2FA requis (non supporté sans app-specific password)
4. Compte sans permissions App Store Connect

**Solutions** :
```bash
# 1. Vérifier APPLE_ID
# → Email exact utilisé pour Apple Developer

# 2. Générer nouveau app-specific password
# → appleid.apple.com

# 3. Vérifier permissions App Store Connect
# → Rôle : Admin, App Manager, ou Developer

# 4. Test altool localement
xcrun altool --validate-app \
  --type ios \
  --file MediStock.ipa \
  --username "APPLE_ID" \
  --password "APP_PASSWORD"
```

---

### Problème : Secrets Not Masked in Logs

**Symptôme** : Secrets apparaissent en clair dans logs GitHub Actions

**Causes** :
1. Secret contient espaces/retours ligne
2. Secret trop court (<3 caractères)
3. Exposé via variable intermédiaire non protégée

**Solutions** :
```bash
# 1. Nettoyer secret (supprimer espaces/newlines)
echo "$SECRET" | tr -d '[:space:]' | pbcopy

# 2. Pour secrets courts : concaténer avec prefix
# Exemple : "PREFIX_short"

# 3. Éviter echo direct
# ❌ BAD:
echo "Secret: ${{ secrets.MY_SECRET }}"

# ✅ GOOD:
MY_VAR="${{ secrets.MY_SECRET }}"
# Utiliser $MY_VAR (masqué automatiquement)
```

---

### Problème : Firebase Setup Failed

**Symptôme** :
```
Error: GoogleService-Info.plist not found
```

**Causes** :
1. Secret `GOOGLE_SERVICE_INFO_PLIST` manquant
2. Décodage base64 échoué
3. Fichier placé dans mauvais répertoire

**Solutions** :
```yaml
# Workflow debugging
- name: Debug Firebase Setup
  run: |
    # Vérifier secret présent
    if [ -z "${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}" ]; then
      echo "❌ GOOGLE_SERVICE_INFO_PLIST secret not set"
      exit 1
    fi

    # Décoder et vérifier
    echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}" | base64 --decode > test.plist

    # Valider XML
    plutil -lint test.plist

    # Placer dans bon répertoire
    mv test.plist MediStock/GoogleService-Info.plist
    ls -la MediStock/GoogleService-Info.plist
```

---

## Conclusion

### Récapitulatif Configuration

**Minimum Viable (CI Basic)** :
- ✅ `FIREBASE_API_KEY`
- ✅ `GOOGLE_SERVICE_INFO_PLIST`

**Production Ready (Release)** :
- ✅ Secrets CI Basic
- ✅ `IOS_CERTIFICATE_P12`
- ✅ `CERTIFICATE_PASSWORD`
- ✅ `IOS_PROVISIONING_PROFILE`
- ✅ `APPLE_TEAM_ID`
- ✅ `KEYCHAIN_PASSWORD`

**Full Pipeline (TestFlight)** :
- ✅ Secrets Production Ready
- ✅ `APPLE_ID`
- ✅ `APP_SPECIFIC_PASSWORD`

**Enhanced (Notifications)** :
- ✅ Secrets Full Pipeline
- ✅ `SLACK_WEBHOOK` (optionnel)
- ✅ `DISCORD_WEBHOOK` (optionnel)

---

### Checklist Finale

- [ ] Tous les secrets requis configurés pour votre niveau cible
- [ ] Workflow test exécuté avec succès
- [ ] Secrets masqués correctement dans logs
- [ ] Documentation rotation planifiée (calendrier)
- [ ] Backup secrets dans gestionnaire mots de passe sécurisé
- [ ] Équipe formée sur procédures sécurité
- [ ] Audit logs GitHub configuré et surveillé
- [ ] Plan incident sécurité documenté

---

### Support

**Questions ou problèmes ?**

1. Consultez section [Troubleshooting](#troubleshooting)
2. Vérifiez logs GitHub Actions détaillés
3. Contactez : **TLILI HAMDI**

**Ressources** :
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)

---

**Document créé et validé par** : TLILI HAMDI
**Date** : 2025-11-04
**Version** : 1.0.0
**Dernière mise à jour** : 2025-11-04

---

*La sécurité de votre pipeline dépend de la protection de ces secrets. Suivez les bonnes pratiques et effectuez des rotations régulières.*
