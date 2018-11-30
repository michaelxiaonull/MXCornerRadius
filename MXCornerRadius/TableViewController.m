//
//  TableViewController.m
//  MXCornerRadius
//
//  Created by Michael on 2018/11/28.
//  Copyright © 2018 Michael. All rights reserved.
//

#import "TableViewController.h"
#import "MXCornerRadius.h"
#import "UIImageView+WebCache.h"
#import "AppDelegate.h"
#import <objc/runtime.h>

@interface TableViewController () <UITableViewDataSource, UITableViewDelegate> {
    BOOL _disableRoundImageCache;
}

@end

@implementation TableViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"disable debug log" style:UIBarButtonItemStyleDone target:self action:@selector(enableDebugLogButtonClicked:)];
    [self addTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

#pragma mark - public
+ (instancetype)viewControllerWithDisableAllImageViewRoundImageCache:(BOOL)disableRoundImageCache {
    TableViewController *vc = [[TableViewController alloc] init];
    vc.title = [NSString stringWithFormat:@"%@", disableRoundImageCache ? @"disableImageCache" : @"enableImageCache"];
    vc->_disableRoundImageCache = disableRoundImageCache;
    return vc;
}

- (void)enableDebugLogButtonClicked:(UIBarButtonItem *)sender {
    [MXRoundImageCacheManager sharedManager].printDebugLogForRoundImageCache = ![MXRoundImageCacheManager sharedManager].printDebugLogForRoundImageCache;
    sender.title = [MXRoundImageCacheManager sharedManager].printDebugLogForRoundImageCache ? @"disable debug log" : @"enable debug log";
}

- (void)addTableView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.rowHeight = 70;
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(UITableViewCell.class)];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass(UITableViewCell.class)];
        //`cell.imageView`
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.imageView.mxCornerRadius = 10.0f;
        cell.imageView.mxDisableRoundImageCache = _disableRoundImageCache;
        cell.imageView.image = [UIImage imageNamed:@"2.jpg"];
        //`cell.textLabel`
        cell.textLabel.numberOfLines = 0;
        //`accessoryImgView`
        UIImageView *accessoryImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 10, 50, 50)];
        accessoryImgView.mxDisableRoundImageCache = _disableRoundImageCache;
        accessoryImgView.contentMode = UIViewContentModeScaleAspectFill;
        accessoryImgView.mxCornerRadius = 25.0f;
        cell.accessoryView = accessoryImgView;
    }
    NSString *url = nil;
    switch (indexPath.row % 3) {
        case 0:
            url = @"http://pic24.nipic.com/20121022/1417516_151626862000_2.jpg";
            break;
        case 1:
            url = @"http://img3.doubanio.com/view/commodity_review/large/public/p200907257.jpg";
            break;
        case 2:
            url = @"http://pic26.nipic.com/20130114/9252150_140310235330_2.jpg";
            break;
    }
    [(UIImageView *)cell.accessoryView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"1"] options:SDWebImageLowPriority|SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        cell.textLabel.text = [NSString stringWithFormat:@"accessoryImgView has alread cached %ld \n", ((UIImageView *)cell.accessoryView).cacheImagesDictM.count];
    }];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    ((UIImageView *)cell.accessoryView).mxCornerRadius = 10;
    dispatch_after(2, dispatch_get_main_queue(), ^{
        cell.accessoryView = nil;
    });
}

@end
