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
                // Tableau de bord
                NavigationStack(path: $appCoordinator.dashboardNavigationPath) {
                    DashboardView(dashboardViewModel: appCoordinator.dashboardViewModel)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            appCoordinator.view(for: destination)
                        }
                }
                .tabItem {
                    Label("Accueil", systemImage: "house")
                }
                .tag(0)
                
                // Liste des médicaments
                NavigationStack(path: $appCoordinator.medicineNavigationPath) {
                    MedicineListView(medicineStockViewModel: appCoordinator.medicineListViewModel)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            appCoordinator.view(for: destination)
                        }
                }
                .tabItem {
                    Label("Médicaments", systemImage: "pills")
                }
                .tag(1)
                
                // Gestion des rayons
                NavigationStack(path: $appCoordinator.aislesNavigationPath) {
                    AislesView(aislesViewModel: appCoordinator.aislesViewModel)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            appCoordinator.view(for: destination)
                        }
                }
                .tabItem {
                    Label("Rayons", systemImage: "tray.2")
                }
                .tag(2)
                
                // Historique
                NavigationStack(path: $appCoordinator.historyNavigationPath) {
                    HistoryView(historyViewModel: appCoordinator.historyViewModel)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            appCoordinator.view(for: destination)
                        }
                }
                .tabItem {
                    Label("Historique", systemImage: "clock")
                }
                .tag(3)
                
                // Profil
                NavigationStack(path: $appCoordinator.profileNavigationPath) {
                    ProfileView(viewModel: appCoordinator.profileViewModel)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            appCoordinator.view(for: destination)
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
        // Configuration des handlers de navigation pour le ViewModel du tableau de bord
        appCoordinator.dashboardViewModel.navigateToMedicineDetailHandler = { medicine in
            appCoordinator.navigateTo(.medicineDetail(medicine))
        }
        
        appCoordinator.dashboardViewModel.navigateToMedicineListHandler = {
            selectedTab = 1 // Switch to Medicines tab
        }
        
        appCoordinator.dashboardViewModel.navigateToAislesHandler = {
            selectedTab = 2 // Switch to Aisles tab
        }
        
        appCoordinator.dashboardViewModel.navigateToHistoryHandler = {
            selectedTab = 3 // Switch to History tab
        }
        
        appCoordinator.dashboardViewModel.navigateToCriticalStockHandler = {
            selectedTab = 1 // Switch to Medicines tab
            // appCoordinator.medicineListViewModel.filterByStockStatus(.critical)
        }
        
        appCoordinator.dashboardViewModel.navigateToExpiringMedicinesHandler = {
            selectedTab = 1 // Switch to Medicines tab
            // appCoordinator.medicineListViewModel.filterByExpiryStatus(.soon)
        }
        
        appCoordinator.dashboardViewModel.navigateToAdjustStockHandler = {
            if let firstMedicine = appCoordinator.medicineListViewModel.medicines.first {
                appCoordinator.navigateTo(.adjustStock(firstMedicine))
            }
        }
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
