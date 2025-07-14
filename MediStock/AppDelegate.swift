//
//  AppDelegate.swift
//  MediStock
//
//  Created by Tlili Hamdi on 28/05/2024.
//

import Foundation
import UIKit
import Firebase
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 🔥 SOLUTION RADICALE: Désactiver Firebase pendant les tests
        #if DEBUG
        // Vérifier si nous sommes en mode test
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
           ProcessInfo.processInfo.arguments.contains("--testing") ||
           NSClassFromString("XCTest") != nil {
            print("🧪 MODE TEST DÉTECTÉ - Firebase désactivé pour éviter les blocages")
            return true
        }
        #endif
        
        // Configuration Firebase normale pour l'app
        FirebaseApp.configure()
        
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
        db.settings = settings
        
        return true
    }
}

