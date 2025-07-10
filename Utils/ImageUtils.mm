// ImageUtils.mm

#import "ImageUtils.h"
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/imgcodecs/ios.h>

void UIImageToMat(UIImage *image, cv::Mat &mat, bool alpha) {
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

    void *data = malloc(size.width * size.height * 4);
    if (!data) {
        mat = cv::Mat();
        CGColorSpaceRelease(colorSpace);
        return;
    }

    CGContextRef contextRef = CGBitmapContextCreate(
        data, size.width, size.height,
        8, size.width * 4, colorSpace,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault
    );

    CGContextDrawImage(contextRef, CGRectMake(0, 0, size.width, size.height), imageRef);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(contextRef);

    cv::Mat tmp((int)size.height, (int)size.width, CV_8UC4, data);
    mat = tmp.clone();
    free(data);

    if (!alpha) {
        cv::cvtColor(mat, mat, cv::COLOR_RGBA2BGR);
    } else {
        cv::cvtColor(mat, mat, cv::COLOR_RGBA2BGRA);
    }
}

UIImage * MatToUIImage(const cv::Mat &mat) {
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
            rgbaMat = mat.clone();
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

    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];

    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return finalImage;
}
