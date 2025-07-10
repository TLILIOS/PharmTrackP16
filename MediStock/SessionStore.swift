import Foundation
import FirebaseAuth
import Combine

class SessionStore: ObservableObject {
    @Published var session: User?
    private var authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func listen() {
        authRepository.authStateDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.session = user
            }
            .store(in: &cancellables)
    }

    func unbind() {
        cancellables.removeAll()
    }
}

