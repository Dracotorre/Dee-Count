//
//  DTCountAidViewController.h
//  Dee Count
//
//  Created by David G Shrock on 9/18/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AidResetViewDelegate;

@interface DTCountAidResetViewController : UIViewController

@property (nonatomic, weak) id <AidResetViewDelegate> delegate;
@property (nonatomic) BOOL compareCountsExists;

@end

@protocol AidResetViewDelegate <NSObject>

- (void)resetCountsNowReplacingCompare:(BOOL)replace;

@end