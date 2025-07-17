# Bonnes Pratiques SwiftUI - MediStock

## 1. Décomposition des Vues Complexes

### ❌ À éviter
```swift
var body: some View {
    ZStack {
        Color.background
        VStack {
            // 50+ lignes de code imbriqué
            // Multiples niveaux de HStack/VStack
            // Logique complexe inline
        }
    }
}
```

### ✅ Bonne pratique
```swift
var body: some View {
    contentView
        .background(backgroundView)
        .navigationTitle("Titre")
        .toolbar { toolbarContent }
}

// Utiliser des extensions pour organiser
extension MyView {
    private var contentView: some View { ... }
    private var backgroundView: some View { ... }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent { ... }
}
```

## 2. Gestion des Méthodes Asynchrones

### ❌ À éviter
```swift
.onReceive(notification) { _ in
    Task {
        await viewModel?.loadMedicine() // Oubli du paramètre id
    }
}
```

### ✅ Bonne pratique
```swift
// Stocker les paramètres nécessaires
let medicineId: String

.onReceive(notification) { _ in
    Task {
        await viewModel?.loadMedicine(id: medicineId)
    }
}
```

## 3. Gestion des Notifications

### ❌ À éviter
```swift
// Répétition pour chaque notification
.onReceive(NotificationCenter.default.publisher(for: .medicineUpdated)) { _ in
    Task { await refresh() }
}
.onReceive(NotificationCenter.default.publisher(for: .stockAdjusted)) { _ in
    Task { await refresh() }
}
```

### ✅ Bonne pratique
```swift
// Combiner les notifications
private var refreshPublisher: AnyPublisher<Notification, Never> {
    Publishers.MergeMany(
        NotificationCenter.default.publisher(for: .medicineUpdated),
        NotificationCenter.default.publisher(for: .stockAdjusted),
        NotificationCenter.default.publisher(for: .medicineAdded),
        NotificationCenter.default.publisher(for: .medicineDeleted)
    )
    .eraseToAnyPublisher()
}

// Utilisation
.onReceive(refreshPublisher) { _ in
    Task { await refresh() }
}
```

## 4. Architecture MVVM

### ❌ À éviter
```swift
struct MyView: View {
    @State private var data: [Item] = []
    
    var body: some View {
        // Logique métier dans la vue
        Button("Load") {
            // Code de chargement direct
        }
    }
}
```

### ✅ Bonne pratique
```swift
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    var body: some View {
        // Vue pure, pas de logique métier
        Button("Load") {
            Task { await viewModel.loadData() }
        }
    }
}

@MainActor
class MyViewModel: ObservableObject {
    // Toute la logique métier ici
}
```

## 5. Computed Properties pour la Lisibilité

### ✅ Utiliser des computed properties pour :
- Filtrage de données
- Conditions complexes
- Calculs dérivés

```swift
private var filteredMedicines: [Medicine] {
    viewModel.medicines
        .filter { searchText.isEmpty || $0.name.contains(searchText) }
        .sorted(by: sortCriteria)
}

private var isDataAvailable: Bool {
    !viewModel.medicines.isEmpty && !viewModel.isLoading
}
```

## 6. Gestion des États de Chargement

### ✅ Pattern recommandé
```swift
enum LoadingState {
    case idle
    case loading
    case loaded(data: [Item])
    case error(Error)
}

// Dans la vue
switch viewModel.state {
case .idle:
    EmptyView()
case .loading:
    ProgressView()
case .loaded(let items):
    ContentView(items: items)
case .error(let error):
    ErrorView(error: error)
}
```

## 7. Éviter les Force Unwrap

### ❌ À éviter
```swift
viewModel!.loadData()
medicine.id!
```

### ✅ Bonne pratique
```swift
viewModel?.loadData()
guard let id = medicine.id else { return }
```

## 8. Naming Conventions

- **Views**: `MedicineListView`, `AdjustStockView`
- **ViewModels**: `MedicineListViewModel`, `AdjustStockViewModel`
- **Observable ViewModels**: `ObservableMedicineListViewModel`
- **Computed properties**: `isLoading`, `hasData`, `filteredItems`
- **Actions**: `loadData()`, `refresh()`, `deleteItem()`

## 9. Limite de Complexité SwiftUI

Si vous obtenez l'erreur "The compiler is unable to type-check this expression":
1. Décomposer le body en plusieurs computed properties
2. Extraire les sous-vues dans des structs séparées
3. Limiter les niveaux d'imbrication (max 3-4 niveaux)
4. Éviter les expressions complexes inline

## 10. Tests et Préviews

### ✅ Toujours fournir des previews
```swift
#Preview {
    NavigationStack {
        MyView(viewModel: MyViewModel.preview)
    }
}

extension MyViewModel {
    static var preview: MyViewModel {
        // Version mock pour les previews
    }
}
```