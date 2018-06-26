//
//  CountPadSelectController.h
//  DCount
//
//  Created by David Shrock on 4/28/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CountPadDoneDelegate <NSObject>

- (void)countPadResult:(int)result;

@end

@protocol CountActionDelegate
-(void) selectedResetCounts;
@optional
-(void) selectedClearItems;
@end

@protocol CountActionDelegate;

@interface CountPadSelectController : UIViewController {
    
    IBOutlet UITextField *numberField;
    IBOutlet UIButton *oneKey;
    IBOutlet UIButton *twoKey;
    IBOutlet UIButton *threeKey;
    IBOutlet UIButton *fourKey;
    IBOutlet UIButton *fiveKey;
    IBOutlet UIButton *sixKey;
    IBOutlet UIButton *sevenKey;
    IBOutlet UIButton *eightKey;
    IBOutlet UIButton *nineKey;
    IBOutlet UIButton *zeroKey;
    IBOutlet UIButton *doneKey;
    IBOutlet UIButton *backKey;
    
    int padTotal;
}
@property (nonatomic, weak) id <CountPadDoneDelegate>padDoneDelegate;

- (IBAction)oneKeyPress:(id)sender;
- (IBAction)twoKeyPress:(id)sender;
- (IBAction)threeKeyPress:(id)sender;
- (IBAction)fourKeyPress:(id)sender;
- (IBAction)fiveKeyPress:(id)sender;
- (IBAction)sixKeyPress:(id)sender;
- (IBAction)sevenKeyPress:(id)sender;
- (IBAction)eightKeyPress:(id)sender;
- (IBAction)nineKeyPress:(id)sender;
- (IBAction)zeroKeyPress:(id)sender;
- (IBAction)doneKeyPress:(id)sender;
- (IBAction)backKeyPress:(id)sender;

@end

