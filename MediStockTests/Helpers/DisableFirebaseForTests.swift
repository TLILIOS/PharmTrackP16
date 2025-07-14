import Foundation
import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// MARK: - Disable Firebase Completely in Tests

class FirebaseTestDisabler {
    static let shared = FirebaseTestDisabler()
    
    private var isDisabled = false
    
    func disableFirebase() {
        guard !isDisabled else { return }
        
        // Prevent Firebase from initializing
        if FirebaseApp.app() != nil {
            // Firebase is already initialized, we need to work around it
            disableNetworkForAllFirebaseServices()
        }
        
        isDisabled = true
    }
    
    private func disableNetworkForAllFirebaseServices() {
        // Disable Firestore
        let db = Firestore.firestore()
        db.settings.isPersistenceEnabled = false
        db.settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        // Force offline mode immediately
        db.disableNetwork { _ in }
        
        // Clear any pending writes
        db.terminate { _ in }
    }
}

// MARK: - Swizzling to Intercept Firebase Calls

extension FirebaseAuthRepository {
    static func swizzleForTests() {
        let originalSelector = #selector(FirebaseAuthRepository.init)
        let swizzledSelector = #selector(FirebaseAuthRepository.init_test)
        
        guard let originalMethod = class_getInstanceMethod(FirebaseAuthRepository.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(FirebaseAuthRepository.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc dynamic func init_test() {
        // Call original init
        self.init_test()
        
        // Disable Firebase operations
        FirebaseTestDisabler.shared.disableFirebase()
    }
}

// MARK: - Test-Only Firebase Repositories

protocol TestableFirebaseRepository {
    var isTestMode: Bool { get set }
}

extension MediStock.FirebaseAisleRepository {
    private struct AssociatedKeys {
        static var isTestMode = "isTestMode"
    }
    
    var isTestMode: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isTestMode) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isTestMode, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func enableTestMode() {
        isTestMode = true
        FirebaseTestDisabler.shared.disableFirebase()
    }
}

extension MediStock.FirebaseMedicineRepository {
    private struct AssociatedKeys {
        static var isTestMode = "isTestMode"
    }
    
    var isTestMode: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isTestMode) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isTestMode, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func enableTestMode() {
        isTestMode = true
        FirebaseTestDisabler.shared.disableFirebase()
    }
}