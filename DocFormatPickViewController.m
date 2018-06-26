//
//  DocFormatPickViewController.m
//  Dee Count
//
//  Created by David G Shrock on 9/8/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DocFormatPickViewController.h"

@interface DocFormatPickViewController ()

@property (weak, nonatomic) IBOutlet UIButton *dczButton;
@property (weak, nonatomic) IBOutlet UIButton *csvButton;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation DocFormatPickViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.dczButton.layer.borderWidth = 1.0f;
    self.dczButton.layer.borderColor = self.dczButton.titleLabel.textColor.CGColor;
    self.dczButton.layer.cornerRadius = 8.0f;
    
    self.csvButton.layer.borderWidth = 1.0f;
    self.csvButton.layer.borderColor = self.csvButton.titleLabel.textColor.CGColor;
    self.csvButton.layer.cornerRadius = 8.0f;
    
    self.activityIndicator.hidden = YES;
    self.messageTextView.text = NSLocalizedString(@"docFormatPickerMessage", @"Choose DCZ to import into Dee Count for count comparison.");
   
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPick)];
    cancelButton.tintColor = self.dczButton.tintColor;
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    if (self.hidden) {
        [self hideAllAnimated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)hideAllAnimated:(BOOL)animated
{
    self.hidden = YES;
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    self.messageTextView.text = NSLocalizedString(@"Saving...", @"Saving...");
    
    if (animated) {
        
        [UIView animateWithDuration:0.333f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.csvButton.alpha = 0.0f;
                             self.dczButton.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             //[self dismissViewControllerAnimated:YES completion:nil];
                         }];
    }
    else {
        self.csvButton.alpha = 0.0f;
        self.dczButton.alpha = 0.0f;
    }

}

- (void)cancelPick
{
    [self.delegate canceledPicker];
}

- (IBAction)csvButtonAction:(id)sender
{
    [self hideAllAnimated:YES];
    [self.delegate pickedFormatCSV];
}
- (IBAction)dczButtonAction:(id)sender
{
    [self hideAllAnimated:YES];
    [self.delegate pickedFormatDCZ];
}

@end
