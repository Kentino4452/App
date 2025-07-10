import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

        if !hasSeenOnboarding {
            window?.rootViewController = OnboardingViewController()
            window?.makeKeyAndVisible()
            return
        }

        // ✅ Se c'è un token, validalo con API /api/me/
        if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
            validateTokenAndLaunchUI()
        } else {
            // Nessun token → vai al login
            window?.rootViewController = LoginViewController()
            window?.makeKeyAndVisible()
        }
    }

    private func validateTokenAndLaunchUI() {
        guard let url = URL(string: "http://127.0.0.1:8000/api/me/") else {
            setRoot(LoginViewController())
            return
        }

        APIClient.authorizedRequest(url: url) { result in
            switch result {
            case .success(_):
                self.setRoot(MainTabBarController())
            case .failure(_):
                logoutAndReturnToLogin()
            }
        }
    }

    private func setRoot(_ viewController: UIViewController) {
        DispatchQueue.main.async {
            self.window?.rootViewController = viewController
            self.window?.makeKeyAndVisible()
        }
    }
}



