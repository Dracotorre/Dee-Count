//
//  DeleteLocationConfirmViewController.h
//  Dee Count
//
//  Created by David G Shrock on 8/31/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DeleteConfirmDelegate;

@interface DeleteConfirmViewController : UIViewController

@property (nonatomic) int deleteKey;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, copy) void (^dismissBlock)(void);
@property (nonatomic, weak) id <DeleteConfirmDelegate>delegate;

@end

@protocol DeleteConfirmDelegate <NSObject>

- (void)deletionConfirmed:(BOOL)confirm forKey:(int)key;

@end