// ImageStitcher.mm

#import "ImageStitcher.h"

// Evita conflitto tra UIKit (BOOL) NO e macro NO in OpenCV
#ifdef NO
#undef NO
#endif

#import "opencv.hpp"
#import "stitching.hpp"
#import "ImageUtils.h"
#import "core.hpp"

@implementation ImageStitcher {
    cv::Ptr<cv::Stitcher> _stitcher; // 🔧 miglioramento 2: reuse dello stitcher
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _panoConfidenceThresh = 0.7;
        _blendingStrength = 8.0;
        _waveCorrection = YES;

        // 🔧 miglioramento 2: inizializza lo stitcher una sola volta
        _stitcher = cv::Stitcher::create(cv::Stitcher::PANORAMA);
    }
    return self;
}

- (nullable UIImage *)stitchImages:(NSArray<UIImage *> *)images error:(NSError **)error {
    if (images.count < 2) {
        if (error) {
            *error = [NSError errorWithDomain:@"ImageStitcher"
                                         code:StitcherStatusErrorInput
                                     userInfo:@{NSLocalizedDescriptionKey: @"Servono almeno due immagini per effettuare lo stitching."}];
        }
        return nil;
    }

    // --- UIImage -> cv::Mat
    std::vector<cv::Mat> mats;
    mats.reserve(images.count);
    for (UIImage *img in images) {
        if (!img) continue;
        cv::Mat m;
        UIImageToMat(img, &m, /*alpha*/false);
        if (!m.empty()) mats.push_back(m);
    }

    if (mats.size() < 2) {
        if (error) {
            *error = [NSError errorWithDomain:@"ImageStitcher"
                                         code:StitcherStatusErrorInput
                                     userInfo:@{NSLocalizedDescriptionKey: @"Non è stato possibile convertire abbastanza immagini valide."}];
        }
        return nil;
    }

    cv::Mat pano;

    // --- Configurazione dello stitcher riusato
    _stitcher->setPanoConfidenceThresh(self.panoConfidenceThresh);
    _stitcher->setWaveCorrection(self.waveCorrection);
    _stitcher->setWaveCorrectKind(cv::detail::WAVE_CORRECT_HORIZ);

    // Exposure compensator 🔧 miglioramento 5
    {
        auto compensator = cv::makePtr<cv::detail::BlocksGainCompensator>();
        _stitcher->setExposureCompensator(compensator);
    }

    // Seam finder
    _stitcher->setSeamFinder(cv::makePtr<cv::detail::GraphCutSeamFinder>(
        cv::detail::GraphCutSeamFinderBase::COST_COLOR));

    // Blender 🔧 miglioramento 3: livelli qualità al posto di valore libero
    {
        cv::Ptr<cv::detail::Blender> blender =
            cv::detail::Blender::createDefault(cv::detail::Blender::MULTI_BAND, false);
        if (auto* mb = dynamic_cast<cv::detail::MultiBandBlender*>(blender.get())) {
            int bands;
            if (self.blendingStrength < 5.0) {
                bands = 3; // Low
            } else if (self.blendingStrength < 10.0) {
                bands = 7; // Medium
            } else {
                bands = 12; // High
            }
            mb->setNumBands(bands);
        }
        _stitcher->setBlender(blender);
    }

    // Warper sferico
    _stitcher->setWarper(cv::makePtr<cv::SphericalWarper>());

    // --- Esecuzione stitching
    cv::Stitcher::Status status = _stitcher->stitch(mats, pano);

    if (status == cv::Stitcher::OK && !pano.empty()) {
        cv::Mat corrected = [self correctHorizon:pano];
        return MatToUIImage((const void*)&corrected);
    }

    // --- Error handling
    if (error) {
        NSString *reason;
        switch (status) {
            case cv::Stitcher::ERR_NEED_MORE_IMGS:
                reason = @"Servono più immagini per completare lo stitching.";
                break;
            case cv::Stitcher::ERR_HOMOGRAPHY_EST_FAIL:
                reason = @"Impossibile stimare l'omografia. Controlla la sovrapposizione tra immagini.";
                break;
            case cv::Stitcher::ERR_CAMERA_PARAMS_ADJUST_FAIL:
                reason = @"Fallita la regolazione dei parametri di camera. Possibile parallasse elevata.";
                break;
            default:
                reason = @"Errore sconosciuto durante lo stitching.";
                break;
        }
        *error = [NSError errorWithDomain:@"ImageStitcher"
                                     code:StitcherStatusErrorStitching
                                 userInfo:@{
                                     NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Errore di stitching (codice OpenCV %d)", (int)status],
                                     NSLocalizedFailureReasonErrorKey: reason
                                 }];
    }
#if DEBUG
    NSLog(@"[Stitcher] Fallimento con codice %d", (int)status);
#endif
    return nil;
}

// Correzione orizzonte
- (cv::Mat)correctHorizon:(const cv::Mat&)image {
    cv::Mat gray, edges;
    cv::cvtColor(image, gray, cv::COLOR_BGR2GRAY);
    cv::Canny(gray, edges, 50, 150);

    std::vector<cv::Vec2f> lines;
    cv::HoughLines(edges, lines, 1, CV_PI/180, 250); // 🔧 miglioramento 1: CV_PI moderno

    double angleSum = 0;
    int count = 0;
    for (const auto& line : lines) {
        float theta = line[1];
        double angle = theta * 180 / CV_PI;
        if (angle > 80 && angle < 100) { angleSum += angle; count++; }
    }

    if (count == 0) return image;

    double avgAngle = (angleSum / count) - 90.0;
    if (std::abs(avgAngle) < 0.3) return image;

    cv::Point2f center(image.cols / 2.0f, image.rows / 2.0f);
    cv::Mat rotMat = cv::getRotationMatrix2D(center, avgAngle, 1.0);
    cv::Mat rotated;
    cv::warpAffine(image, rotated, rotMat, image.size(), cv::INTER_LINEAR, cv::BORDER_REPLICATE);
    return rotated;
}

@end





