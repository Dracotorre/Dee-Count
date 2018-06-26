//
//  DTCountAidManageViewController.h
//  Dee Count
//
//  Created by David G Shrock on 9/18/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CountAidDelegate;

@interface DTCountAidManageViewController : UITabBarController

@property (nonatomic, copy) void (^dismissBlock)(void);
@property (nonatomic, weak) id <CountAidDelegate> countAidDelegate;

- (instancetype)initForCompareCountsExists:(BOOL)compareExists;

@end


@protocol CountAidDelegate <NSObject>

- (void)resetCountsNowReplacingCompare:(BOOL)replace;
- (void)exportAidRequest;
- (void)importAidRequestIsGuided:(BOOL)guided;

@end