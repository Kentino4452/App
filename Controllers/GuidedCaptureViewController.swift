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

    private let progressCircle = CircularProgressView()
    private var isCapturing = false
    private let ghostPreview = UIImageView()

    private var hdrBracketImages: [CIImage] = []
    private var stitchedImages: [UIImage] = []
    var propertyID: Int!
    private let expectedShots = 24 // Numero di foto HDR da accumulare prima dello stitching

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
            captureSession.startRunning()

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
                self.captureHDRBracket()
                self.nextTargetAngle = self.normalizeAngle(self.nextTargetAngle + self.targetAngleStep)

                UIImpactFeedbackGenerator(style: .light).impactOccurred()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self.isCapturing = false
                }
            }
        }
    }

    private func captureHDRBracket() {
        let settings = AVCapturePhotoBracketSettings(rawPixelFormatType: 0,
                                                     processedFormat: [AVVideoCodecKey: AVVideoCodecType.jpeg],
                                                     bracketedSettings: [
                                                        AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: -1.0),
                                                        AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: 0.0),
                                                        AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: 1.0)
                                                     ])
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Errore scatto: \(error.localizedDescription)")
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let ciImage = CIImage(data: data) else { return }

        hdrBracketImages.append(ciImage)

        if hdrBracketImages.count == 3 {
            let merged = mergeHDR(images: hdrBracketImages)
            let context = CIContext()
            if let merged = merged,
               let cgImage = context.createCGImage(merged, from: merged.extent) {
                let finalImage = UIImage(cgImage: cgImage)
                ghostPreview.image = finalImage
                processImageForStitching(finalImage)
            }
            hdrBracketImages.removeAll()
        }
    }

    private func mergeHDR(images: [CIImage]) -> CIImage? {
        guard images.count == 3 else { return nil }
        let filter = CIFilter(name: "CIHighlightShadowAdjust")
        filter?.setValue(images[1], forKey: kCIInputImageKey)
        filter?.setValue(1.0, forKey: "inputShadowAmount")
        filter?.setValue(0.7, forKey: "inputHighlightAmount")
        return filter?.outputImage
    }

private func processImageForStitching(_ image: UIImage) {
    stitchedImages.append(image)

    if stitchedImages.count == expectedShots {
        let stitcher = ImageStitcher()
        stitcher.panoConfidenceThresh = 0.8
        stitcher.blendingStrength = 8
        stitcher.waveCorrection = true

        var error: NSError?
        if let panorama = stitcher.stitchImages(stitchedImages, error: &error) {
            
            // 🔐 Recupero token salvato
            guard let token = UserDefaults.standard.string(forKey: "authToken") else {
                print("⚠️ Token non trovato. Upload non eseguito.")
                return
            }

            // 📤 Upload immagine panoramica
            ImageUploader.upload(
                image: panorama,
                to: "http://127.0.0.1:8000/api/upload-panorama/",
                propertyID: self.propertyID,
                token: token
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
                        // (opzionale) mostra un alert all’utente
                    }
                }
            }
        } else {
            print("❌ Errore stitching: \(error?.localizedDescription ?? "Sconosciuto")")
            // (opzionale) mostra un alert all’utente
        }

        // 🧹 Pulisce la lista per il prossimo uso
        stitchedImages.removeAll()
    }
}



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
