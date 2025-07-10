import UIKit

class NewPropertyViewController: UIViewController {

    private let titleField: UITextField = {
        let field = UITextField()
        field.placeholder = "Titolo proprietà"
        field.borderStyle = .roundedRect
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let descriptionField: UITextView = {
        let view = UITextView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.cornerRadius = 8
        view.font = UIFont.systemFont(ofSize: 16)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let categorySegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["Appartamento", "Casa", "Ufficio"])
        segment.selectedSegmentIndex = 0
        segment.translatesAutoresizingMaskIntoConstraints = false
        return segment
    }()

    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scatta Foto 360°", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Nuova Proprietà"
        setupLayout()
        continueButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
    }

    private func setupLayout() {
        view.addSubview(titleField)
        view.addSubview(descriptionField)
        view.addSubview(categorySegment)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleField.heightAnchor.constraint(equalToConstant: 44),

            descriptionField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 20),
            descriptionField.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
            descriptionField.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
            descriptionField.heightAnchor.constraint(equalToConstant: 120),

            categorySegment.topAnchor.constraint(equalTo: descriptionField.bottomAnchor, constant: 20),
            categorySegment.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            continueButton.topAnchor.constraint(equalTo: categorySegment.bottomAnchor, constant: 30),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func handleSave() {
        guard let title = titleField.text, !title.isEmpty,
              let description = descriptionField.text, !description.isEmpty else {
            showAlert(title: "Errore", message: "Completa tutti i campi.")
            return
        }

        let token = UserDefaults.standard.string(forKey: "authToken") ?? ""
        let category = categorySegment.titleForSegment(at: categorySegment.selectedSegmentIndex) ?? "Altro"
        
        PropertyAPI.createProperty(title: title, description: description, category: category, token: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let propertyID):
                    print("✅ Proprietà salvata con ID: \(propertyID)")
                    let guidedVC = GuidedCaptureViewController()
                    guidedVC.propertyID = propertyID
                    self.navigationController?.pushViewController(guidedVC, animated: true)
                    
                case .failure(let error):
                    self.showAlert(title: "Errore", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alert, animated: true)
    }
}
