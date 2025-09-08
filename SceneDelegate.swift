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

        // 🔴 Saltiamo login/registrazione → entriamo direttamente nell'app
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()
    }
}





