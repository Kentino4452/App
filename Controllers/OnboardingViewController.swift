import UIKit

class OnboardingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBlue
        setupUI()
    }

    private func setupUI() {
        let welcomeLabel = UILabel()
        welcomeLabel.text = "Benvenuto su RealEstate360"
        welcomeLabel.textAlignment = .center
        welcomeLabel.font = UIFont.boldSystemFont(ofSize: 24)
        welcomeLabel.textColor = .white

        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomeLabel)

        NSLayoutConstraint.activate([
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        let continueButton = UIButton(type: .system)
        continueButton.setTitle("Inizia", for: .normal)
        continueButton.tintColor = .white
        continueButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        continueButton.addTarget(self, action: #selector(continueToApp), for: .touchUpInside)

        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 30)
        ])
    }

    @objc private func continueToApp() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        let mainTab = MainTabBarController()
        UIApplication.shared.windows.first?.rootViewController = mainTab
    }
}
