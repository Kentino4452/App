// ImageStitcher.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, StitcherStatus) {
    StitcherStatusSuccess,
    StitcherStatusErrorInput,
    StitcherStatusErrorStitching
};

@interface ImageStitcher : NSObject

@property (nonatomic, assign) double panoConfidenceThresh;
@property (nonatomic, assign) double blendingStrength;
@property (nonatomic, assign) BOOL waveCorrection;

- (instancetype)init;

- (nullable UIImage *)stitchImages:(NSArray<UIImage *> *)images
                             error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END



