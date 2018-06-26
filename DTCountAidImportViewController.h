//
//  DTCountAidImportViewController.h
//  Dee Count
//
//  Created by David G Shrock on 9/18/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AidImportViewDelegate;

@interface DTCountAidImportViewController : UIViewController

@property (nonatomic, weak) id <AidImportViewDelegate> delegate;

@end

@protocol AidImportViewDelegate <NSObject>

- (void)importCountsAidRequested;
- (void)importCountsGuidedRequested;

@end