import UIKit

final class NewPropertyViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let titleField = NewPropertyViewController.makeTextField(placeholder: "Titolo proprietà")
    private let descriptionField: UITextView = {
        let view = UITextView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.cornerRadius = 8
        view.font = .systemFont(ofSize: 16)
        view.heightAnchor.constraint(equalToConstant: 120).isActive = true
        return view
    }()
    
    private let categoryLabel = NewPropertyViewController.makeLabel("Categoria")
    private let categorySegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["Appartamento", "Casa", "Ufficio"])
        segment.selectedSegmentIndex = 0
        return segment
    }()
    
    private let addressField = NewPropertyViewController.makeTextField(placeholder: "Indirizzo")
    private let priceField: UITextField = {
        let field = NewPropertyViewController.makeTextField(placeholder: "Prezzo")
        field.keyboardType = .decimalPad
        return field
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scatta Foto 360°", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Nuova Proprietà"
        
        setupLayout()
        continueButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
    }
    
    // MARK: - Layout
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        // Titolo
        contentStack.addArrangedSubview(NewPropertyViewController.makeLabel("Titolo"))
        contentStack.addArrangedSubview(titleField)
        
        // Descrizione
        contentStack.addArrangedSubview(NewPropertyViewController.makeLabel("Descrizione"))
        contentStack.addArrangedSubview(descriptionField)
        
        // Categoria
        contentStack.addArrangedSubview(categoryLabel)
        contentStack.addArrangedSubview(categorySegment)
        
        // Indirizzo
        contentStack.addArrangedSubview(NewPropertyViewController.makeLabel("Indirizzo"))
        contentStack.addArrangedSubview(addressField)
        
        // Prezzo
        contentStack.addArrangedSubview(NewPropertyViewController.makeLabel("Prezzo"))
        contentStack.addArrangedSubview(priceField)
        
        // Bottone
        contentStack.addArrangedSubview(continueButton)
    }
    
    // MARK: - Actions
    @objc private func handleSave() {
        guard let title = titleField.text, !title.isEmpty,
              let description = descriptionField.text, !description.isEmpty,
              let address = addressField.text, !address.isEmpty,
              let priceText = priceField.text, let price = Double(priceText) else {
            showAlert(title: "Errore", message: "Completa tutti i campi.")
            return
        }
        
        let category = categorySegment.titleForSegment(at: categorySegment.selectedSegmentIndex) ?? "Altro"
        
        PropertyAPI.createProperty(title: title,
                                   description: description,
                                   category: category,
                                   address: address,
                                   price: price) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let propertyID):
                    print("✅ Proprietà salvata con ID: \(propertyID)")
                    let guidedVC = GuidedCaptureViewController(propertyID: propertyID)
                    self.navigationController?.pushViewController(guidedVC, animated: true)
                    
                case .failure(let error):
                    self.showAlert(title: "Errore", message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Helpers
    private static func makeTextField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return field
    }
    
    private static func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alert, animated: true)
    }
}




