//
//  MasterViewController.h
//  Dee Count
//
//  Created by David G Shrock on 8/7/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
//  updated from 2010 version 1, RootViewController_iPad
//  - ARC and style and iOS 8 layout
//  - delegate improvements
//  - moved local variables to properties

#import <UIKit/UIKit.h>
#import "StartupOperation.h"
#import "LoadDataCancelDelegate.h"
#import "DetailViewController.h"

//@class DetailViewController;
@class DTCountLocation;
@protocol LocationUpdateDelegate;

@interface MasterViewController : UITableViewController <StartupOperationDelegate, LoadDataCancelDelegate, DCountDetailLocationUpdatedDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (nonatomic, assign) id<LocationUpdateDelegate> locDelegate;

- (void)setLaunchWithURL:(NSURL *)url;
- (void)saveStatus;
- (void)scanQRDefaultPrefChanged:(BOOL)on;

@end

@protocol LocationUpdateDelegate

- (void)locationUpdated:(DTCountLocation *)loc;

@end