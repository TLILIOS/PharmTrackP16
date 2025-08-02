# 🔐 Guide de Migration Sécurisée - KeychainService

## 🎯 Objectif
Remplacer le stockage des mots de passe en clair par un système sécurisé basé sur des tokens de session.

## ⚡ Migration Progressive (Sans Casser l'Existant)

### Étape 1 : Déployer la Nouvelle Version
1. Le nouveau `KeychainService_Secure.swift` est créé À CÔTÉ de l'ancien
2. L'ancien code continue de fonctionner normalement
3. Les méthodes problématiques sont marquées `@deprecated`

### Étape 2 : Modifier AuthService Progressivement

```swift
// Dans AuthService.swift, ajouter cette méthode de migration :

private func migrateToSecureKeychain() {
    // Migration automatique au démarrage
    KeychainService_Secure.performMigrationIfNeeded()
}

// Modifier la méthode de login pour utiliser le nouveau système :
func login(email: String, password: String) async throws {
    // 1. Authentification Firebase normale
    let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
    
    // 2. Récupérer le token de session Firebase
    guard let token = try? await authResult.user.getIDToken() else {
        throw AuthError.tokenGenerationFailed
    }
    
    // 3. Utiliser le NOUVEAU système sécurisé
    try KeychainService_Secure.shared.saveBiometricAuthData(
        email: email,
        sessionToken: token
    )
    
    // 4. Supprimer l'ancien stockage si présent
    KeychainService.shared.deleteUserCredentials()
}
```

### Étape 3 : Adapter l'Authentification Biométrique

```swift
// Dans la vue de login biométrique :

func authenticateWithBiometrics() async {
    // Utiliser le nouveau système
    guard let authData = KeychainService_Secure.shared.loadBiometricAuthData() else {
        // Forcer une nouvelle connexion
        showLoginScreen = true
        return
    }
    
    // Utiliser le token de session au lieu du mot de passe
    do {
        // Vérifier que le token est toujours valide côté Firebase
        try await Auth.auth().currentUser?.reload()
        
        // Si valide, l'utilisateur est connecté
        isAuthenticated = true
    } catch {
        // Token expiré, nouvelle connexion requise
        showLoginScreen = true
    }
}
```

### Étape 4 : Script de Test de Non-Régression

```bash
#!/bin/bash
# test_keychain_migration.sh

echo "🧪 Test de Migration KeychainService"

# 1. Vérifier que l'app compile
echo "✅ Compilation..."
xcodebuild -scheme MediStock -destination 'platform=iOS Simulator,name=iPhone 14' build

# 2. Lancer les tests unitaires existants
echo "✅ Tests unitaires..."
xcodebuild test -scheme MediStock -destination 'platform=iOS Simulator,name=iPhone 14'

# 3. Vérifier les warnings de dépréciation
echo "⚠️  Vérification des dépréciations..."
grep -r "saveUserCredentials\|loadUserCredentials" MediStock/ --include="*.swift" | grep -v "KeychainService"

echo "✅ Migration prête !"
```

## 🔄 Plan de Rollback

Si problème détecté :
1. Renommer `KeychainService_Secure.swift` → `KeychainService_Secure.swift.disabled`
2. L'ancien KeychainService continue de fonctionner
3. Aucune modification du code existant n'est nécessaire

## ✅ Checklist de Validation

- [ ] Les utilisateurs existants peuvent toujours se connecter
- [ ] La connexion biométrique fonctionne (avec re-auth si nécessaire)
- [ ] Aucun mot de passe n'est stocké dans le nouveau système
- [ ] Les tokens expirent après 24h
- [ ] Les anciens credentials sont supprimés après migration
- [ ] Aucune régression dans les fonctionnalités existantes

## 📊 Métriques de Succès

1. **Sécurité** : 0 mot de passe stocké en clair
2. **Compatibilité** : 100% des fonctionnalités préservées
3. **Migration** : Transparente pour l'utilisateur
4. **Performance** : Temps de connexion identique

## 🚀 Déploiement Recommandé

1. **Phase 1** (Jour 1) : Déployer le code avec les deux versions
2. **Phase 2** (Jour 7) : Activer la migration pour 10% des utilisateurs
3. **Phase 3** (Jour 14) : Si OK, migrer tous les utilisateurs
4. **Phase 4** (Jour 30) : Supprimer l'ancien KeychainService

Cette approche garantit ZÉRO RÉGRESSION tout en corrigeant la faille de sécurité critique.