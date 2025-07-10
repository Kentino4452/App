import UIKit

class HomeViewController: UIViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "RealEstate360"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor.label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let addPropertyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("➕ Aggiungi Proprietà", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dashboard"
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        setupToolbar()
        setupActions()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(addPropertyButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            addPropertyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addPropertyButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60),
            addPropertyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            addPropertyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func setupToolbar() {
        let photoIcon = UIBarButtonItem(image: UIImage(systemName: "camera"), style: .plain, target: self, action: #selector(openCamera))
        let listIcon = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: self, action: #selector(openProperties))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        self.toolbarItems = [photoIcon, flexible, listIcon]
        self.navigationController?.isToolbarHidden = false
    }

    private func setupActions() {
        addPropertyButton.addTarget(self, action: #selector(openAddProperty), for: .touchUpInside)
    }

    @objc private func openAddProperty() {
        let guidedVC = GuidedCaptureViewController()
        guidedVC.modalPresentationStyle = .fullScreen
        guidedVC.propertyID = 1 // 👈 imposta ID reale dinamicamente
        navigationController?.pushViewController(guidedVC, animated: true)
    }

    @objc private func openCamera() {
        let captureVC = GuidedCaptureViewController()
        navigationController?.pushViewController(captureVC, animated: true)
    }

    @objc private func openProperties() {
        print("Vai alla lista proprietà")
    }
}

