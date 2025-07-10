import UIKit

class PropertyDetailViewController: UIViewController {

    private let nameField = UITextField()
    private let startButton = UIButton(type: .system)
    private let viewPanoramaButton = UIButton(type: .system)

    // ⚠️ Imposta l'ID reale della proprietà quando disponibile
    var propertyID: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupForm()
    }

    private func setupForm() {
        nameField.placeholder = "Nome proprietà"
        nameField.borderStyle = .roundedRect
        nameField.frame = CGRect(x: 30, y: 150, width: view.bounds.width - 60, height: 44)
        view.addSubview(nameField)

        startButton.setTitle("📸 Scatta Foto 360°", for: .normal)
        startButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        startButton.frame = CGRect(x: 30, y: 220, width: view.bounds.width - 60, height: 50)
        startButton.addTarget(self, action: #selector(startCapture), for: .touchUpInside)
        view.addSubview(startButton)

        viewPanoramaButton.setTitle("🌐 Visualizza Panorama", for: .normal)
        viewPanoramaButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        viewPanoramaButton.frame = CGRect(x: 30, y: 290, width: view.bounds.width - 60, height: 50)
        viewPanoramaButton.addTarget(self, action: #selector(showPanorama), for: .touchUpInside)
        view.addSubview(viewPanoramaButton)
    }

    @objc private func startCapture() {
        guard let name = nameField.text, !name.isEmpty else {
            let alert = UIAlertController(title: "Attenzione", message: "Inserisci un nome per la proprietà", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let captureVC = GuidedCaptureViewController()
        captureVC.propertyID = propertyID
        captureVC.modalPresentationStyle = .fullScreen
        present(captureVC, animated: true)
    }

    @objc private func showPanorama() {
        PropertyAPI.getImages(for: propertyID) { result in
            switch result {
            case .success(let urls):
                guard let firstURL = urls.first else {
                    self.showAlert("Nessuna immagine trovata.")
                    return
                }

                DispatchQueue.main.async {
                    let viewer = PanoramaViewerViewController()
                    viewer.panoramaImageURL = firstURL
                    viewer.modalPresentationStyle = .fullScreen
                    self.present(viewer, animated: true)
                }

            case .failure(let error):
                self.showAlert("Errore nel caricamento immagini: \(error.localizedDescription)")
            }
        }
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

