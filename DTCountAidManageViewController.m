//
//  DTCountAidManageViewController.m
//  Dee Count
//
//  Created by David G Shrock on 9/18/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DTCountAidManageViewController.h"
#import "DTCountAidExportViewController.h"
#import "DTCountAidImportViewController.h"
#import "DTCountAidResetViewController.h"
#import "AppController.h"

@interface DTCountAidManageViewController () <AidResetViewDelegate, AidExportViewDelegate, AidImportViewDelegate> {
    
}

@end

@implementation DTCountAidManageViewController


- (instancetype)initForCompareCountsExists:(BOOL)compareExists
{
    self = [super init];
    if (self) {
        
        self.preferredContentSize = CGSizeMake(400.0f, 512.0f);
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelMe:)];
        cancelButton.tintColor = [[AppController sharedAppController] barButtonColor];
        self.navigationItem.leftBarButtonItem = cancelButton;
        
        self.navigationItem.title = NSLocalizedString(@"Compare Counts", @"Compare Counts");
        
        NSBundle *appBundle = [NSBundle mainBundle];
        
        DTCountAidResetViewController *resetController = [[DTCountAidResetViewController alloc] initWithNibName:@"DTCountAidResetViewController" bundle:appBundle];
        resetController.delegate = self;
        resetController.compareCountsExists = compareExists;
        DTCountAidExportViewController *exportController = [[DTCountAidExportViewController alloc] initWithNibName:@"DTCountAidExportViewController" bundle:appBundle];
        exportController.delegate = self;
        exportController.compareCountsExist = compareExists;
        DTCountAidImportViewController *importController = [[DTCountAidImportViewController alloc] initWithNibName:@"DTCountAidImportViewController" bundle:appBundle];
        importController.delegate = self;
        self.viewControllers = @[resetController, exportController, importController];
        
    }
    return self;
}

- (instancetype)init
{
    return [self initForCompareCountsExists:NO];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (void)cancelMe:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:self.dismissBlock];
}

#pragma mark - delegates


- (void)resetCountsNowReplacingCompare:(BOOL)replace
{
    [self.countAidDelegate resetCountsNowReplacingCompare:replace];
}

- (void)exportCountsAidRequested
{
    [self.countAidDelegate  exportAidRequest];
}

- (void)importCountsAidRequested
{
    [self.countAidDelegate  importAidRequestIsGuided:NO];
}

- (void)importCountsGuidedRequested
{
    [self.countAidDelegate  importAidRequestIsGuided:YES];
}

@end

