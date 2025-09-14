import UIKit

final class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .systemBackground
    }
    
    private func setupTabs() {
        // 🏠 Home
        let homeVC = UINavigationController(rootViewController: HomeViewController())
        homeVC.tabBarItem = UITabBarItem(title: "Home",
                                         image: UIImage(systemName: "house"),
                                         tag: 0)
        
        // 📊 Dashboard (venditore)
        let dashboardVC = UINavigationController(rootViewController: DashboardViewController())
        dashboardVC.tabBarItem = UITabBarItem(title: "Dashboard",
                                              image: UIImage(systemName: "plus.circle"),
                                              tag: 1)
        
        // 👤 Profilo (placeholder per ora)
        let profileVC = UIViewController()
        profileVC.view.backgroundColor = .systemGroupedBackground
        profileVC.title = "Profilo"
        profileVC.tabBarItem = UITabBarItem(title: "Profilo",
                                            image: UIImage(systemName: "person.circle"),
                                            tag: 2)
        
        // ⚙️ Impostazioni (placeholder per ora)
        let settingsVC = UIViewController()
        settingsVC.view.backgroundColor = .systemGroupedBackground
        settingsVC.title = "Impostazioni"
        settingsVC.tabBarItem = UITabBarItem(title: "Impostazioni",
                                             image: UIImage(systemName: "gearshape"),
                                             tag: 3)
        
        // Assegnazione tab
        viewControllers = [homeVC, dashboardVC, profileVC, settingsVC]
    }
}

