import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var appCoordinator: AppCoordinator
    
    // Animation properties
    @State private var tabbarOffset: CGFloat = 20
    @State private var tabbarOpacity = 0.0
    @Namespace private var tabAnimation
    
    init(appCoordinator: AppCoordinator) {
        self._appCoordinator = StateObject(wrappedValue: appCoordinator)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Tableau de bord - Stack global
                NavigationStack(path: $appCoordinator.globalNavigationPath) {
                    DashboardView(dashboardViewModel: appCoordinator.dashboardViewModel)
                        .environmentObject(appCoordinator)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            appCoordinator.view(for: destination)
                                .environmentObject(appCoordinator)
                        }
                }
                .tabItem {
                    Label("Accueil", systemImage: "house")
                }
                .tag(0)
                
                // Liste des médicaments - Stack global
                NavigationStack(path: $appCoordinator.globalNavigationPath) {
                    MedicineListView(medicineStockViewModel: appCoordinator.medicineListViewModel)
                        .environmentObject(appCoordinator)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            appCoordinator.view(for: destination)
                                .environmentObject(appCoordinator)
                        }
                }
                .tabItem {
                    Label("Médicaments", systemImage: "pills")
                }
                .tag(1)
                
                // Gestion des rayons - Stack global
                NavigationStack(path: $appCoordinator.globalNavigationPath) {
                    AislesView(aislesViewModel: appCoordinator.aislesViewModel)
                        .environmentObject(appCoordinator)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            appCoordinator.view(for: destination)
                                .environmentObject(appCoordinator)
                        }
                }
                .tabItem {
                    Label("Rayons", systemImage: "tray.2")
                }
                .tag(2)
                
                // Historique - Stack global
                NavigationStack(path: $appCoordinator.globalNavigationPath) {
                    HistoryView(historyViewModel: appCoordinator.historyViewModel)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            appCoordinator.view(for: destination)
                                .environmentObject(appCoordinator)
                        }
                }
                .tabItem {
                    Label("Historique", systemImage: "clock")
                }
                .tag(3)
                
                // Profil - Stack global
                NavigationStack(path: $appCoordinator.globalNavigationPath) {
                    ProfileView(viewModel: appCoordinator.profileViewModel)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            appCoordinator.view(for: destination)
                                .environmentObject(appCoordinator)
                        }
                }
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
                .tag(4)
            }
            .tint(Color.accentApp)
            
            // Message d'erreur global
            if let errorMessage = appCoordinator.globalErrorMessage {
                VStack {
                    Spacer()
                    
                    MessageView(message: errorMessage, type: .error) {
                        appCoordinator.dismissGlobalError()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 70) // Espace pour la tabbar
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .onAppear {
            setupTabBarAppearance()
            configureNavigationHandlers()
            animateTabBar()
        }
    }
    
    private func setupTabBarAppearance() {
        // Configuration de l'apparence de la TabBar
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
        UITabBar.appearance().isTranslucent = true
    }
    
    private func configureNavigationHandlers() {
        // Configuration simplifiée avec stack global - plus besoin de changer d'onglets
        appCoordinator.dashboardViewModel.navigateToMedicineDetailHandler = { medicine in
            appCoordinator.navigateTo(.medicineDetail(medicine.id))
        }
        
        // Note: Avec le stack global, les autres handlers legacy ne sont plus nécessaires
        // La navigation se fait automatiquement via navigateFromDashboard() et navigateTo()
    }
    
    private func animateTabBar() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
            tabbarOffset = 0
            tabbarOpacity = 1.0
        }
    }
}

#Preview {
    MainTabView(appCoordinator: AppCoordinator.preview)
}
