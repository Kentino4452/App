import UIKit

final class PanoramaReviewViewController: UIViewController {
    
    private let propertyID: Int
    private let panorama: UIImage
    
    // Viewer 360° (ricicliamo PanoramaViewerViewController internamente)
    private var viewerVC: PanoramaViewerViewController?
    
    private let publishButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("✅ Pubblica", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemGreen
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return btn
    }()
    
    private let retryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("🔄 Rifai", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemRed
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return btn
    }()
    
    // MARK: - Init
    init(propertyID: Int, panorama: UIImage) {
        self.propertyID = propertyID
        self.panorama = panorama
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) non implementato") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupViewer()
        setupButtons()
    }
    
    // MARK: - Setup Viewer
    private func setupViewer() {
        let viewer = PanoramaViewerViewController()
        viewer.modalPresentationStyle = .overFullScreen
        
        // 👉 passiamo l’immagine locale
        if let data = panorama.jpegData(compressionQuality: 0.9) {
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_panorama.jpg")
            try? data.write(to: tmpURL)
            viewer.panoramaImageURL = tmpURL
        }
        
        addChild(viewer)
        view.addSubview(viewer.view)
        viewer.view.frame = view.bounds
        viewer.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewer.didMove(toParent: self)
        
        self.viewerVC = viewer
    }
    
    // MARK: - Setup Buttons
    private func setupButtons() {
        let stack = UIStackView(arrangedSubviews: [publishButton, retryButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        publishButton.addTarget(self, action: #selector(handlePublish), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handlePublish() {
        // 🔄 Spinner + messaggio "Pubblicazione in corso"
        let alert = UIAlertController(title: nil, message: "Pubblicazione in corso…", preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        alert.view.addSubview(spinner)
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            spinner.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -20)
        ])
        
        present(alert, animated: true)
        
        ImageUploader.upload(image: panorama, to: propertyID) { result in
            DispatchQueue.main.async {
                alert.dismiss(animated: true) {
                    switch result {
                    case .success(_):
                        let done = UIAlertController(title: "Pubblicato ✅",
                                                     message: "Il tour è stato caricato correttamente.",
                                                     preferredStyle: .alert)
                        done.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.dismiss(animated: true)
                        })
                        self.present(done, animated: true)
                        
                    case .failure(let error):
                        let fail = UIAlertController(title: "Errore",
                                                     message: error.localizedDescription,
                                                     preferredStyle: .alert)
                        fail.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(fail, animated: true)
                    }
                }
            }
        }
    }
    
    @objc private func handleRetry() {
        // 👉 Torna indietro al GuidedCapture per rifare gli scatti
        navigationController?.popViewController(animated: true)
    }
}


