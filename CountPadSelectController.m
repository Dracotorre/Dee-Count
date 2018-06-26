//
//  CountPadSelectController.m
//  DCount
//
//  Created by David Shrock on 4/28/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//

#import "CountPadSelectController.h"


@implementation CountPadSelectController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.preferredContentSize = CGSizeMake(266.0f, 320.0f);
        padTotal = 0;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //self.preferredContentSize = CGSizeMake(186.0, 254.0);
    
    [self borderForButton:doneKey];
    [self borderForButton:oneKey];
    [self borderForButton:twoKey];
    [self borderForButton:threeKey];
    [self borderForButton:fourKey];
    [self borderForButton:fiveKey];
    [self borderForButton:sixKey];
    [self borderForButton:sevenKey];
    [self borderForButton:eightKey];
    [self borderForButton:nineKey];
    [self borderForButton:zeroKey];
    
}

- (void)borderForButton:(UIButton *)button
{
    button.layer.borderWidth = 1.0f;
    button.layer.borderColor = doneKey.tintColor.CGColor;
    button.layer.cornerRadius = 8.0f;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    padTotal = 0;
    if (padTotal > 0) [numberField setText:[NSString stringWithFormat:@"%d", padTotal]];
    else [numberField setText:@""];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)oneKeyPress:(id)sender
{
    [self countAction:1];
}
- (IBAction)twoKeyPress:(id)sender
{
    [self countAction:2];
}
- (IBAction)threeKeyPress:(id)sender
{
    [self countAction:3];
}
- (IBAction)fourKeyPress:(id)sender
{
    [self countAction:4];
}
- (IBAction)fiveKeyPress:(id)sender
{
    [self countAction:5];
}
- (IBAction)sixKeyPress:(id)sender
{
    [self countAction:6];
}
- (IBAction)sevenKeyPress:(id)sender
{
    [self countAction:7];
}
- (IBAction)eightKeyPress:(id)sender
{
    [self countAction:8];
}
- (IBAction)nineKeyPress:(id)sender
{
    [self countAction:9];
}
- (IBAction)zeroKeyPress:(id)sender
{
    [self countAction:0];
}
- (IBAction)doneKeyPress:(id)sender
{
    [self.padDoneDelegate countPadResult:padTotal];
}
- (IBAction)backKeyPress:(id)sender
{
    if (padTotal > 0) padTotal = padTotal * 0.1;
    else padTotal = 0;
    [numberField setText:[NSString stringWithFormat:@"%d", padTotal]];
}

- (void)countAction:(int)num
{
    // limit to 4 digits
    if (numberField.text.length < 4) {
        if (padTotal > 0) padTotal = padTotal * 10 + num;
        else padTotal = num;
        [numberField setText:[NSString stringWithFormat:@"%d", padTotal]];
    }
    
    if (numberField.text.length > 3) {
        
        [self.padDoneDelegate countPadResult:padTotal];
    }
}

@end
