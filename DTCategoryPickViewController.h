//
//  DTCategoryPickViewController.h
//  Dee Count
//
//  Created by David G Shrock on 9/10/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DTCountItem;
@class DTCountLocation;

@protocol DTCategoryPickDelegate;

@interface DTCategoryPickViewController : UIViewController <UITableViewDataSource, UITableViewDataSource>

@property (nonatomic, strong) DTCountItem *item;
@property (nonatomic, strong) DTCountLocation *location;
@property (weak, nonatomic) IBOutlet UITextField *categoryTextField;
@property (nonatomic, copy) void (^dismissBlock)(void);
@property (nonatomic, weak) id <DTCategoryPickDelegate>delegate;
@property (nonatomic) BOOL showUpdateAllOption;

@end

@protocol DTCategoryPickDelegate <NSObject>

- (void)updateCategoryForUncategorizedItemsForLocation:(DTCountLocation *)location;

@end