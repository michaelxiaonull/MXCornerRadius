//
//  ViewController.m
//  MXCornerRadius
//
//  Created by Michael on 2018/11/27.
//  Copyright © 2018 Michael. All rights reserved.
//

#import "ViewController.h"
#import "MXCornerRadius.h"
#import "TableViewController.h"
#import <objc/runtime.h>

@interface ViewController () {
    NSHashTable *_table;
}

@property (weak, nonatomic) IBOutlet UIImageView *cornerImgView;

@property (weak, nonatomic) IBOutlet UITextField *cornerTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //`printDebugLogForRoundImageCache` defaults `NO`
    [MXRoundImageCacheManager sharedManager].printDebugLogForRoundImageCache = YES;
    self.cornerImgView.mxCornerRadius = self.cornerTextField.text.floatValue;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (IBAction)enableDebugLogButtonClicked:(UIButton *)sender {
    [MXRoundImageCacheManager sharedManager].printDebugLogForRoundImageCache = ![MXRoundImageCacheManager sharedManager].printDebugLogForRoundImageCache;
    [sender setTitle:[MXRoundImageCacheManager sharedManager].printDebugLogForRoundImageCache ? @"disable debug log" : @"enable debug log" forState:UIControlStateNormal];
}

- (IBAction)removeCacheButtonClicked:(UIButton *)sender {
    [self.cornerImgView removeFromSuperview];
    //cache images of imageView will all dealloc when imageView dealloc, set `[MXRoundImageCacheManager sharedManager].printDebugLogForRoundImageCache = YES` and see logs in console
    //`- [UIImageView dealloc]` -> `- [MXImageViewObserver dealloc]` -> `MXImageViewObserver.cacheImagesDictM = nil`
}

- (IBAction)pushTableViewControllerButtonClicked:(UIButton *)sender {
    BOOL disableAllImageViewRoundImageCache = [sender.currentTitle containsString:@"disabled"];
    [self.navigationController pushViewController:[TableViewController viewControllerWithDisableAllImageViewRoundImageCache:disableAllImageViewRoundImageCache] animated:YES];
}

- (IBAction)buttonClicked:(UIButton *)sender {
    CGFloat cornerRadius = self.cornerTextField.text.floatValue;
    if ([sender.currentTitle isEqualToString:@"-"]) {
        cornerRadius -= 5;
    } else {
        cornerRadius += 5;
    }
    cornerRadius = MAX(0, cornerRadius);
    self.cornerTextField.text = [NSString stringWithFormat:@"%.1f", cornerRadius];
    self.cornerImgView.mxCornerRadius = cornerRadius;
}

@end
