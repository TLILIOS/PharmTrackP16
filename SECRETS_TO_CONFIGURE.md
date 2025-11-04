# 🔐 Configuration Secrets GitHub - Guide Pratique
**Date**: 2025-11-04
**Projet**: MediStock
**Par**: TLILI HAMDI

---

## ⚠️ IMPORTANT - Sécurité

Ce fichier contient des instructions pour configurer vos secrets GitHub.
**NE COMMITEZ JAMAIS CE FICHIER dans Git !**

Une fois la configuration terminée, **supprimez ce fichier**.

---

## 📋 Secrets à Configurer (Priorité Haute)

### Secret 1: FIREBASE_API_KEY

**Valeur à copier** :
```
AIzaSyABTYK3rtzdrmXCxFMVtrjBOVeAYbmDvR8
```

**Comment configurer** :
1. Allez sur https://github.com/TLILIOS/PharmTrackP16/settings/secrets/actions
2. Cliquez sur **"New repository secret"**
3. **Name**: `FIREBASE_API_KEY`
4. **Secret**: Copiez-collez la valeur ci-dessus
5. Cliquez **"Add secret"**

---

### Secret 2: GOOGLE_SERVICE_INFO_PLIST

**Valeur à copier** (encodée en base64) :

Pour obtenir cette valeur, exécutez la commande suivante dans votre terminal :

```bash
cd /Users/macbookair/Desktop/Desk/OC_Projects_24/P16/Rebonnte_P16DAIOS-main
base64 -i MediStock/GoogleService-Info.plist | tr -d '\n' | pbcopy
```

Cette commande va :
- Encoder le fichier GoogleService-Info.plist en base64
- Supprimer les retours à la ligne
- Copier le résultat dans votre presse-papiers

**Comment configurer** :
1. Exécutez la commande ci-dessus dans le Terminal
2. Allez sur https://github.com/TLILIOS/PharmTrackP16/settings/secrets/actions
3. Cliquez sur **"New repository secret"**
4. **Name**: `GOOGLE_SERVICE_INFO_PLIST`
5. **Secret**: Collez (Cmd+V) le contenu copié
6. Cliquez **"Add secret"**

---

## ✅ Validation de la Configuration

### Vérifier les secrets configurés

1. Allez sur https://github.com/TLILIOS/PharmTrackP16/settings/secrets/actions
2. Vous devriez voir :
   - ✅ `FIREBASE_API_KEY` (Updated X seconds ago)
   - ✅ `GOOGLE_SERVICE_INFO_PLIST` (Updated X seconds ago)

### Re-déclencher les workflows

Après avoir configuré les secrets :

**Option 1 - Via l'interface GitHub** :
1. Allez sur https://github.com/TLILIOS/PharmTrackP16/actions
2. Sélectionnez le workflow échoué (par exemple "PR Validation")
3. Cliquez sur **"Re-run all jobs"**

**Option 2 - Nouveau commit** :
Les workflows se redéclencheront automatiquement au prochain push sur la PR.

---

## 🔍 Vérifier que ça fonctionne

Une fois les secrets configurés et les workflows re-déclenchés :

1. **Workflow "ci.yml"** devrait :
   - ✅ Build réussir
   - ✅ Tests passer
   - Durée : ~15 min

2. **Workflow "pr-validation.yml"** devrait :
   - ✅ Fast checks passer
   - ✅ SwiftLint passer
   - ✅ Build & Tests passer
   - Durée : ~20 min

3. **Logs à surveiller** :
   Dans les logs GitHub Actions, vous devriez voir :
   ```
   Setting up Firebase with API key: ***
   ✅ GoogleService-Info.plist decoded successfully
   ```
   (La valeur du secret est masquée avec ***)

---

## 🛠️ Troubleshooting

### Problème : Workflow échoue toujours après configuration

**Vérifiez** :
1. Les noms des secrets sont **EXACTEMENT** :
   - `FIREBASE_API_KEY` (pas `FIREBASE_API_KEYS` ou autre)
   - `GOOGLE_SERVICE_INFO_PLIST` (respecter majuscules/minuscules)

2. La valeur `GOOGLE_SERVICE_INFO_PLIST` :
   - Doit être encodée en base64 (pas le XML brut)
   - Ne doit PAS contenir de retours à la ligne
   - Utilisez bien la commande fournie avec `tr -d '\n'`

### Problème : "Secret masking failed"

**Cause** : Le secret contient des espaces ou retours ligne.

**Solution** :
```bash
# Re-générer GOOGLE_SERVICE_INFO_PLIST proprement
base64 -i MediStock/GoogleService-Info.plist | tr -d '\n\r\t ' | pbcopy
```

### Problème : "GoogleService-Info.plist not found" dans logs

**Cause** : Le workflow ne peut pas décoder le secret.

**Solution** :
1. Vérifiez que le secret est bien configuré
2. Re-décodez et re-configurez `GOOGLE_SERVICE_INFO_PLIST`

---

## 📞 Support

Si les workflows échouent toujours après configuration :

1. **Consultez les logs détaillés** :
   - GitHub Actions → Workflow échoué → Cliquez sur le job → Déroulez les étapes
   - Cherchez les messages d'erreur

2. **Vérifiez la documentation** :
   - `docs/GITHUB_SECRETS_SETUP.md` - Guide complet
   - `docs/CI_CD_PIPELINE.md` - Troubleshooting section

3. **Cas d'erreurs communes** :
   - `Error: API_KEY invalid` → Vérifiez que la clé est correcte dans Firebase Console
   - `Error: Failed to decode plist` → Re-encodez le fichier en base64

---

## 🔒 Sécurité - Rappels

✅ **À FAIRE** :
- Configurer les secrets dans GitHub (interface web sécurisée)
- Supprimer ce fichier après configuration
- Ne jamais partager les secrets par email/Slack

❌ **NE JAMAIS** :
- Commiter ce fichier dans Git
- Copier les secrets dans des fichiers non chiffrés
- Partager les secrets publiquement

---

## 📝 Checklist Finale

Après configuration, vérifiez :

- [ ] Secret `FIREBASE_API_KEY` configuré dans GitHub
- [ ] Secret `GOOGLE_SERVICE_INFO_PLIST` configuré dans GitHub
- [ ] Workflows re-déclenchés (ou nouveau commit poussé)
- [ ] Au moins un workflow passe avec succès
- [ ] Ce fichier `SECRETS_TO_CONFIGURE.md` **SUPPRIMÉ** (important !)

---

**Auteur** : TLILI HAMDI
**Date** : 2025-11-04

⚠️ **SUPPRIMEZ CE FICHIER après configuration des secrets !**

```bash
rm SECRETS_TO_CONFIGURE.md
```
