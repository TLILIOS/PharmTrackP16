# Dangerfile - MediStock
# Auteur: TLILI HAMDI
# Documentation: https://danger.systems/ruby/

# ============================================
# Configuration
# ============================================

# Ignore certains fichiers
IGNORED_FILES = [
  "Pods/",
  "Carthage/",
  ".build/",
  "DerivedData/",
  "fastlane/report.xml",
  "fastlane/Preview.html",
  "*.generated.swift"
]

# ============================================
# Helpers
# ============================================

def filter_ignored_files(files)
  files.reject do |file|
    IGNORED_FILES.any? { |pattern| file.include?(pattern) }
  end
end

# ============================================
# PR Metadata Checks
# ============================================

# Vérifier que la PR a une description
if github.pr_body.length < 10
  warn("📝 Please add a meaningful description to your Pull Request.")
end

# Vérifier que la PR n'est pas trop grosse
if git.lines_of_code > 500
  warn("🔍 This PR changes #{git.lines_of_code} lines of code. Consider breaking it into smaller PRs for easier review.")
end

# Vérifier le nombre de commits
if git.commits.count > 10
  warn("📦 This PR contains #{git.commits.count} commits. Consider squashing them before merging.")
end

# ============================================
# Code Changes Analysis
# ============================================

# Fichiers modifiés
modified_files = filter_ignored_files(git.modified_files + git.added_files)
deleted_files = filter_ignored_files(git.deleted_files)

# Analyser les fichiers Swift
swift_files = modified_files.select { |file| file.end_with?(".swift") }

# Afficher le résumé des changements
message("📊 **Changes Summary:**\n- Swift files: #{swift_files.count}\n- Modified: #{git.modified_files.count}\n- Added: #{git.added_files.count}\n- Deleted: #{git.deleted_files.count}")

# ============================================
# SwiftLint Integration
# ============================================

# Run SwiftLint sur les fichiers modifiés
swiftlint.config_file = '.swiftlint.yml'
swiftlint.lint_files inline_mode: true

# Afficher le nombre de violations
if swiftlint.issues.count > 0
  warn("⚠️ SwiftLint found #{swiftlint.issues.count} issues. Please fix them before merging.")
end

# ============================================
# Tests Coverage Check
# ============================================

# Vérifier que des tests ont été ajoutés/modifiés
test_files = modified_files.select { |file| file.include?("Tests/") && file.end_with?(".swift") }

if swift_files.count > 0 && test_files.count == 0
  warn("🧪 No test files were modified. Consider adding tests for your changes.")
end

# Vérifier la présence de mocks pour nouveaux services
new_service_files = git.added_files.select { |file| file.include?("Services/") && file.end_with?(".swift") }
new_mock_files = git.added_files.select { |file| file.include?("Mocks/") && file.include?("Mock") }

if new_service_files.count > 0 && new_mock_files.count == 0
  warn("🎭 New services were added but no corresponding mocks. Consider adding mocks for better testability.")
end

# ============================================
# Architecture Compliance
# ============================================

# Vérifier que les ViewModels utilisent @MainActor
new_viewmodels = git.added_files.select { |file| file.include?("ViewModels/") && file.end_with?("ViewModel.swift") }

new_viewmodels.each do |file|
  content = File.read(file)
  unless content.include?("@MainActor")
    warn("⚡️ ViewModel `#{File.basename(file)}` should be marked with @MainActor", file: file)
  end
end

# Vérifier que les Models sont des structs (pas de classes)
new_models = git.added_files.select { |file| file.include?("Models/") && file.end_with?(".swift") }

new_models.each do |file|
  content = File.read(file)
  if content.match?(/^class\s+\w+/)
    warn("📦 Model `#{File.basename(file)}` should be a struct, not a class", file: file)
  end
end

# ============================================
# Security Checks
# ============================================

# Vérifier qu'aucun fichier sensible n'est ajouté
sensitive_files = [
  "GoogleService-Info.plist",
  "Config.xcconfig",
  "Config-Test.xcconfig",
  ".env"
]

git.added_files.each do |file|
  if sensitive_files.any? { |pattern| file.include?(pattern) }
    fail("🔒 SECURITY: Sensitive file `#{file}` should not be committed! Add it to .gitignore.")
  end
end

# Vérifier les force unwrapping (!)
swift_files.each do |file|
  content = File.read(file)
  force_unwraps = content.scan(/\w+!(?!\=)/).count  # Exclure !=

  if force_unwraps > 5
    warn("⚠️ File `#{file}` contains #{force_unwraps} force unwraps (!). Consider using optional binding.", file: file)
  end
end

# Vérifier les force try
swift_files.each do |file|
  content = File.read(file)
  if content.include?("try!")
    warn("⚠️ File `#{file}` uses force try (try!). Use do-catch instead.", file: file)
  end
end

# Vérifier les print statements (utiliser Logger à la place)
swift_files.each do |file|
  content = File.read(file)
  prints = content.scan(/print\(/).count

  if prints > 0
    warn("🖨️ File `#{file}` contains #{prints} print statements. Use Logger instead.", file: file)
  end
end

# ============================================
# Documentation Checks
# ============================================

# Vérifier que les fonctions publiques ont une documentation
swift_files.each do |file|
  content = File.read(file)

  # Compter les fonctions publiques sans documentation
  public_funcs = content.scan(/public\s+func\s+\w+/).count
  documented_funcs = content.scan(/\/\/\/.*\n.*public\s+func/).count

  if public_funcs > documented_funcs
    warn("📚 File `#{file}` has #{public_funcs - documented_funcs} undocumented public functions.", file: file)
  end
end

# ============================================
# Changelog Check
# ============================================

# Vérifier que CHANGELOG.md a été mis à jour pour les PRs importantes
if modified_files.count > 5 && !git.modified_files.include?("CHANGELOG.md")
  warn("📝 Consider updating CHANGELOG.md for significant changes.")
end

# ============================================
# Accessibility Checks
# ============================================

# Vérifier que les nouvelles vues SwiftUI ont des labels d'accessibilité
new_views = git.added_files.select { |file| file.include?("Views/") && file.end_with?(".swift") }

new_views.each do |file|
  content = File.read(file)

  # Vérifier présence de Button, Image sans .accessibilityLabel
  buttons_without_label = content.scan(/Button\([^)]*\)(?!\s*\.accessibilityLabel)/).count
  images_without_label = content.scan(/Image\([^)]*\)(?!\s*\.accessibilityLabel)/).count

  if buttons_without_label > 0 || images_without_label > 0
    warn("♿️ File `#{file}` may be missing accessibility labels for UI elements.", file: file)
  end
end

# ============================================
# Performance Checks
# ============================================

# Vérifier l'utilisation de @State vs @StateObject vs @ObservedObject
swift_files.each do |file|
  next unless file.include?("Views/")

  content = File.read(file)

  # Détecter mauvais usage de @ObservedObject (devrait être @StateObject pour ownership)
  if content.include?("@ObservedObject") && content.match?(/init\(.*\)/)
    message("⚡️ Consider using @StateObject instead of @ObservedObject in `#{file}` if you're creating the object.", file: file)
  end
end

# ============================================
# Git Best Practices
# ============================================

# Vérifier que les messages de commit suivent Conventional Commits
non_conventional_commits = git.commits.select do |commit|
  !commit.message.match?(/^(feat|fix|docs|style|refactor|perf|test|chore|ci)(\(.+\))?:/)
end

if non_conventional_commits.count > 0
  warn("📋 #{non_conventional_commits.count} commits don't follow Conventional Commits format (feat:, fix:, etc.)")
end

# ============================================
# Reviewers Suggestion
# ============================================

# Suggérer des reviewers basés sur les fichiers modifiés
if modified_files.any? { |f| f.include?("Services/") || f.include?("Repositories/") }
  message("💡 **Suggested reviewers:** Backend/Data layer experts")
end

if modified_files.any? { |f| f.include?("Views/") || f.include?("ViewModels/") }
  message("💡 **Suggested reviewers:** UI/UX experts")
end

if modified_files.any? { |f| f.include?("Tests/") }
  message("💡 **Suggested reviewers:** QA/Testing experts")
end

# ============================================
# Final Summary
# ============================================

if status_report[:errors].count == 0 && status_report[:warnings].count == 0
  message("✅ **Great job!** No issues found. Code looks good to merge!")
elsif status_report[:errors].count > 0
  fail("❌ **Critical issues found!** Please fix all errors before merging.")
else
  message("⚠️ **Some warnings found.** Please review them before merging.")
end

# Afficher un message de remerciement
message("🙏 Thank you for your contribution, @#{github.pr_author}!")

# ============================================
# Custom Rules
# ============================================

# Règle: Vérifier que Info.plist n'est pas modifié manuellement
if git.modified_files.include?("MediStock/Info.plist")
  warn("⚠️ Info.plist was modified. Ensure this is intentional and version numbers are updated correctly.")
end

# Règle: Vérifier la taille des fichiers
large_files = modified_files.select do |file|
  File.exist?(file) && File.size(file) > 500 * 1024  # > 500KB
end

if large_files.count > 0
  warn("📦 Large files detected (>500KB): #{large_files.join(', ')}. Consider optimization.")
end

# Règle: Vérifier présence de TODO/FIXME dans le nouveau code
swift_files.each do |file|
  next unless git.added_files.include?(file)

  content = File.read(file)
  todos = content.scan(/\/\/ TODO(?!.*#\d+)/).count  # TODO sans référence ticket

  if todos > 0
    warn("📌 File `#{file}` contains #{todos} TODO comments without ticket references. Use TODO: #123 format.", file: file)
  end
end

# ============================================
# Documentation
# ============================================

# Installation:
# $ gem install danger
# $ gem install danger-swiftlint

# Configuration GitHub:
# 1. Créer un Personal Access Token avec permissions repo
# 2. Ajouter DANGER_GITHUB_API_TOKEN dans GitHub Secrets
# 3. Ajouter step dans workflow PR:
#    - name: Run Danger
#      run: bundle exec danger
#      env:
#        DANGER_GITHUB_API_TOKEN: ${{ secrets.DANGER_GITHUB_API_TOKEN }}

# Commandes:
# $ danger pr https://github.com/USER/REPO/pull/123  # Test local
# $ danger local                                      # Test sur changements locaux

# Plugins disponibles:
# - danger-swiftlint (lint integration)
# - danger-xcode_summary (test results)
# - danger-prose (markdown/prose checks)
