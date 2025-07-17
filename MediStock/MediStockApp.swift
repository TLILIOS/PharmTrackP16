//
//  MediStockApp.swift
//  MediStock
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import SwiftUI
import UserNotifications

// Service de notifications importé depuis ExpirationNotificationService.swift

// Extension View définie dans EnvironmentKeys.swift

@main
struct MediStockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Configuration simple des notifications d'expiration au démarrage
        Task {
            let notificationService = ExpirationNotificationService(medicineRepository: FirebaseMedicineRepository())
            
            await notificationService.requestNotificationPermission()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withRepositories()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Vérifier les expirations à chaque ouverture de l'app
                    Task {
                        let notificationService = ExpirationNotificationService(medicineRepository: FirebaseMedicineRepository())
                        await notificationService.checkExpirations()
                    }
                }
        }
    }
}
