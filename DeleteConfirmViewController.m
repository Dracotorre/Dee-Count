//
//  DeleteLocationConfirmViewController.m
//  Dee Count
//
//  Created by David G Shrock on 8/31/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DeleteConfirmViewController.h"

@interface DeleteConfirmViewController ()
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation DeleteConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelMe:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.messageTextView.text = self.message;
    self.deleteButton.titleLabel.text = NSLocalizedString(@"Delete", @"Delete");
}

- (void)viewDidLayoutSubviews
{
    // prevent navbar from covering our sub-views
    self.navigationController.navigationBar.translucent = NO;
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
- (IBAction)deleteButtonTouchAction:(id)sender
{
    [self.delegate deletionConfirmed:YES forKey:self.deleteKey];
}

-(void)cancelMe:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:self.dismissBlock];
}

@end
