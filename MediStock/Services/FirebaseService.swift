import Foundation
import Firebase
import FirebaseAnalytics
import FirebaseCrashlytics
import SwiftUI

// MARK: - Firebase Service pour Analytics et Crashlytics

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    private init() {}

    // MARK: - Test Mode Detection

    private var isTestMode: Bool {
        ProcessInfo.processInfo.environment["UNIT_TESTS_ONLY"] == "1"
    }
    
    // MARK: - Configuration

    func configure() {
        // Skip Firebase initialization during unit tests
        if isTestMode {
            print("⚠️ Skipping Firebase initialization (UNIT_TESTS_ONLY mode)")
            return
        }

        // Configuration Firebase sécurisée avec FirebaseConfigLoader
        FirebaseConfigLoader.configure(for: .production)

        // Vérifier que Firebase est bien configuré avant de continuer
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured, skipping Analytics and Firestore setup")
            return
        }

        // Activer Analytics
        Analytics.setAnalyticsCollectionEnabled(true)

        // Activer Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

        // Configuration cache Firestore optimisée pour offline-first
        // IMPORTANT: Cette configuration DOIT être appliquée AVANT toute utilisation de Firestore
        let settings = FirestoreSettings()

        // Cache persistant de 100MB pour supporter toutes les données offline
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber)

        // Désactiver la vérification SSL en cas de problèmes réseau (développement uniquement)
        #if DEBUG
        settings.isSSLEnabled = true // Toujours activer SSL, même en debug
        #endif

        // Appliquer les settings AVANT toute utilisation de Firestore
        Firestore.firestore().settings = settings
    }
    
    // MARK: - Analytics Events

    func logEvent(_ event: AnalyticsEvent) {
        guard !isTestMode else { return }
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
    
    func setUserProperty(_ property: UserProperty) {
        guard !isTestMode else { return }
        Analytics.setUserProperty(property.value, forName: property.name)
    }

    func setUserID(_ userID: String?) {
        guard !isTestMode else { return }
        Analytics.setUserID(userID)
    }
    
    // MARK: - Crashlytics

    func logError(_ error: Error, userInfo: [String: Any]? = nil) {
        guard !isTestMode else { return }
        Crashlytics.crashlytics().record(error: error, userInfo: userInfo)
    }

    func log(_ message: String) {
        guard !isTestMode else { return }
        Crashlytics.crashlytics().log(message)
    }

    func setCustomValue(_ value: Any?, forKey key: String) {
        guard !isTestMode else { return }
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    // MARK: - Medicine Events
    
    func logMedicineAdded(medicine: Medicine) {
        logEvent(AnalyticsEvent(
            name: "medicine_added",
            parameters: [
                "medicine_id": medicine.id as Any,
                "medicine_name": medicine.name,
                "aisle_id": medicine.aisleId as Any,
                "initial_quantity": medicine.currentQuantity
            ]
        ))
    }
    
    func logMedicineUpdated(medicine: Medicine) {
        logEvent(AnalyticsEvent(
            name: "medicine_updated",
            parameters: [
                "medicine_id": medicine.id as Any,
                "medicine_name": medicine.name,
                "current_quantity": medicine.currentQuantity
            ]
        ))
    }
    
    func logMedicineDeleted(medicineId: String) {
        logEvent(AnalyticsEvent(
            name: "medicine_deleted",
            parameters: [
                "medicine_id": medicineId
            ]
        ))
    }
    
    func logStockAdjusted(medicine: Medicine, adjustment: Int, reason: String) {
        logEvent(AnalyticsEvent(
            name: "stock_adjusted",
            parameters: [
                "medicine_id": medicine.id ?? "unknown",
                "medicine_name": medicine.name,
                "adjustment": adjustment,
                "new_quantity": medicine.currentQuantity + adjustment,
                "reason": reason,
                "stock_status": medicine.stockStatus == .critical ? "critical" :
                              medicine.stockStatus == .warning ? "warning" : "normal"
            ]
        ))
    }
    
    // MARK: - User Events
    
    func logSignIn(method: String) {
        logEvent(AnalyticsEvent(
            name: AnalyticsEventLogin,
            parameters: [
                AnalyticsParameterMethod: method
            ]
        ))
    }
    
    func logSignUp(method: String) {
        logEvent(AnalyticsEvent(
            name: AnalyticsEventSignUp,
            parameters: [
                AnalyticsParameterMethod: method
            ]
        ))
    }
    
    func logSignOut() {
        logEvent(AnalyticsEvent(name: "sign_out", parameters: nil))
    }
    
    // MARK: - Search Events
    
    func logSearch(searchTerm: String, resultCount: Int) {
        logEvent(AnalyticsEvent(
            name: AnalyticsEventSearch,
            parameters: [
                AnalyticsParameterSearchTerm: searchTerm,
                "result_count": resultCount
            ]
        ))
    }
    
    // MARK: - Screen Views
    
    func logScreenView(screenName: String, screenClass: String? = nil) {
        logEvent(AnalyticsEvent(
            name: AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: screenName,
                AnalyticsParameterScreenClass: screenClass ?? screenName
            ]
        ))
    }
    
    // MARK: - Performance Monitoring

    func logPerformanceEvent(name: String, duration: TimeInterval, metadata: [String: Any]? = nil) {
        var parameters: [String: Any] = [
            "duration_ms": Int(duration * 1000)
        ]

        if let metadata = metadata {
            parameters.merge(metadata) { _, new in new }
        }

        logEvent(AnalyticsEvent(
            name: "performance_\(name)",
            parameters: parameters
        ))
    }

    // MARK: - Network Events

    func logEvent(name: String, parameters: [String: Any]?) {
        guard !isTestMode else { return }
        Analytics.logEvent(name, parameters: parameters)
    }
}

// MARK: - Analytics Event Model

struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]?
}

// MARK: - User Property Model

struct UserProperty {
    let name: String
    let value: String?
}

// MARK: - Common User Properties

extension UserProperty {
    static func userRole(_ role: String) -> UserProperty {
        UserProperty(name: "user_role", value: role)
    }
    
    static func appVersion(_ version: String) -> UserProperty {
        UserProperty(name: "app_version", value: version)
    }
    
    static func preferredTheme(_ theme: String) -> UserProperty {
        UserProperty(name: "preferred_theme", value: theme)
    }
}

// MARK: - Analytics Helper

extension View {
    func trackScreen(_ name: String) -> some View {
        self.onAppear {
            FirebaseService.shared.logScreenView(screenName: name)
        }
    }
}
