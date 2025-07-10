import UIKit

class RegisterViewController: UIViewController, UITextFieldDelegate {

    private let emailField = UITextField()
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let registerButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .large)

    private var fieldsStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupAnimations()
        setupFieldListeners()
    }

    private func setupUI() {
        emailField.placeholder = "Email"
        emailField.borderStyle = .roundedRect
        emailField.autocapitalizationType = .none

        usernameField.placeholder = "Username"
        usernameField.borderStyle = .roundedRect
        usernameField.autocapitalizationType = .none

        passwordField.placeholder = "Password"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true

        registerButton.setTitle("Crea account", for: .normal)
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.backgroundColor = .systemBlue
        registerButton.layer.cornerRadius = 8
        registerButton.isEnabled = false
        registerButton.alpha = 0.5
        registerButton.addTarget(self, action: #selector(registerUser), for: .touchUpInside)

        fieldsStack = UIStackView(arrangedSubviews: [emailField, usernameField, passwordField, registerButton])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 20
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false
        fieldsStack.alpha = 0
        fieldsStack.transform = CGAffineTransform(translationX: 0, y: 30)

        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(fieldsStack)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            fieldsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fieldsStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            fieldsStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupAnimations() {
        UIView.animate(withDuration: 0.6, delay: 0.2, options: [.curveEaseOut], animations: {
            self.fieldsStack.alpha = 1
            self.fieldsStack.transform = .identity
        })
    }

    private func setupFieldListeners() {
        [emailField, usernameField, passwordField].forEach {
            $0.addTarget(self, action: #selector(validateFields), for: .editingChanged)
        }
    }

    @objc private func validateFields() {
        let isValid = !(emailField.text?.isEmpty ?? true) &&
                      !(usernameField.text?.isEmpty ?? true) &&
                      !(passwordField.text?.isEmpty ?? true)

        registerButton.isEnabled = isValid
        registerButton.alpha = isValid ? 1.0 : 0.5
    }

    @objc private func registerUser() {
        view.endEditing(true)
        spinner.startAnimating()
        registerButton.isEnabled = false

        guard let email = emailField.text,
              let username = usernameField.text,
              let password = passwordField.text else {
            showAlert("Compila tutti i campi")
            return
        }

        let params = [
            "email": email,
            "username": username,
            "password": password
        ]

        guard let url = URL(string: "http://127.0.0.1:8000/api/register/") else {
            showAlert("URL non valido")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            showAlert("Errore nella richiesta")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.registerButton.isEnabled = true

                if let error = error {
                    self.showAlert("Errore: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.showAlert("Nessuna risposta dal server")
                    return
                }

                if httpResponse.statusCode == 201 {
                    AuthAPI.login(username: username, password: password) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let token):
                                UserDefaults.standard.set(token, forKey: "authToken")

                                if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                                    let window = sceneDelegate.window
                                    let welcomeView = UIView(frame: window?.bounds ?? .zero)
                                    welcomeView.backgroundColor = .systemBackground

                                    let label = UILabel()
                                    label.text = "Benvenuto!"
                                    label.font = UIFont.boldSystemFont(ofSize: 28)
                                    label.textColor = .label
                                    label.textAlignment = .center
                                    label.translatesAutoresizingMaskIntoConstraints = false

                                    welcomeView.addSubview(label)
                                    window?.addSubview(welcomeView)

                                    NSLayoutConstraint.activate([
                                        label.centerXAnchor.constraint(equalTo: welcomeView.centerXAnchor),
                                        label.centerYAnchor.constraint(equalTo: welcomeView.centerYAnchor)
                                    ])

                                    UIView.animate(withDuration: 0.8, delay: 0.3, options: [.curveEaseInOut], animations: {
                                        label.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                                        label.alpha = 0.7
                                    }, completion: { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                            let mainTabBar = MainTabBarController()
                                            window?.rootViewController = mainTabBar
                                            window?.makeKeyAndVisible()
                                        }
                                    })
                                }

                            case .failure(let loginError):
                                self.showAlert("Registrato ma login fallito: \(loginError.localizedDescription)")
                            }
                        }
                    }

                } else {
                    self.showAlert("Registrazione fallita. Codice: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }

    private func showAlert(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}
