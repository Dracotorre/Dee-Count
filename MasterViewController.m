//
//  MasterViewController.m
//  Dee Count
//
//  Created by David G Shrock on 8/7/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
//  updated from 2010 version 1, RootViewController_iPad
//  - ARC and style and iOS 8 layout
//  - delegate improvements
//  - moved local variables to properties

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "LocationSections.h"
#import "DTCountLocation.h"
#import "DTCountInventory.h"
#import "DTCountLocationCell.h"
#import "AppController.h"
#import "DTCBGOperationsWorker.h"
#import "StartupOperation.h"
#import "ImageCache.h"
#import "DTCountCategoryStore.h"

#import "DTScanCode/DTScanCodeViewController.h"
#import "DTScanCode/DTScanCodeMetaControl.h"


@interface MasterViewController () <ScanBarCodeSelectedActionDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, copy) NSMutableArray *locations;
@property (nonatomic, strong) NSArray *filteredLocations;
@property (nonatomic) BOOL hasTotalCountComparisonLocation;
@property (nonatomic) BOOL isShowingSearch;
@property (nonatomic) BOOL isImporting;
@property (nonatomic) BOOL isVisible;
@property (nonatomic) BOOL isStartingOver;
@property (nonatomic) BOOL isLaunching;
@property (nonatomic) BOOL hasStartedAndPickedLocation;
@property (nonatomic) BOOL saveMyScreenForRelaunch;
@property (nonatomic) int curSrchIdx;
@property (nonatomic) int importHasError;
@property (nonatomic, strong) LocationSections *locSections;
@property (nonatomic, strong) NSURL *launchURL;
@property (nonatomic, strong) UIBarButtonItem *countButton;

@property (nonatomic, weak) DTScanCodeViewController *scanCodeViewController;

@property (nonatomic, strong) DTCBGOperationsWorker *pendingStartOps;

@end

@implementation MasterViewController

@synthesize filteredLocations, locSections;
@synthesize locations;


- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

#pragma mark - Views

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    [self.tableView registerClass:[DTCountLocationCell class] forCellReuseIdentifier:@"DCountLocationCell"];
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.detailViewController.delegate = self;
    
    self.countButton.enabled = NO;
    
    [self.view setAlpha:0.94f];
    if (self.locations) {
        self.locSections = [[LocationSections alloc] initWithLocationsArray:self.locations ignore:self.hasTotalCountComparisonLocation];
    }
    self.isLaunching = YES;
    [self doStartupOpWithURL:self.launchURL isRestarting:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //[self setCountButtonDisplay];
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        self.saveMyScreenForRelaunch = YES;
    }

    self.isVisible = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    self.isVisible = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    /*
    DTCountLocation *detLoc = (DTCountLocation *)self.detailViewController.detailItem;
    if (detLoc) {
        NSInteger index = [self indexForLocation:detLoc];
        if (index >= 0 && index < locations.count) {
            [self.tableView beginUpdates];
            NSIndexPath *indexPath = [self.locSections getIndexPathFromArrayIndex:index];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [self.tableView endUpdates];
        }
    }
     */
    [self.tableView reloadData];

    [self updateTitle];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 - (NSUInteger)supportedInterfaceOrientations
 {
 if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
 return UIInterfaceOrientationMaskPortrait;
 }
 return UIInterfaceOrientationMaskAll;
 } */

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    /* if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
     if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
     return NO;
     }
     }*/
    return YES;
}

- (void)doStartupOpWithURL:(NSURL *)url isRestarting:(BOOL)restarting
{
    
    if (self.pendingStartOps == nil) {
        self.pendingStartOps = [[DTCBGOperationsWorker alloc] init];
    }
    // decide if need startup Op to import or display special
    if (!restarting && [[AppController sharedAppController] oldStoreDataExists]) {
        [self.detailViewController setLayoutMode:UpdateDataLayout];
        
        self.isImporting = YES;
        
        StartupOperation *sOp = [[StartupOperation alloc] initWithDelegate:self];
        sOp.updatingFromOldStore = YES;
        sOp.key = [self pendingLaunchKey];
        [self.pendingStartOps.bgOpInProgress setObject:sOp forKey:sOp.key];
        [self.pendingStartOps.bgOpQueue addOperation:sOp];
    }
    else if (url != nil && [url isFileURL] && ![self.pendingStartOps.bgOpInProgress.allKeys containsObject:[self pendingImportKey]]) {

        self.importHasError = 0;
        [self.detailViewController setLayoutMode:ImportLayout];
        
        self.isImporting = YES;
        
        StartupOperation *sOp = [[StartupOperation alloc] initWithURL:url withDelegate:self];
        sOp.key = [self pendingImportKey];
        [self.pendingStartOps.bgOpInProgress setObject:sOp forKey:[self pendingImportKey]];
        [self.pendingStartOps.bgOpQueue addOperation:sOp];
    }
    else {
        self.isImporting = NO;
        if (!restarting) {
           [self.detailViewController setLayoutMode:LoadingLayout];
        }
        
        StartupOperation *sOp = [[StartupOperation alloc] initWithDelegate:self];
        sOp.key = [self pendingLaunchKey];
        [self.pendingStartOps.bgOpInProgress setObject:sOp forKey:sOp.key];
        [self.pendingStartOps.bgOpQueue addOperation:sOp];
    }
}


- (void)updateTitle
{
    NSLog(@"master update title");
    if (self.detailViewController.isScanCodeAvailable && [AppController sharedAppController].showQRFinder) {
        NSLog(@"set scan code");
            if (self.countButton.tag == 101) {
                [self setCountButtonDisplay];
            }
    }
    else {
            if (self.countButton.tag == 102) {
                [self setCountButtonDisplay];
            }
            else {
                [self updateTitleToCountTotal];
            }
    }
        
    [self setTitle:NSLocalizedString(@"Locations", @"Locations")];

}

- (void)updateTitleToCountTotal
{
    int count = (int)locations.count;
    if (self.hasTotalCountComparisonLocation) count--;
    self.countButton.title = [[AppController sharedAppController] formatNumber:count];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        self.saveMyScreenForRelaunch = NO;
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        DTCountLocation *loc = nil;
        
        if (self.isImporting) {
            loc = (DTCountLocation *)self.detailViewController.detailItem;
            if (!loc || !self.hasStartedAndPickedLocation) {
                NSInteger lastSelectedIndex = [[AppController sharedAppController] loadLastSelectedLocationIndex];
                
                NSInteger maxLocCount = locations.count;
                if ([self hasTotalCountComparisonLocation]) {
                    maxLocCount -= 1;
                }
                if (lastSelectedIndex >= 0 && lastSelectedIndex < maxLocCount) {
                    loc = (DTCountLocation *)[locations objectAtIndex:lastSelectedIndex];
                    self.hasStartedAndPickedLocation = YES;
                }
                else if (locations.count > 0) {
                    loc = (DTCountLocation *)[locations objectAtIndex:0];
                    self.hasStartedAndPickedLocation = YES;
                }
            }
        }
        else {
            int idx = (int)[self.locSections convertIndexPathToArrayIndex:indexPath];
            loc = [locations objectAtIndex:idx];
        }
        
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:loc];
       
        [controller setSecretCountCompareLocationExists:self.hasTotalCountComparisonLocation];
        
        if (self.detailViewController != nil) {
            if (self.importHasError == 0) {
                // pass on existing
                controller.importStartupError = self.detailViewController.importStartupError;
            }
            else {
                controller.importStartupError = self.importHasError;
            }
            
            NSArray *totalItems = self.detailViewController.myTotalItems;
            NSArray *tempTotalItems = self.detailViewController.myTempTotalItems;
            NSArray *shortItems = self.detailViewController.myShortItems;
            
            if (totalItems != nil) {
                [controller setTotalItemsAll:totalItems shortItems:shortItems tempItems:tempTotalItems];
            }
        }
        else {
            NSLog(@"**** master segue: detail view is nil!");
        }
        
        controller.delegate = self;
        if (sender != nil && [sender isKindOfClass:[NSString class]]) {
            NSString *senderString = (NSString *)sender;
            if (self.isImporting) {
                [controller setLayoutMode:ImportLayout];
            }
            else if ([senderString isEqualToString:@"EditLayout"]) {
                if (locations.count == 1) {
                    controller.isFirstLocation = YES;
                }
                [controller setLayoutMode:EditingLayout];
            }
            else {
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    [controller selectItemByLabel:senderString showDetails:YES withScroll:UITableViewScrollPositionTop];
                }
                else {
                    [controller selectItemByLabel:senderString showDetails:NO withScroll:UITableViewScrollPositionTop];
                }
                
            }
        }
        else if (self.isImporting) {
            [controller setLayoutMode:ImportLayout];
        }
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        self.detailViewController = controller;
    }
}

#pragma mark - Table View

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.isImporting) {
        return @"";
    }
    return [locSections sectionTitle:section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [locSections allSectionTitles];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.isImporting) {
        return 1;
    }
    return [self.locSections numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.isImporting) {
        return 1;
    }
    return [self.locSections numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.isImporting) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ImportCell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = NSLocalizedString(@"Import Progress", @"Import Progress");
        return cell;
    }
    DTCountLocation *loc = [self locationForIndexPath:indexPath];
    
    DTCountLocationCell *cell = (DTCountLocationCell *)[tableView dequeueReusableCellWithIdentifier:@"DCountLocationCell"];
    if (!cell) {
        cell = [[DTCountLocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DCountLocationCell"];
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [cell setLocation:loc];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showDetail" sender:nil];
    /* old way
     int idx = (int)[self.locSections convertIndexPathToArrayIndex:indexPath];
     DTCountLocation *loc = [locations objectAtIndex:idx];
     
     self.detailViewController.detailItem = loc;
     */
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        int idx = (int)[self.locSections convertIndexPathToArrayIndex:indexPath];
        DTCountLocation *loc = [locations objectAtIndex:idx];
        NSArray *inventoriesForLocation = [[loc valueForKey:@"inventories"] allObjects];
        for (DTCountInventory *mi in inventoriesForLocation) {
            NSNumber *num = [NSNumber numberWithInt:0];
            [mi setValue:num forKey:@"count"];
        }
        
        if (loc == self.detailViewController.detailItem) {
            [self removeALocationAtIndexPath:indexPath animated:YES];
            [self selectFirstLocation];
        }
        else {
            [self removeALocationAtIndexPath:indexPath animated:YES];
        }
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
    [self updateTitle];
}

#pragma mark -
#pragma mark - StartupOperation Delegate

- (void)importDidFinishWithError
{
    self.importHasError = 1;
}

- (void)importDidFinishWithFileError
{
    self.importHasError = 2;
}

- (void)startupLoadedLocations:(NSArray *)locs
{
    [self updateLocations:locs];
    
    if (self.isImporting) {
        [self hideLocations:YES];
    }

    if (locations.count > 0) {
        [self finishStartupAndLaunch];
    }
    else {
        // check to see if we need to set default
        if ([[AppController sharedAppController] userHasSeenStartupTip] == NO) {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                [[AppController sharedAppController] updateAutoSetItemInputOnLocPick:YES];
            }
        }
    }
}

- (void)startupDidFinishLoadingForProcess:(StartupOperation *)startOp
{
    self.isLaunching = NO;
    NSArray *allItems = startOp.resultItems;
    
    [self.pendingStartOps.bgOpInProgress removeObjectForKey:startOp.key];
    
    if (allItems != nil) {
        [self.detailViewController setTotalItems:allItems];
    }
    if (self.isImporting) {

        self.isImporting = NO;
        [[AppController sharedAppController] cleanTempDirectory];
        
        [self resortLocationsWithTableRelaod:NO];
        
        [self performSelector:@selector(finishStartupAndLaunch) withObject:nil afterDelay:0.2f];
        //[self finishStartupAndLaunch];
        
    }
    if (startOp.updatingFromOldStore) {
        self.isImporting = NO;
        
        NSInteger customCountBy = [[AppController sharedAppController] loadCustomCountValueDeprecated];
        if (customCountBy > 1 && customCountBy < 1000) {
            [[AppController sharedAppController] saveCustomCountValue:customCountBy];
        }
        [[AppController sharedAppController] updateAutoSetItemInputOnLocPick:YES];
        
        self.importHasError = -100;
        [self resortLocationsWithTableRelaod:NO];
        
        [self finishStartupAndLaunch];

    }
    else if (locations.count == 0) {
        [self finishStartupAndLaunch];
    }

    // else already did finishStartup


}

- (void)updateImportProgress:(NSNumber *)progress
{
    [self.detailViewController setProgress:[progress doubleValue]];
}

#pragma mark - LoadData Delegate

- (void)didCancelLoadData
{
    [self.pendingStartOps cancelAll];
}

#pragma mark - DetailLocation Delegate

- (void)createdSecretCompareLocation
{
    //NSLog(@"set secret location YES");
    NSArray *list = [[AppController sharedAppController] loadAllLocations];
    locations = [list mutableCopy];
    [self resortLocationsWithTableRelaod:NO];
    self.hasTotalCountComparisonLocation = YES;
}

- (void)detailLocationSaved
{
    if (self.detailViewController.detailItem == nil) {
        NSLog(@"detail is nil!!!");
    }
    
    BOOL newNameExists = NO;
    
    DTCountLocation *selectedLoc = (DTCountLocation *)self.detailViewController.detailItem;
    NSString *locLabel = [selectedLoc valueForKey:@"label"];
    if ([selectedLoc.oldName isEqualToString:locLabel]) {
        // thumbnail changes elsewhere
        return;
    }
    
    for (DTCountLocation *iLoc in locations) {
        if (iLoc != selectedLoc) {
            NSString *iLab = [iLoc valueForKey:@"label"];
            if (([locLabel compare:iLab options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
                newNameExists = YES;
                break;
            }
        }
    }
    
    BOOL reloadTable = NO;
    
    
    
    int oldIdx = (int)[self indexForLocation:selectedLoc];
    NSIndexPath *indexPath = [locSections getIndexPathFromArrayIndex:oldIdx];

    if (indexPath) {
        
        // * * *
        // do animations at once letting tableView handle correct order
        // must come before data change
        [self.tableView beginUpdates];
        
        // do before resortLocations to detect new section
        NSIndexSet *oldSectionIdx = [self.locSections removeFromLocationTitle:selectedLoc.oldName];
        NSIndexSet *newSectionIdx = [self.locSections insertFromLocationTitle:locLabel];
        
        [self resortLocationsWithTableRelaod:NO];
        int idx = (int)[self indexForLocation:(DTCountLocation *)selectedLoc];
        
        if (idx >= 0) {
            NSIndexPath *newIndexPath = [self.locSections getIndexPathFromArrayIndex:idx];
            if ([selectedLoc.oldName hasPrefix:[locLabel substringToIndex:1]] &&
                newIndexPath.section == indexPath.section && newIndexPath.row == indexPath.row) {
                
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                
            }
            else {
                if (newIndexPath.row >= 0 && indexPath.row >= 0) {
                    
                    if (oldSectionIdx != nil) {
                        [self.tableView deleteSections:oldSectionIdx withRowAnimation:UITableViewRowAnimationRight];
                    }
                    if (newSectionIdx != nil) {
                        [self.tableView insertSections:newSectionIdx withRowAnimation:UITableViewRowAnimationLeft];
                    }
                    
                    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    
                    [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    
                    
                }
                else {
                    NSLog(@" indexpaths not found!");
                    reloadTable = YES;
                }
            }
        }
        else {
            NSLog(@"*** location not found!!");
        }
        
        [self.tableView endUpdates];
        // **
        // *** * * end table
    }
    else {
        NSLog(@"MAster --- old loc not found - reloading table");
        reloadTable = YES;
    }
    
    
    
    if (reloadTable) {
        [self.tableView reloadData];
    }
    
    [self reselectLocation:selectedLoc];
    
    if (newNameExists) {
        [self.detailViewController showLocationNameExistsReminderForLabel:locLabel];
    }
    
}

- (void)detailLocationTitleChanged
{
    
}

- (void)detailLocationThumbnailChanged
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSArray *pathArray = [[NSArray alloc] initWithObjects:indexPath, nil];

    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:pathArray withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (void)selectLocation:(DTCountLocation *)loc withItemName:(NSString *)itemLabel
{
    DTCountLocation *detailLoc = (DTCountLocation *)self.detailViewController.detailItem;
    
    for (int i = 0; i < locations.count; ++i) {
        DTCountLocation *iloc = (DTCountLocation *)[locations objectAtIndex:i];
        if (loc == iloc) {
            if (loc != detailLoc) {
                
                NSIndexPath *indexPath = [locSections getIndexPathFromArrayIndex:i];
                
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                
                //if (self.splitViewController.isCollapsed && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                [self.detailViewController setDetailItem:loc];
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    [self.detailViewController selectItemByLabel:itemLabel showDetails:YES withScroll:UITableViewScrollPositionTop];
                }
                else {
                    [self.detailViewController selectItemByLabel:itemLabel showDetails:NO withScroll:UITableViewScrollPositionTop];
                }
                
                //}
                //else {
                //    [self performSelector:@selector(selectLocationSelected:) withObject:itemLabel afterDelay:0.333];
                // }
            }
            break;
        }
    }
}

- (void)busyUpdating:(BOOL)isBusy
{
    [self hideLocations:isBusy];
}

- (void)deleteMyLocationAndGoToLocationLabel:(NSString *)label
{
    [self removeSelectedLocationAndGoToLabel:label];
}

- (void)reselectMyLocation
{
    DTCountLocation *detailLoc = (DTCountLocation *)self.detailViewController.detailItem;
    
    BOOL found = NO;
    for (int i = 0; i < locations.count; ++i) {
        DTCountLocation *loc = [locations objectAtIndex:i];

        if (loc == detailLoc) {
            found = YES;
                NSIndexPath *indexPath = [locSections getIndexPathFromArrayIndex:i];
                
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            
                [self.detailViewController setDetailItem:loc];
            
            break;
        }
    }
    if (!found) {
        [self selectFirstLocation];
    }
}

- (void)importDataAtURL:(NSURL *)url
{
    [self hideLocations:YES];
    [self.tableView reloadData];

    [self doStartupOpWithURL:url isRestarting:NO];
}

- (void)cancelImport
{
    for (id key in self.pendingStartOps.bgOpInProgress) {
        StartupOperation *sOp = (StartupOperation *)self.pendingStartOps.bgOpInProgress[key];
        [sOp cancelImport];
    }
}

- (void)deleteEverythingAndRestart
{
    self.isStartingOver = YES;
    self.hasStartedAndPickedLocation = NO;
    NSMutableArray *allItems = [self.detailViewController.myTempTotalItems mutableCopy];
    for (int i = 0; i < locations.count; ++i) {
        DTCountLocation *loc = (DTCountLocation *)[locations objectAtIndex:i];
        [self removedItemsWithDeleteLocation:loc forAllItems:allItems];
    }
    locations = nil;
    
    [[DTCountCategoryStore sharedStore] resetAllCategories];
    
    [[AppController sharedAppController] saveContext];

    //[[AppController sharedAppController] deleteStoreFile];   -- not working
    [[AppController sharedAppController] cleanCacheDirectory];
    [[AppController sharedAppController] cleanAllFilesInDocumentsDirectory];
    
    
    [self doStartupOpWithURL:nil isRestarting:YES];
}

- (void)resetSecretLocationCounts
{
    DTCountLocation *lastLoc = (DTCountLocation *)[locations lastObject];
    NSString *label = [lastLoc valueForKey:@"label"];
    if ([label isEqualToString:[[AppController sharedAppController] totalCountsSecretLocationName]]) {

        NSArray *inventories = [[lastLoc valueForKey:@"inventories"] allObjects];
        for (DTCountInventory *inv in inventories) {
            NSNumber *zeroNum = [NSNumber numberWithInteger:0];
            [inv setValue:zeroNum forKey:@"count"];
        }
    }
}

- (void)initCountButtonToNumberStyle
{
    self.countButton = [[UIBarButtonItem alloc] initWithTitle:@"0" style:UIBarButtonItemStylePlain target:self action:nil];
    self.countButton.enabled = false;
    self.countButton.tintColor = [UIColor grayColor];
    self.countButton.tag = 101;
    self.navigationItem.leftBarButtonItem = self.countButton;
}

- (void)initCountButtonToCamStyle
{
    self.countButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"scanQRFindIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(scanTitleCodeAction:)];
    self.countButton.tintColor = [AppController sharedAppController].barButtonColor;
    self.countButton.tag = 102;
    self.navigationItem.leftBarButtonItem = self.countButton;
    
}

- (void)cameraStatusUpdated
{
    NSLog(@"cam status updated %d", self.detailViewController.isCameraAvailable);
    if (self.detailViewController.isCameraAvailable) {
        [self initCountButtonToCamStyle];
    }
    else {
        [self initCountButtonToNumberStyle];
        [self updateTitleToCountTotal];
    }
}


#pragma mark - scanning and  Scan Code Delegate

- (void)scanTitleCodeAction:(id)sender
{
    self.countButton.enabled = NO;
    [self.detailViewController.view endEditing:YES];
    CGFloat delay = 0.18f;
    if ([self.detailViewController closedScannerEnableScanning:NO]) {
        delay = 0.45f;
    }
        
    [self performSelector:@selector(prepareScanCodeController) withObject:nil afterDelay:delay];
}

- (void)prepareScanCodeController
{
    DTScanCodeViewController *scanController = [[DTScanCodeViewController alloc] initWithCodeSupport:DTCodeSupportQROnly];
    scanController.scannedCodeSelectedDelegate = self;
    scanController.sendCodeOnTap = NO;
    scanController.dismissBlock = ^{
        self.scanCodeViewController = nil;
        self.countButton.enabled = YES;
        [self.detailViewController closedScannerEnableScanning:YES];
        [[AppController sharedAppController] setScanCodeMetaControl:nil];
    };
    [[AppController sharedAppController] setScanCodeMetaControl:scanController.scanCodeMetaControl];
        
    [scanController.instructionLabel setText:NSLocalizedString(@"Location QR code to Find", @"Location QR code to Find")];
        
    self.scanCodeViewController = scanController;

    
    self.scanCodeViewController.modalPresentationStyle = UIModalPresentationPopover;
    //self.scanCodeViewController.preferredContentSize = CGSizeMake(440.0, 480.0);
    
    [self presentViewController:self.scanCodeViewController animated:YES completion:nil];
    UIPopoverPresentationController *presentationController = [self.scanCodeViewController popoverPresentationController];
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    //presentationController.sourceRect = rect;
    presentationController.barButtonItem = self.countButton;
    presentationController.sourceView = self.view;
    presentationController.delegate = self;
}

-(void)selectedBarCode:(NSString *)barcodeString
{
    self.countButton.enabled = NO;
    if (barcodeString != nil && barcodeString.length > 0 && barcodeString.length < 32) {
        [self.scanCodeViewController showMatchedForCodeText:barcodeString forSeconds:0.51f];
        
        [self.scanCodeViewController dismissViewControllerAnimated:YES completion:^{
            
            NSString *title = [[AppController sharedAppController] stripBadCharactersFromString:barcodeString];
            if (title.length > 0)
            {
                for (DTCountLocation *loc in locations) {
                    NSString *label = [loc valueForKey:@"label"];
                    if (([label compare:title options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
                        [self selectLocation:loc withCommand:nil];
                        break;
                    }
                }
            }
            [[AppController sharedAppController] setScanCodeMetaControl:nil];
            self.scanCodeViewController = nil;
            [self.detailViewController closedScannerEnableScanning:YES];
            self.countButton.enabled = YES;
        }];
        
    }
}
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    if (self.scanCodeViewController != nil && self.scanCodeViewController == popoverPresentationController.presentedViewController) {
        [[AppController sharedAppController] setScanCodeMetaControl:nil];
        self.scanCodeViewController = nil;
        [self.detailViewController closedScannerEnableScanning:YES];
        self.countButton.enabled = YES;
    }
}

#pragma mark -
#pragma mark - methods

- (void)scanQRDefaultPrefChanged:(BOOL)on
{
    [self setCountButtonDisplay];
}


- (void)setCountButtonDisplay
{
    BOOL scanAvailable = NO;
    
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
        AVAuthorizationStatus camAuth = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (camAuth == AVAuthorizationStatusAuthorized || camAuth == AVAuthorizationStatusNotDetermined) {
            scanAvailable = YES;
        }
    }
    if (scanAvailable && [AppController sharedAppController].showQRFinder) {
        
        [self initCountButtonToCamStyle];
    }
    else {
        [self initCountButtonToNumberStyle];
        [self updateTitleToCountTotal];
    }
    
    self.navigationItem.leftBarButtonItem = self.countButton;
}

- (void)addNewLocationAction
{
    [self addNewLocationAndForceSegue:YES];
}

- (DTCountLocation *)addNewLocationAndForceSegue:(BOOL)forceSegue
{
    DTCountLocation *newLoc = nil;
    if (locations != nil)
    {
        AppController *ac = [AppController sharedAppController];
        NSManagedObjectContext *moc = [ac managedObjectContext];
        newLoc = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:moc];
        //int count = (int)locations.count;
        //if (self.hasTotalCountComparisonLocation)
        //{
        //    count--;
        //    [locations insertObject:newLoc atIndex:count];
        //}
        //else [locations addObject:newLoc];
        
        // * * * begin table update - must go before insertion
        // *
        [self.tableView beginUpdates];
        
        [locations insertObject:newLoc atIndex:0];
        
        //NSString *locName = [NSString stringWithFormat:@"Location %d", count + 1];
        NSString *locName = NSLocalizedString(@"New Location", @"New Location");
        
        // check for dupe names
        int matchCount = 0;
        for (int i = 0; i < locations.count; ++i) {
            if ([[[locations objectAtIndex:i] label] hasPrefix:locName]) {
                matchCount++;
            }
        }
        if (matchCount > 0) {
            locName = [locName stringByAppendingString:[NSString stringWithFormat:@" %d", matchCount + 1]];
        }
        [newLoc setValue:locName forKey:@"label"];
        
        NSIndexSet *adjIdx = [self.locSections insertFromLocationTitle:locName];
        
        [self resortLocationsWithTableRelaod:NO];
        
        
        if (adjIdx != nil) {
            [self.tableView insertSections:adjIdx withRowAnimation:UITableViewRowAnimationLeft];
        }
        
        NSUInteger idx = [self indexForLocation:newLoc];
        NSIndexPath *indexPath = [self.locSections getIndexPathFromArrayIndex:idx];

        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        
        [self.tableView endUpdates];
        // *
        // * * * * end table updates
        
        [self updateTitle];
        
        if (self.isVisible || forceSegue) {

            [self performSelector:@selector(selectLocationForEdit:) withObject:newLoc afterDelay:0.5];
        }
        else {
            [self reselectLocation:newLoc];
            [self.detailViewController setDetailItem:newLoc];
            self.detailViewController.importStartupError = self.importHasError;
            if (locations.count == 1) {
                self.detailViewController.isFirstLocation = YES;
            }
            [self.detailViewController setLayoutMode:EditingLayout];
        }
    }
    else {
        NSLog(@"  !!! locations nil!!");
    }
    
    return newLoc;
}

- (void)finishStartupAndLaunch
{
    if (!self.isImporting) {
        [self hideLocations:NO];
        
        self.detailViewController.secretCountCompareLocationExists = self.hasTotalCountComparisonLocation;
        
        self.countButton.enabled = YES;

        //[self.detailViewController loadDone:self.importHasError];
        self.detailViewController.importStartupError = self.importHasError;
        
        if (locations.count == 0) {
            [self addNewLocationAndForceSegue:!self.isStartingOver];
            self.hasStartedAndPickedLocation = YES;
        }
        else if (self.hasStartedAndPickedLocation && self.detailViewController.detailItem) {
            self.detailViewController.importStartupError = self.importHasError;
            [self.detailViewController setLayoutMode:NormalLayout];
        }
        else {
            self.hasStartedAndPickedLocation = YES;
            
            NSInteger lastSelectedIndex = [[AppController sharedAppController] loadLastSelectedLocationIndex];
        
            NSInteger maxLocCount = locations.count;
            if ([self hasTotalCountComparisonLocation]) {
                maxLocCount -= 1;
            }
            if (lastSelectedIndex >= 0 && lastSelectedIndex < maxLocCount) {
                DTCountLocation *loc = (DTCountLocation *)[locations objectAtIndex:lastSelectedIndex];
                DTCountLocation *detLoc = (DTCountLocation *)self.detailViewController;
                if (loc != detLoc) {
                    NSIndexPath *indexPath = [locSections getIndexPathFromArrayIndex:lastSelectedIndex];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
                    //DTCountLocation *loc = [locations objectAtIndex:0];
                    //if (locDelegate != nil) [locDelegate locationUpdated:loc];
                    [self performSegueWithIdentifier:@"showDetail" sender:nil];
                }
            }
            else {
                if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ||
                    self.traitCollection.verticalSizeClass != UIUserInterfaceSizeClassRegular || self.importHasError != 0)
                {
                    [self selectFirstLocation];
                }
            }

        }

        [self updateTitle];
        self.isStartingOver = NO;
        self.importHasError = 0;
    }
    
}

- (NSUInteger)indexForLocation:(DTCountLocation *)loc
{
    for (int i = 0; i < locations.count; ++i) {
        DTCountLocation *curLoc = [locations objectAtIndex:i];
        if (curLoc == loc) {
            return i;
        }
    }
    return -1;
}

- (DTCountLocation *)locationForIndexPath:(NSIndexPath *)indexPath
{
    int idx = (int)[self.locSections convertIndexPathToArrayIndex:indexPath];
    int limIdx = (int)[locations count];
    if (self.hasTotalCountComparisonLocation) limIdx--;
    
    DTCountLocation *loc = nil;
    if (idx >= 0) {
        if (self.isShowingSearch) {
            loc = [self.filteredLocations objectAtIndex:idx];
        }
        else {
            loc = [locations objectAtIndex:idx];
        }
    }
    return loc;
}

- (NSString *)pendingImportKey
{
    return @"importKey";
}

- (NSString *)pendingLaunchKey
{
    return @"launchKey";
}

- (void)saveStatus
{
    // called by app delegate on close
    // Which screen are we on?  if iPad, always use selected location,
    //  but on iPhone, if on this view then
    
    NSInteger index = 0;

    if (self.saveMyScreenForRelaunch) {
        index = -1;
    }
    else {
        DTCountLocation *loc = (DTCountLocation *)self.detailViewController.detailItem;
        if (loc != nil) {
            index = [self indexForLocation:loc];
        }
        else index = -1;
    }
    [[AppController sharedAppController] saveLastSelectedLocationIndex:index];
}

- (void)setLaunchWithURL:(NSURL *)url
{
    if (locations != nil && locations.count > 0) {
        [self doStartupOpWithURL:url isRestarting:NO];
    }
    else {
        
        self.launchURL = url;
    }
}

- (void)removeSelectedLocationAndGoToLabel:(NSString *)label
{
    BOOL needToReload = NO;
    DTCountLocation *locationToGo;
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath == nil || label) {
        for (int i = 0; i < locations.count; ++i) {
            DTCountLocation *loc = [locations objectAtIndex:i];
            if (loc == self.detailViewController.detailItem) {
                indexPath = [self.locSections getIndexPathFromArrayIndex:i];
                needToReload = YES;
            }
            else if (label) {
                NSString *locLab = [loc valueForKey:@"label"];
                if (([locLab compare:label options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
                    locationToGo = loc;
                    if (indexPath) break;
                }
            }
        }
    }
    [self removeALocationAtIndexPath:indexPath animated:!needToReload];
    
    if (needToReload) [self.tableView reloadData];
    
    [self updateTitle];
    if (locationToGo) {
        [self reselectLocation:locationToGo];
        self.detailViewController.secretCountCompareLocationExists = self.hasTotalCountComparisonLocation;
        [self.detailViewController setDetailItem:locationToGo];
    }
    else {
        [self selectFirstLocation];
    }
}

- (void)removeALocationAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (indexPath) {
        [self.tableView beginUpdates];
        
        int index = (int)[self.locSections convertIndexPathToArrayIndex:indexPath];
        DTCountLocation *loc = [locations objectAtIndex:index];
        NSString *locTitle = [loc valueForKey:@"label"];
        NSMutableArray *allItems = [self.detailViewController.myTotalItems mutableCopy];
        
        BOOL removedItems = [self removedItemsWithDeleteLocation:loc forAllItems:allItems];
        
        [locations removeObjectAtIndex:index];
        
        NSIndexSet *adjIdx = [self.locSections removeFromLocationTitle:locTitle];
        
        UITableViewRowAnimation anim = UITableViewRowAnimationFade;
        if (animated) {
            anim = UITableViewRowAnimationNone;
        }
        if (adjIdx != nil) {
            [self.tableView deleteSections:adjIdx withRowAnimation:anim];
        }
        else {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:anim];
        }
        
        [self.tableView endUpdates];
        
        if (removedItems) {
            [self.detailViewController setTotalItems:allItems];
        }
    }
}

/**
 *  returns updated items  -- sets loc to nil, but does not update Locations
 */
- (BOOL)removedItemsWithDeleteLocation:(DTCountLocation *)loc forAllItems:(NSMutableArray *)allItems
{
    BOOL removedItems = NO;
    AppController *ac = [AppController sharedAppController];
        
    NSManagedObjectContext *moc = [ac managedObjectContext];
    
    NSString *imageKey = [loc valueForKey:@"picuuid"];
    if (imageKey) {
        [[ImageCache sharedImageCache] deleteImageForKey:imageKey];
    }
    NSArray *inventories = [[loc valueForKey:@"inventories"] allObjects];
    
    for (int i = (int)inventories.count - 1; i >= 0; --i) {
        DTCountInventory *mi = (DTCountInventory *)[inventories objectAtIndex:i];
        DTCountItem *itm = (DTCountItem *)[mi valueForKey:@"item"];
        [[itm mutableSetValueForKey:@"inventories"] removeObject:mi];
        [[loc mutableSetValueForKey:@"inventories"] removeObject:mi];
        [moc deleteObject:mi];
        mi = nil;
        
        if ([self.detailViewController safeToDeleteItem:itm]) {
            [allItems removeObject:itm];
            removedItems = YES;
            itm = [[DTCountCategoryStore sharedStore] removeCategoryFromItem:itm];
            [moc deleteObject:itm];
            itm = nil;
        }
    }
    [moc deleteObject:loc];
    
    loc = nil;
    
    return removedItems;
}

/**
 *  also re-inits locSections on reloadTable
 */
- (void)resortLocationsWithTableRelaod:(BOOL)reloadTable
{
    AppController *ac = [AppController sharedAppController];
    // resort

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"label" ascending:YES  selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sds = [NSArray arrayWithObject:sd];
    
    [locations sortUsingDescriptors:sds];
    
    // check if has secret location
    self.hasTotalCountComparisonLocation = NO;
    for (int i = 0; i < locations.count; ++i)
    {
        DTCountLocation *loc = [locations objectAtIndex:i];
        NSString *locName = [loc valueForKey:@"label"];
        if ([locName isEqualToString:[ac totalCountsSecretLocationName]])
        {
            DTCountLocation *secretLoc = [locations objectAtIndex:i];
            [locations removeObjectAtIndex:i];
            [locations addObject:secretLoc];   // put secret at end
            self.hasTotalCountComparisonLocation = YES;
            break;
        }
    }
    if (reloadTable) {
        self.locSections = [[LocationSections alloc] initWithLocationsArray:locations ignore:self.hasTotalCountComparisonLocation];
    }
    
    if (!self.isImporting && reloadTable) {
        //NSLog(@"resortLocations - reload tableView");
        [self.tableView reloadData];
    }
    
}

- (void)reloadLocations
{
    self.isImporting = NO;
    
    NSArray *list = [[AppController sharedAppController] loadAllLocations];
    locations = [list mutableCopy];
    //NSLog(@"RootView reloadLocations- loaded locations: %lu", (unsigned long)locations.count);
    
    if (locations.count == 0)
    {
        [self addNewLocationAndForceSegue:NO];
    }
    [self resortLocationsWithTableRelaod:YES];
    [self updateTitle];
    
}

- (void)reselectLocation:(DTCountLocation *)targetLoc
{
    BOOL found = NO;
    
    for (int i = 0; i < locations.count; ++i) {
        DTCountLocation *loc = [locations objectAtIndex:i];
        if (targetLoc == loc) {
            NSIndexPath *indexPath = [locSections getIndexPathFromArrayIndex:i];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            found = YES;
            
            break;
        }
    }
    if (!found) {
        [self selectFirstLocation];
    }
}

- (void)updateLocations:(NSArray *)locs
{
    locations = [locs mutableCopy];
    [self resortLocationsWithTableRelaod:!self.isImporting];
}

- (void)selectFirstLocation
{
    //NSLog(@"select first locaiton");
    if (locations.count == 0 || (self.hasTotalCountComparisonLocation && locations.count <= 1)) {
        [self addNewLocationAndForceSegue:NO];
    }
    else {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
        if (self.detailViewController.detailItem) {
            DTCountLocation *loc = [locations objectAtIndex:0];
            self.detailViewController.importStartupError = self.importHasError;
            self.detailViewController.secretCountCompareLocationExists = self.hasTotalCountComparisonLocation;
            [self.detailViewController setDetailItem:loc];
        }
        else {
            [self performSegueWithIdentifier:@"showDetail" sender:nil];
        }
    }
}

/**
 *  selects and sets detail; also see reselectLocation
 */
- (void)selectLocation:(DTCountLocation *)targetloc withCommand:(NSString *)command
{
    BOOL found = NO;
    
    for (int i = 0; i < locations.count; ++i) {
        DTCountLocation *loc = [locations objectAtIndex:i];
        if (targetloc == loc) {
            NSIndexPath *indexPath = [locSections getIndexPathFromArrayIndex:i];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            found = YES;
            
            break;
        }
    }
    if (found) {
        [self performSegueWithIdentifier:@"showDetail" sender:command];
    }
    else {
        [self selectFirstLocation];
    }
}
-(void)selectLocationForEdit:(DTCountLocation *)targetLoc
{
    NSString *actionString = @"EditLayout";
    [self selectLocation:targetLoc withCommand:actionString];
}

- (void)selectLocationSelected:(NSString *)itemLabelToPick
{
    [self performSegueWithIdentifier:@"showDetail" sender:itemLabelToPick];
}

- (void)hideLocations:(BOOL)hide
{
    if (hide) {
        self.locSections = nil;
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
        self.navigationItem.rightBarButtonItem = barButton;
        self.navigationItem.leftBarButtonItem = nil;
        
        [activityIndicator startAnimating];
    }
    else
    {
        self.locSections = [[LocationSections alloc] initWithLocationsArray:self.locations ignore:self.hasTotalCountComparisonLocation];

        [self setAddButton];
        [self setCountButtonDisplay];
    }
    [self.tableView reloadData];
}

- (void)removeTotalCountComparisonLocation
{
    if (self.hasTotalCountComparisonLocation)
    {
        AppController *ac = [AppController sharedAppController];
        for (int i = (int)locations.count - 1; i >= 0; --i) {
            DTCountLocation * loc = [locations objectAtIndex:i];
            NSString *locName = [loc valueForKey:@"label"];
            if ([locName isEqualToString:[ac totalCountsSecretLocationName]])
            {
                NSManagedObjectContext *moc = [ac managedObjectContext];
                NSArray *inventories = [[loc valueForKey:@"inventories"] allObjects];
                for (DTCountInventory *mi in inventories) {
                    DTCountItem *itemAtLoc = [mi valueForKey:@"item"];
                    [[itemAtLoc mutableSetValueForKey:@"inventories"] removeObject:mi];
                    [[loc mutableSetValueForKey:@"inventories"] removeObject:mi];
                    [moc deleteObject:mi];
                }
                [moc deleteObject:loc];
                [locations removeObjectAtIndex:i];
                loc = nil;
                self.hasTotalCountComparisonLocation = NO;
                i = -100;
            }
        }
        [ac saveContext];
    }
}

- (void)setAddButton
{
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewLocationAction)];
    [addButton setTintColor:[AppController sharedAppController].barButtonColor];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] != 0)
    {
        if (self.curSrchIdx >= locations.count) self.curSrchIdx = 0;
        DTCountLocation *loc = [locations objectAtIndex:self.curSrchIdx];
        if ([[[loc valueForKey:@"label"] lowercaseString] compare:[searchText lowercaseString]] > 0) {
            self.curSrchIdx = 0;
        }
        for (int i = self.curSrchIdx; i < locations.count; ++i) {
            
            loc = [locations objectAtIndex:i];
            if ([[[loc valueForKey:@"label"] lowercaseString] hasPrefix:[searchText lowercaseString]]) {
                self.curSrchIdx = i;
                NSIndexPath *ip = [NSIndexPath indexPathForRow:self.curSrchIdx inSection:0];
                [[self tableView] selectRowAtIndexPath:ip animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                break;
            }
            
        }
    }
    else self.curSrchIdx = 0;
    /*
     if ([searchText length] > 0)
     {
     NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label CONTAINS[cd] %@", searchText];
     filteredLocations = [locations filteredArrayUsingPredicate:predicate];
     isShowSearch = YES;
     [[self tableView] reloadData];
     
     }
     else isShowSearch = NO;
     */
}

- (void)filterContentForSearchText:(NSString*)searchText
{
    //[filteredLocations removeAllObjects];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label CONTAINS[cd] %@", searchText];
    self.filteredLocations = [locations filteredArrayUsingPredicate:predicate];
    
}


@end
