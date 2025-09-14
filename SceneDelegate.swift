import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        // ✅ Token statico salvato per test
        let testToken = "c317d24ca043bf52e826c62c00213691a7676618"
        UserDefaults.standard.set(testToken, forKey: "authToken")
        print("🔑 Token di test salvato in UserDefaults")

        // 🔴 Saltiamo login/registrazione → entriamo direttamente nell'app
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()
    }
}








