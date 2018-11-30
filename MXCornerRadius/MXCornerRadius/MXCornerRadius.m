//
//  MXCornerRadius.m
//  0515 - MXCornerRadius
//
//  Created by Michael on 2017/5/15.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "MXCornerRadius.h"
#import <objc/runtime.h>

#pragma mark - ---------------------------- NSMapTable (MXCornerRadiusSubscripting) ---------------------------------------
@implementation NSMapTable (MXCornerRadiusSubscripting)

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key
{
    if (obj != nil) {
        [self setObject:obj forKey:key];
    } else {
        [self removeObjectForKey:key];
    }
}

@end

#pragma mark - ---------------------------- MXRoundImageCacheManager ---------------------------------------
@interface MXRoundImageCacheManager ()

@property(nonatomic) NSMapTable<NSString *, MXImageViewObserver *> *cacheObserversMapTable;

@end

@implementation MXRoundImageCacheManager

+ (instancetype)sharedManager {
    static MXRoundImageCacheManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[super allocWithZone:nil] init];
        sharedManager.cacheObserversMapTable = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
    });
    return sharedManager;
}

@end

#pragma mark - ---------------------------- MXImageViewObserver ---------------------------------------
@interface MXImageViewObserver : NSObject {
    NSUInteger _repeatGetImageBoundsCount;
}

@property (nonatomic, assign) UIImageView *imageView;
@property (nonatomic) UIImage *originalImage;
@property (nonatomic) UIImage *lastCornerRadiusImage;//used when `mxDisableRoundImageCache` set `YES`
@property (nonatomic) NSMutableDictionary<NSString *, UIImage *> *cacheImagesDictM;
@property (nonatomic) CGFloat mxCornerRadius;
@property (nonatomic, getter=shouldMxDisableRoundImageCache) BOOL mxDisableRoundImageCache;

+ (instancetype)imageViewObserverWithImageView:(UIImageView *)imageView;

@end

@implementation MXImageViewObserver

#pragma mark - override
- (NSString *)description {
    return [NSString stringWithFormat:@"<\n%@: %p cacheImagesDictM: %@ >", self.class, self, self.cacheImagesDictM];
}

#pragma mark - life cycle
- (void)dealloc {
    [self.imageView removeObserver:self forKeyPath:@"image"];
    [self.imageView removeObserver:self forKeyPath:@"contentMode"];
    if ([MXRoundImageCacheManager sharedManager].shouldPrintDebugLogForRoundImageCache && !self.shouldMxDisableRoundImageCache) {
        NSLog(@"\n >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MXCornerRadius log begin <<<<<<<<<<<<<<<<<<<<<<<<\n\n after `- [MXImageViewObserver dealloc]`, MXImageViewObserver object has released: \n\"%@\" \n other MXImageViewObserver objects still live, \"cacheObserversMapTable\" :\n \"%@\" \n >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MXCornerRadius log end <<<<<<<<<<<<<<<<<<<<<<<<\n", self.cacheImagesDictM, [MXRoundImageCacheManager sharedManager].cacheObserversMapTable);
    }
}

+ (instancetype)imageViewObserverWithImageView:(UIImageView *)imageView {
    
    MXImageViewObserver *imageViewObserver = [MXImageViewObserver new];
    
    //imageViewObserver.mxCornerRadius = cornerRadius;
    imageViewObserver.imageView = imageView;
    imageViewObserver.cacheImagesDictM = @{}.mutableCopy;
    //imageViewObserver.originalImage = imageView.image;
    
    [imageView addObserver:imageViewObserver forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
    [imageView addObserver:imageViewObserver forKeyPath:@"contentMode" options:NSKeyValueObservingOptionNew context:nil];
    
    return imageViewObserver;
}

#pragma mark - setter methods
- (void)setMxCornerRadius:(CGFloat)mxCornerRadius {
    
    if (_mxCornerRadius != mxCornerRadius) {
        
        //去掉旧的图片缓存
        //        NSString *cacheImagekey = [NSString stringWithFormat:@"originalImageAddress_%p_cornerRadius_%.1lf", _originalImage, _mxCornerRadius];
        //        [[MXRoundImageCacheManager sharedManager].cacheImagesDictM removeObjectForKey:cacheImagekey];
        _mxCornerRadius = mxCornerRadius;
        
        //生成的图片缓存
        /**
         * 因为是拿`imageView.layer`放到上下文中渲染，所以如果之前的`imageView.image`的`mxCornerRadius`比较大，但是
         * 新的`mxCornerRadius`小于之前的话，代表需要显示更多的图片内容，但是剪的内容都是白色，看不出效果，因此需要重新设置为原图
         */
        if (_originalImage) {
            _imageView.image = _originalImage;
            //[self updateImageViewIfContextExisted];
        } else if (_imageView.image) {
            _originalImage = _imageView.image;
            [self updateImageViewIfContextExisted];
        }
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"image"]) {
        UIImage *newImage = change[@"new"];
        if(![newImage isKindOfClass:[UIImage class]]) {
            _originalImage = nil;
            return;
        }
        NSString *cacheImagekey = nil;
        UIImage *cacheImage = nil;
        BOOL shouldSetImageAgain = NO;
        if (!self.mxDisableRoundImageCache) {
            cacheImagekey = [NSString stringWithFormat:@"originalImageAddress_%p_cornerRadius_%.1lf", _originalImage, _mxCornerRadius];
            MXImageViewObserver *observer = [MXRoundImageCacheManager sharedManager].cacheObserversMapTable[cacheImagekey];
            cacheImage = observer.cacheImagesDictM[cacheImagekey];
            shouldSetImageAgain = !cacheImage || (cacheImage != newImage);
        } else {
            cacheImage = _lastCornerRadiusImage;
            shouldSetImageAgain = !cacheImage || (cacheImage != newImage);
        }
        if (shouldSetImageAgain) {
            /**
             * 一切生成小图的过程全部依靠原图，如果原图改变，那么需要重新执行`-[MXImageViewObserver updateImageViewIfContextExisted]`, 在`updateImageViewIfContextExisted`方法中已经判断过`缓存`是否包含`原图片的小图片`
             * 1. 当没有图片缓存的时候(!cacheImage)，代表`_originalImage`为空，需要赋值之后再生成小图
             * 2. 如果新图片跟缓存中的不一样(newImage != cacheImage)，则代表`sd_setImage`拿到的是大图，但是需要特别特别注意的是：由于此时`cell.imageView`正在复用`，因此`_originalImage`取到的是之前的旧`indexPath`下的大图，缓存中存在此大图对应的的圆角小图`cacheImage`也是旧的, 需要重新将大图替换为小图，再次执行`updateImageViewIfContextExisted`
             */
            _originalImage = newImage;
            [self updateImageViewIfContextExisted];
        } else if (cacheImage == newImage) {
            /**
             * 如果新图片跟缓存中的一样，则代表是走了自己的`_imageView.image = roundRectImage`
             */
            if ([MXRoundImageCacheManager sharedManager].shouldPrintDebugLogForRoundImageCache && !self.shouldMxDisableRoundImageCache) {
                NSLog(@"\n >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MXCornerRadius log begin <<<<<<<<<<<<<<<<<<<<<<<<\n\n \"%@\" = \"%@\" image has cached!, will not generate again!\n\n >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MXCornerRadius log end <<<<<<<<<<<<<<<<<<<<<<<<\n", cacheImagekey, cacheImage);
            }
        }
    } else if ([keyPath isEqualToString:@"contentMode"]){
        _imageView.image = _originalImage;
    }
}

#pragma mark - private
- (void)updateImageViewIfContextExisted {
    CGRect imageRect = _imageView.bounds;
    __weak __typeof(self) weak_self = self;
    if (CGRectEqualToRect(imageRect, CGRectZero)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weak_self) strong_self = weak_self;
            strong_self->_repeatGetImageBoundsCount++;
            if (strong_self->_repeatGetImageBoundsCount >= 20) {
                //should not recursion
                if ([MXRoundImageCacheManager sharedManager].shouldPrintDebugLogForRoundImageCache) {
                    NSLog(@"\n >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MXCornerRadius log begin <<<<<<<<<<<<<<<<<<<<<<<<\n\n imageView has image but has no bounds, retry %ld times, please check ! \n\n >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MXCornerRadius log end <<<<<<<<<<<<<<<<<<<<<<<<\n", strong_self->_repeatGetImageBoundsCount);
                }
                return;
            }
            [strong_self updateImageViewIfContextExisted];
        });
        return;
    }
    UIImage *cacheImage = nil;
    if (self.shouldMxDisableRoundImageCache) {
        _lastCornerRadiusImage = cacheImage = [self getCornerRadiusImage];
    } else {
        NSString *cacheImagekey = [NSString stringWithFormat:@"originalImageAddress_%p_cornerRadius_%.1lf", _originalImage, _mxCornerRadius];
        MXImageViewObserver *observer = [MXRoundImageCacheManager sharedManager].cacheObserversMapTable[cacheImagekey];
        cacheImage = observer.cacheImagesDictM[cacheImagekey];
        if (!cacheImage) {
            if ([NSStringFromClass(_imageView.image.class) containsString:@"_UIAnimat"]) {
                _imageView.layer.cornerRadius = _mxCornerRadius;
                _imageView.layer.masksToBounds = YES;
                cacheImage = _imageView.image;
            } else {
                cacheImage = [self getCornerRadiusImage];
            }
            [MXRoundImageCacheManager sharedManager].cacheObserversMapTable[cacheImagekey] = self;
            self.cacheImagesDictM[cacheImagekey] = cacheImage;
            if ([MXRoundImageCacheManager sharedManager].printDebugLogForRoundImageCache) {
                NSLog(@"\n >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MXCornerRadius log begin <<<<<<<<<<<<<<<<<<<<<<<<\n\n add new one image cache:%@\n current imageObserver's cacheImagesDictM: %@\n\n >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MXCornerRadius log end <<<<<<<<<<<<<<<<<<<<<<<<\n", cacheImage, self.cacheImagesDictM);
            }
        }
    }
    _imageView.image = cacheImage;
}

- (UIImage *)getCornerRadiusImage {
    CGRect imageRect = _imageView.bounds;
    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, 0);
    [[UIBezierPath bezierPathWithRoundedRect:imageRect cornerRadius:_mxCornerRadius] addClip];
    [_imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *cacheImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return cacheImage;
}

@end

#pragma mark - ---------------------------- UIImageView (AddCornerRadius) ---------------------------------------
@implementation UIImageView (AddCornerRadius)

#pragma mark  - setter
- (void)setMxCornerRadius:(CGFloat)mxCornerRadius {
    mxCornerRadius = MAX(0, mxCornerRadius);
    self.imageViewObserver.mxCornerRadius = mxCornerRadius;
}

- (void)setMxDisableRoundImageCache:(BOOL)mxDisableRoundImageCache {
    self.imageViewObserver.mxDisableRoundImageCache = mxDisableRoundImageCache;
}

#pragma mark - getter
- (CGFloat)mxCornerRadius {
    return self.imageViewObserver.mxCornerRadius;
}

- (BOOL)shouldMxDisableRoundImageCache {
    return self.imageViewObserver.mxDisableRoundImageCache;
}

- (NSMutableDictionary<NSString *,UIImage *> *)cacheImagesDictM {
    return self.imageViewObserver.cacheImagesDictM;
}

- (MXImageViewObserver *)imageViewObserver {
    MXImageViewObserver *imageViewObserver = objc_getAssociatedObject(self, @selector(imageViewObserver));
    if (!imageViewObserver) {
        imageViewObserver = [MXImageViewObserver imageViewObserverWithImageView:self];
        objc_setAssociatedObject(self, @selector(imageViewObserver), imageViewObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return imageViewObserver;
}

@end
