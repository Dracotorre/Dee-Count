//
//  DocFormatPickViewController.h
//  Dee Count
//
//  Created by David G Shrock on 9/8/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DocFormatPickerDelegate;

@interface DocFormatPickViewController : UIViewController

@property (nonatomic, weak) id <DocFormatPickerDelegate>delegate;
@property (nonatomic) BOOL hidden;

@end

@protocol DocFormatPickerDelegate <NSObject>

- (void)pickedFormatDCZ;
- (void)pickedFormatCSV;
- (void)canceledPicker;

@end