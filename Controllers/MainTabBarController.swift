import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let homeVC = UINavigationController(rootViewController: HomeViewController())
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)

        let profileVC = UIViewController()
        profileVC.view.backgroundColor = .systemGroupedBackground
        profileVC.tabBarItem = UITabBarItem(title: "Profilo", image: UIImage(systemName: "person.circle"), tag: 1)

        let settingsVC = UIViewController()
        settingsVC.view.backgroundColor = .systemGroupedBackground
        settingsVC.tabBarItem = UITabBarItem(title: "Impostazioni", image: UIImage(systemName: "gearshape"), tag: 2)

        viewControllers = [homeVC, profileVC, settingsVC]
    }
}
