//
//  MXCornerRadius.h
//  0515 - MXCornerRadius
//
//  Created by Michael on 2017/5/15.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MXImageViewObserver;
#pragma mark - ---------------------------- MXRoundImageCacheManager ---------------------------------------
@interface MXRoundImageCacheManager : NSObject

/**
 * default is NO, when YES, console logs how many cornerRadius images current imageObserver has cached and other imageObservers have cached
 */
@property(nonatomic, getter=shouldPrintDebugLogForRoundImageCache) BOOL printDebugLogForRoundImageCache;

+ (instancetype)sharedManager;

@end

#pragma mark - ---------------------------- UIImageView (AddCornerRadius) ---------------------------------------
@interface UIImageView (AddCornerRadius)

@property (nonatomic) CGFloat mxCornerRadius;
/**
 * default is NO, cache cornerRadius image to improve FPS, when NO, CPU generate each time when image has a new image, mxCornerRadius changed and contentMode changed
 */
@property (nonatomic, getter=shouldMxDisableRoundImageCache) BOOL mxDisableRoundImageCache;

/**
 * cache collection, key is `[NSString stringWithFormat:@"originalImageAddress_%p_cornerRadius_%.1lf", _originalImage, _mxCornerRadius]`, value is cornerRadius image
 */
@property (nonatomic, readonly, weak) NSMutableDictionary<NSString *, UIImage *> *cacheImagesDictM;

@end
