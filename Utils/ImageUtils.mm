// ImageUtils.mm

#import "ImageUtils.h"
#import "core.hpp"
#import "imgproc.hpp"
#import "imgcodecs.hpp"

/// ⚡ Resize helper per evitare crash da memoria
static cv::Mat resizeIfNeeded(const cv::Mat &src, int maxDim) {
    if (maxDim <= 0) return src; // nessun resize richiesto
    int maxSide = std::max(src.cols, src.rows);
    if (maxSide <= maxDim) return src; // già piccolo
    double scale = (double)maxDim / maxSide;
    cv::Mat dst;
    cv::resize(src, dst, cv::Size(), scale, scale, cv::INTER_AREA);
    return dst;
}

void UIImageToMat(UIImage *image, void *matPtr, bool alpha) {
    cv::Mat &mat = *(cv::Mat *)matPtr;

    if (!image) {
        mat = cv::Mat();
        return;
    }

    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        mat = cv::Mat();
        return;
    }

    CGSize size = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace) {
        mat = cv::Mat();
        return;
    }

    void *data = malloc(size.width * size.height * 4);
    if (!data) {
        CGColorSpaceRelease(colorSpace);
        mat = cv::Mat();
        return;
    }

    CGContextRef contextRef = CGBitmapContextCreate(
        data, size.width, size.height,
        8, size.width * 4, colorSpace,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault
    );

    if (!contextRef) {
        free(data);
        CGColorSpaceRelease(colorSpace);
        mat = cv::Mat();
        return;
    }

    CGContextDrawImage(contextRef, CGRectMake(0, 0, size.width, size.height), imageRef);

    cv::Mat tmp((int)size.height, (int)size.width, CV_8UC4, data);

    // ✅ Copia sicura e libera memoria CoreGraphics
    mat = tmp.clone();

    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    free(data);

    // ✅ Conversione a BGR o BGRA (default per OpenCV)
    if (!alpha) {
        cv::cvtColor(mat, mat, cv::COLOR_RGBA2BGR);
    } else {
        cv::cvtColor(mat, mat, cv::COLOR_RGBA2BGRA);
    }

    // ✅ Resize automatico (max lato 3000px per risparmiare RAM)
    mat = resizeIfNeeded(mat, 3000);
}

UIImage * MatToUIImage(const void *matPtr) {
    const cv::Mat &mat = *(const cv::Mat *)matPtr;

    if (mat.empty()) return nil;

    cv::Mat rgbaMat;
    switch (mat.type()) {
        case CV_8UC1:
            cv::cvtColor(mat, rgbaMat, cv::COLOR_GRAY2RGBA);
            break;
        case CV_8UC3:
            cv::cvtColor(mat, rgbaMat, cv::COLOR_BGR2RGBA);
            break;
        case CV_8UC4:
            cv::cvtColor(mat, rgbaMat, cv::COLOR_BGRA2RGBA);
            break;
        default:
            return nil;
    }

    NSData *data = [NSData dataWithBytes:rgbaMat.data length:rgbaMat.elemSize() * rgbaMat.total()];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);

    CGImageRef imageRef = CGImageCreate(
        rgbaMat.cols, rgbaMat.rows,
        8, 32, rgbaMat.step[0],
        colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaLast,
        provider, NULL, false, kCGRenderingIntentDefault
    );

    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:UIScreen.mainScreen.scale orientation:UIImageOrientationUp];

    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return finalImage;
}

/// ✅ Controllo nitidezza con varianza del Laplaciano
BOOL IsImageSharp(UIImage *image, double threshold) {
    if (!image) return NO;

    cv::Mat mat;
    UIImageToMat(image, &mat, false);
    if (mat.empty()) return NO;

    cv::Mat gray;
    if (mat.channels() == 3) {
        cv::cvtColor(mat, gray, cv::COLOR_BGR2GRAY);
    } else if (mat.channels() == 4) {
        cv::cvtColor(mat, gray, cv::COLOR_BGRA2GRAY);
    } else {
        gray = mat.clone();
    }

    cv::Mat lap;
    cv::Laplacian(gray, lap, CV_64F);

    cv::Scalar mean, stddev;
    cv::meanStdDev(lap, mean, stddev);

    return stddev[0] > threshold;
}




