//
//  DTCountAidViewController.m
//  Dee Count
//
//  Created by David G Shrock on 9/18/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DTCountAidResetViewController.h"

@interface DTCountAidResetViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionNowImageButton;
@property (weak, nonatomic) IBOutlet UILabel *replaceLabel;

@property (weak, nonatomic) IBOutlet UISwitch *replaceInventorySwitch;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelTopConstraint;
@end

@implementation DTCountAidResetViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem.title = NSLocalizedString(@"Reset Counts", @"Reset Counts");
        UIImage *image = [UIImage imageNamed:@"restartCountsTab.png"];
        self.tabBarItem.image = image;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[UITabBar appearance] setTintColor:self.actionNowImageButton.tintColor];
    self.replaceInventorySwitch.on = NO;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self compactLayoutAnimated:NO forTraitCollection:self.traitCollection];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self compactLayoutAnimated:YES forTraitCollection:newCollection];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {

    }];
}

- (void)compactLayoutAnimated:(BOOL)animated forTraitCollection:(UITraitCollection *)traitCollection
{
    CGFloat titleY = 32.0f;
    CGFloat extrasAlpha = 0.0f;
    if (traitCollection.verticalSizeClass != UIUserInterfaceSizeClassRegular) {
        titleY = 12.0f;
        extrasAlpha = 0.0f;
    }
    else if (self.compareCountsExists) {
        extrasAlpha = 1.0f;
    }
    self.titleLabelTopConstraint.constant = titleY;
    
    self.replaceInventorySwitch.alpha = extrasAlpha;
    self.replaceLabel.alpha = extrasAlpha;
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)resetNowAction:(id)sender
{
    UIAlertController __weak *weakAlert = nil;   // new in iOS 8, replaces UIAlertView and sheet
    
    UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ResetCountsTitle", @"Reset Counts")
                                                                        message:NSLocalizedString(@"ResetCountsMsg", @"Are you sure you want to reset all counts to zero?")
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    weakAlert = alertSheet;
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
        [weakAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.delegate resetCountsNowReplacingCompare:self.replaceInventorySwitch.on];
        [weakAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alertSheet addAction:cancelAction];
    [alertSheet addAction:confirmAction];
    
    [self presentViewController:alertSheet animated:YES completion:nil];
}

@end
