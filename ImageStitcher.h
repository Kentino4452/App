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

/// Valore di soglia di confidenza per lo stitching (default 0.7)
@property (nonatomic, assign) double panoConfidenceThresh;

/// Valore di blending strength per la fusione (default 8)
@property (nonatomic, assign) double blendingStrength;

/// Flag per abilitare correzione delle onde (default YES)
@property (nonatomic, assign) BOOL waveCorrection;

/// Inizializzatore di default
- (instancetype)init;

/// Esegue lo stitching di un array di immagini. Restituisce un UIImage in caso di successo, altrimenti nil e imposta l'oggetto NSError.
/// @param images Array di UIImage da unire.
/// @param error Oggetto NSError popolato in caso di errore.
/// @return UIImage del panorama unito oppure nil.
- (nullable UIImage *)stitchImages:(NSArray<UIImage *> *)images
                             error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END