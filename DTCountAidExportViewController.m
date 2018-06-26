//
//  DTCountAidExportViewController.m
//  Dee Count
//
//  Created by David G Shrock on 9/18/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DTCountAidExportViewController.h"

@interface DTCountAidExportViewController ()
@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet UILabel *reminderMsgLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelTopConstraint;
@end

@implementation DTCountAidExportViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem.title = NSLocalizedString(@"Export", @"Export");
        UIImage *image = [UIImage imageNamed:@"exportTab.png"];
        self.tabBarItem.image = image;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[UITabBar appearance] setTintColor:self.exportButton.tintColor];
    
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
    CGFloat extrasAlpha = 1.0f;
    if (self.compareCountsExist == NO) {
        extrasAlpha = 0.0f;
    }
    if (traitCollection.verticalSizeClass != UIUserInterfaceSizeClassRegular) {
        titleY = 12.0f;
        extrasAlpha = 0.0f;
    }
    self.titleLabelTopConstraint.constant = titleY;
    self.reminderMsgLabel.alpha = extrasAlpha;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)exportAction:(id)sender
{
    [self.delegate exportCountsAidRequested];
}
@end
