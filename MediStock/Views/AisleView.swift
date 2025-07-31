import SwiftUI

// MARK: - Vue Rayons corrigée utilisant uniquement les ViewModels

struct AisleListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddForm = false
    @State private var addButtonScale: CGFloat = 1.0
    @State private var cardAppearAnimation = false
    
    var body: some View {
        Group {
            if appState.isLoading && appState.aisles.isEmpty {
                // Chargement initial
                ProgressView("Chargement des rayons...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.aisles.isEmpty {
                // État vide modernisé
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Illustration moderne
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 140, height: 140)
                        
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 70, weight: .light))
                            .foregroundColor(.accentColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .scaleEffect(cardAppearAnimation ? 1 : 0.5)
                    .opacity(cardAppearAnimation ? 1 : 0)
                    
                    VStack(spacing: 12) {
                        Text("Aucun rayon")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                        
                        Text("Organisez vos médicaments\nen créant votre premier rayon")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            addButtonScale = 0.9
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                addButtonScale = 1.0
                            }
                        }
                        showingAddForm = true
                    }) {
                        Label("Créer un rayon", systemImage: "plus.circle.fill")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                        cardAppearAnimation = true
                    }
                }
            } else {
                // Liste des rayons avec cards modernes
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(appState.aisles.enumerated()), id: \.element.id) { index, aisle in
                            NavigationLink(destination: AisleDetailView(aisle: aisle).environmentObject(appState)) {
                                ModernAisleCard(aisle: aisle)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: cardAppearAnimation)
                            }
                            .onAppear {
                                // Pagination
                                if aisle.id == appState.aisles.last?.id {
                                    Task {
                                        await appState.loadMoreAisles()
                                    }
                                }
                            }
                        }
                        
                        // Indicateur de chargement pour pagination
                        if appState.isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    await appState.loadData()
                }
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        cardAppearAnimation = true
                    }
                }
            }
        }
        .navigationTitle("Rayons")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        addButtonScale = 0.9
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            addButtonScale = 1.0
                        }
                    }
                    showingAddForm = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(addButtonScale)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground).opacity(0.9),
                        Color(UIColor.systemBackground).opacity(0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 10)
                .blur(radius: 2)
                .offset(y: 100)
                
                Spacer()
            }
            .allowsHitTesting(false)
        )
        .sheet(isPresented: $showingAddForm) {
            NavigationStack {
                AisleFormView(aisle: nil)
                    .environmentObject(appState)
            }
        }
        .onAppear {
            // S'assurer que les données sont chargées
            if appState.aisles.isEmpty && !appState.isLoading {
                Task {
                    await appState.loadData()
                }
            }
        }
    }
}

// MARK: - Carte de rayon moderne

struct ModernAisleCard: View {
    let aisle: Aisle
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    private var medicineCount: Int {
        appState.medicines.filter { $0.aisleId == aisle.id }.count
    }
    
    private var criticalCount: Int {
        appState.medicines
            .filter { $0.aisleId == aisle.id && $0.stockStatus == .critical }
            .count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône avec fond coloré
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(aisle.color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: aisle.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(aisle.color)
                    .symbolRenderingMode(.hierarchical)
            }
            
            // Contenu principal
            VStack(alignment: .leading, spacing: 6) {
                Text(aisle.name)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                
                // Nombre de médicaments
                Text("\(medicineCount) médicament\(medicineCount > 1 ? "s" : "")")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                
                // Description si disponible
                if let description = aisle.description {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                // Badge critique si nécessaire
                if criticalCount > 0 {
                    CriticalBadge(count: criticalCount)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(aisle.name), \(medicineCount) médicaments\(criticalCount > 0 ? ", \(criticalCount) en stock critique" : "")")
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08)
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5)
    }
}

// MARK: - Badge critique moderne

struct CriticalBadge: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
            
            Text("\(count) critique\(count > 1 ? "s" : "")")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.red)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.red.opacity(0.15))
        )
    }
}

// MARK: - Ligne de rayon (ancienne version conservée pour compatibilité)

struct AisleRow: View {
    let aisle: Aisle
    @EnvironmentObject var appState: AppState
    
    private var medicineCount: Int {
        appState.medicines.filter { $0.aisleId == aisle.id }.count
    }
    
    private var criticalCount: Int {
        appState.medicines
            .filter { $0.aisleId == aisle.id && $0.stockStatus == .critical }
            .count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône du rayon
            Image(systemName: aisle.icon)
                .font(.title2)
                .foregroundColor(aisle.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(aisle.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text("\(medicineCount) médicament\(medicineCount > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if criticalCount > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Label("\(criticalCount) critique\(criticalCount > 1 ? "s" : "")", 
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .labelStyle(.titleOnly)
                    }
                }
                
                if let description = aisle.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .contentShape(Rectangle())
    }
}

// MARK: - Détail d'un rayon

struct AisleDetailView: View {
    let aisle: Aisle
    @EnvironmentObject var appState: AppState
    @State private var showingEditForm = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    
    private var medicines: [Medicine] {
        appState.medicines.filter { $0.aisleId == aisle.id }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // En-tête
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: aisle.icon)
                            .font(.largeTitle)
                            .foregroundColor(aisle.color)
                        
                        VStack(alignment: .leading) {
                            Text(aisle.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("\(medicines.count) médicament\(medicines.count > 1 ? "s" : "")")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    if let description = aisle.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(aisle.color.opacity(0.1))
                .cornerRadius(15)
                
                // Statistiques
                HStack(spacing: 15) {
                    AisleStatCard(
                        title: "Total",
                        value: "\(medicines.count)",
                        icon: "pills",
                        color: aisle.color
                    )
                    
                    AisleStatCard(
                        title: "Critique",
                        value: "\(medicines.filter { $0.stockStatus == .critical }.count)",
                        icon: "exclamationmark.triangle",
                        color: .red
                    )
                    
                    AisleStatCard(
                        title: "Expirant",
                        value: "\(medicines.filter { $0.isExpiringSoon }.count)",
                        icon: "clock",
                        color: .orange
                    )
                }
                
                // Liste des médicaments
                if !medicines.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Médicaments")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(medicines) { medicine in
                                NavigationLink(value: MedicineDestination.detail(medicine)) {
                                    MedicineRow(medicine: medicine)
                                }
                                .buttonStyle(.plain)
                                
                                if medicine.id != medicines.last?.id {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditForm = true }) {
                        Label("Modifier", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Supprimer", systemImage: "trash")
                    }
                    .disabled(!medicines.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            NavigationStack {
                AisleFormView(aisle: aisle)
                    .environmentObject(appState)
            }
        }
        .alert("Supprimer ce rayon ?", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                Task {
                    await appState.deleteAisle(aisle)
                    dismiss()
                }
            }
        } message: {
            Text("Cette action est irréversible. Assurez-vous qu'aucun médicament n'est associé à ce rayon.")
        }
        .navigationDestination(for: MedicineDestination.self) { destination in
            switch destination {
            case .detail(let medicine):
                MedicineDetailView(medicine: medicine)
                    .environmentObject(appState)
            case .edit(let medicine):
                MedicineFormView(medicine: medicine)
                    .environmentObject(appState)
            case .adjustStock(let medicine):
                StockAdjustmentView(medicine: medicine)
                    .environmentObject(appState)
            case .add:
                MedicineFormView(medicine: nil)
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Carte de statistique

struct AisleStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
