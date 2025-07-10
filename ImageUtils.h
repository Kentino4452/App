// ImageUtils.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <opencv2/core/core.hpp>

NS_ASSUME_NONNULL_BEGIN

/// Converte UIImage in cv::Mat. Se alpha è true, preserva canale alpha.
void UIImageToMat(UIImage *image, cv::Mat &mat, bool alpha = false);

/// Converte cv::Mat in UIImage. Restituisce nil se la conversione fallisce.
UIImage * _Nullable MatToUIImage(const cv::Mat &mat);

NS_ASSUME_NONNULL_END
