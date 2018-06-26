//
//  DTCountAidExportViewController.h
//  Dee Count
//
//  Created by David G Shrock on 9/18/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AidExportViewDelegate;

@interface DTCountAidExportViewController : UIViewController

@property (nonatomic) BOOL compareCountsExist;
@property (nonatomic, weak) id <AidExportViewDelegate> delegate;

@end

@protocol AidExportViewDelegate <NSObject>

- (void)exportCountsAidRequested;

@end