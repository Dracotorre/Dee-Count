//
//  ToolsActionViewController.h
//  Dee Count
//
//  Created by David G Shrock on 8/18/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ToolsActionsDelegate;

@interface ToolsActionViewController : UITableViewController

// completion block for caller
@property (nonatomic, copy) void (^dismissBlock)(void);
@property (nonatomic) BOOL scanCodeIsAvailable;
@property (nonatomic, weak) id <ToolsActionsDelegate> toolsActionDelegate;

@end

@protocol ToolsActionsDelegate <NSObject>

- (void)resetCounts;
- (void)clearAllItems;
- (void)clearZeroCountItems;
- (void)restartAll;
- (void)showCompareCountHelp;

@end
