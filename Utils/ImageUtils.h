// ImageUtils.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Converte UIImage in un cv::Mat. Se alpha è true, preserva il canale alpha.
/// Il parametro matPtr deve puntare a un cv::Mat.
void UIImageToMat(UIImage *image, void *matPtr, bool alpha);

/// Converte un cv::Mat in UIImage.
/// Il parametro matPtr deve puntare a un cv::Mat.
UIImage * _Nullable MatToUIImage(const void *matPtr);

/// Verifica la nitidezza di una UIImage usando la varianza del Laplaciano.
/// Ritorna true se l’immagine è abbastanza nitida.
BOOL IsImageSharp(UIImage *image, double threshold);

NS_ASSUME_NONNULL_END

