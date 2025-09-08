import UIKit
import AVFoundation
import CoreMotion
import CoreImage

class GuidedCaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    private let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let motionManager = CMMotionManager()
    private var referenceYaw: Double?
    private let targetAngleStep = Double.pi / 12 // 15°
    private var nextTargetAngle: Double = 0
    private var isCapturing = false
    private var retryCount = 0

    private let progressCircle = CircularProgressView()
    private let ghostPreview = UIImageView()

    private var stitchedImages: [UIImage] = []
    private let propertyID: Int   // 🔒 obbligatorio
    private let expectedShots = 24

    // ✅ Init sicuro: obbliga a passare propertyID
    init(propertyID: Int) {
        self.propertyID = propertyID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) non implementato, usa init(propertyID:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkPermissionsAndSetup()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSessionAndMotion()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            captureSession.startRunning()
            startMotionUpdates()
        }
    }

    // MARK: - Setup
    private func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.setupCaptureSession() : self?.showPermissionDeniedAlert()
                }
            }
        default:
            showPermissionDeniedAlert()
        }
    }

    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showCameraErrorAlert()
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(previewLayer, at: 0)

            captureSession.commitConfiguration()
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
            startMotionUpdates()
        } catch {
            showCameraErrorAlert()
        }
    }

    private func setupUI() {
        ghostPreview.frame = view.bounds
        ghostPreview.contentMode = .scaleAspectFill
        ghostPreview.alpha = 0.25
        ghostPreview.isUserInteractionEnabled = false
        ghostPreview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(ghostPreview)

        progressCircle.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        progressCircle.center = view.center
        view.addSubview(progressCircle)
    }

    // MARK: - Motion
    private func startMotionUpdates() {
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, _) in
            guard let self = self, let attitude = motion?.attitude else { return }

            if self.referenceYaw == nil {
                self.referenceYaw = attitude.yaw
                self.nextTargetAngle = self.normalizeAngle(attitude.yaw + self.targetAngleStep)
            }

            let delta = self.angleDifference(attitude.yaw, self.nextTargetAngle)
            let progress = min(1.0, max(0.0, 1.0 - abs(delta) / (self.targetAngleStep)))
            self.progressCircle.setProgress(progress)

            if abs(delta) < 0.05 && !self.isCapturing {
                self.isCapturing = true
                self.captureSinglePhoto()
            }
        }
    }

    // MARK: - Capture
    private func captureSinglePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        if photoOutput.supportedFlashModes.contains(.off) {
            settings.flashMode = .off
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("❌ Errore scatto: \(error.localizedDescription)")
            isCapturing = false
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            isCapturing = false
            return
        }

        // 🔍 Controllo nitidezza (usa ImageUtils.mm)
        if !IsImageSharp(image, 100.0) {
            if retryCount < 2 {
                retryCount += 1
                print("⚠️ Foto sfocata, retry #\(retryCount)")
                captureSinglePhoto()
                return
            } else {
                print("❌ Foto troppo sfocata, scartata.")
                retryCount = 0
                isCapturing = false
                return
            }
        }

        retryCount = 0 // reset retry se foto valida
        ghostPreview.image = image
        processImageForStitching(image)

        // Avanza all’angolo successivo
        self.nextTargetAngle = self.normalizeAngle(self.nextTargetAngle + self.targetAngleStep)
        self.isCapturing = false
    }

    // MARK: - Stitching
    private func processImageForStitching(_ image: UIImage) {
        stitchedImages.append(image)

        if stitchedImages.count == expectedShots {
            let stitcher = ImageStitcher()
            stitcher.panoConfidenceThresh = 0.8
            stitcher.blendingStrength = 8
            stitcher.waveCorrection = true

            do {
                let panorama = try stitcher.stitch(stitchedImages)

                ImageUploader.upload(
                    image: panorama,
                    to: self.propertyID
                ) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let url):
                            let viewer = PanoramaViewerViewController()
                            viewer.modalPresentationStyle = .fullScreen
                            viewer.panoramaImageURL = url
                            self.present(viewer, animated: true)
                        case .failure(let error):
                            print("❌ Upload fallito: \(error.localizedDescription)")
                        }
                    }
                }
            } catch {
                print("❌ Errore stitching: \(error.localizedDescription)")
            }

            stitchedImages.removeAll()
        }
    }

    // MARK: - Helpers
    private func stopSessionAndMotion() {
        captureSession.stopRunning()
        motionManager.stopDeviceMotionUpdates()
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(title: "Permessi necessari", message: "Abilita la fotocamera nelle impostazioni.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        })
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        present(alert, animated: true)
    }

    private func showCameraErrorAlert() {
        let alert = UIAlertController(title: "Errore fotocamera", message: "Impossibile accedere alla fotocamera.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle
        while normalized < -Double.pi { normalized += 2 * Double.pi }
        while normalized > Double.pi { normalized -= 2 * Double.pi }
        return normalized
    }

    private func angleDifference(_ a: Double, _ b: Double) -> Double {
        return normalizeAngle(b - a)
    }
}

