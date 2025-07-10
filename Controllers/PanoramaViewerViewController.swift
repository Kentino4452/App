import UIKit
import SceneKit

class PanoramaViewerViewController: UIViewController {
    
    private var sceneView: SCNView!
    private var cameraNode = SCNNode()

    var panoramaImageURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupScene()
        setupCamera()
        addCloseButton()
        loadPanoramaFromURL()
    }

    private func setupScene() {
        sceneView = SCNView(frame: view.bounds)
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = true  // touch-based rotazione
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .black
        view.addSubview(sceneView)
    }

    private func setupCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 80
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
    }

    private func loadPanoramaFromURL() {
        guard let url = panoramaImageURL else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.applyPanoramaTexture(image: image)
                }
            } else {
                print("❌ Errore nel caricamento immagine:", error?.localizedDescription ?? "Nessun dato")
            }
        }
        task.resume()
    }

    private func applyPanoramaTexture(image: UIImage) {
        let sphere = SCNSphere(radius: 10)
        sphere.segmentCount = 96
        sphere.firstMaterial?.diffuse.contents = image
        sphere.firstMaterial?.isDoubleSided = true
        sphere.firstMaterial?.diffuse.wrapS = .repeat
        sphere.firstMaterial?.diffuse.wrapT = .clamp
        sphere.firstMaterial?.cullMode = .front

        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.scale = SCNVector3(-1, 1, 1)
        sceneView.scene?.rootNode.addChildNode(sphereNode)
    }

    private func addCloseButton() {
        let buttonSize: CGFloat = 40
        let closeButton = UIButton(type: .system)

        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let closeImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        closeButton.layer.cornerRadius = buttonSize / 2
        closeButton.clipsToBounds = true

        closeButton.frame = CGRect(x: view.bounds.width - buttonSize - 20, y: 50, width: buttonSize, height: buttonSize)
        closeButton.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        closeButton.addTarget(self, action: #selector(closeViewer), for: .touchUpInside)

        view.addSubview(closeButton)
    }

    @objc private func closeViewer() {
        dismiss(animated: true)
    }
}
