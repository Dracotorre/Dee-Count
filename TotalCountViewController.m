    //
//  TotalCountViewController_iPad.m
//  DCount
//
//  Created by David Shrock on 1/9/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//

#import "TotalCountViewController.h"
#import "DTCountItem.h"
#import "DTCountLocation.h"
#import "DTCountInventory.h"
#import "AppController.h"
#import "ItemCell.h"
#import "DTCountCategory.h"
#import "DTCountCategoryStore.h"
#import "DTCountTotalsPack.h"

@interface TotalCountViewController () {

    // to help limit recounts - save big ones we've seen
    DTCountTotalsPack *pItemsLongPack;
    DTCountTotalsPack *pItemsShortPack;
    DTCountTotalsPack *pUncatLongPack;
    DTCountTotalsPack *pUncatShortPack;
    
    ItemDetailViewController *detailViewController;
    int curSrchIdx;
    BOOL showLongList;
    BOOL hasTotalCountLocation;
    int limitDisplayToCategoryAtIndex;
    int categoryCount;
    
    CGFloat tableShiftX;
    BOOL showSwitchStartedOn;
    BOOL tablesSliding;
}

@property (nonatomic, weak) IBOutlet UITableView *itemsTable;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISwitch *showZeroSwitch;
@property (weak, nonatomic) IBOutlet UILabel *showZeroLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalsLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalValueLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *totalsLabelBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *switchBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *itemTableRightSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *itemTableLeftSpaceConstraint;

@property (strong, nonatomic) IBOutlet UITableView *catsTable;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *catTableLeftSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *catTableRightSpaceConstraint;
@property (strong, nonatomic) IBOutlet UISegmentedControl *displayTypeSegmentedControl;

@end

@implementation TotalCountViewController

@synthesize curSrchIdx;

NSDictionary *cellHeightDictionary;

#pragma mark -
#pragma mark Initialization


- (id)init
{
	self = [super init];
    if (self) {
        detailViewController = [[ItemDetailViewController alloc] init];
        [detailViewController setLocSelectDelegate:self];
        [detailViewController setUpdateDelegate:self];
        
        [self.navigationItem setTitle:NSLocalizedString(@"Total Counts", @"Total Counts")];
        
        self.preferredContentSize = CGSizeMake(396.0, 600.0);
        
        limitDisplayToCategoryAtIndex = -1;
        tableShiftX = -300.0f;
    }
	
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    
	return [self init];
}

#pragma mark - custom get/set

- (void)setItemsLongList:(NSArray *)itemsLongList
{
    pItemsLongPack = [[DTCountTotalsPack alloc] init];
    pItemsLongPack.itemList = itemsLongList;
    
    [self clearUncategoryTotals];
}

- (void)setItemsShortList:(NSArray *)itemsShortList
{
    pItemsShortPack = [[DTCountTotalsPack alloc] init];
    pItemsShortPack.itemList = itemsShortList;

    [self clearUncategoryTotals];
}

- (NSArray *)itemsLongList
{
    return pItemsLongPack.itemList;
}

- (NSArray *)itemsShortList
{
    return pItemsShortPack.itemList;
}


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.catsTable = [[UITableView alloc] initWithFrame:[self frameForCatsTableFromItemsFrame:self.itemsTable.frame] style:UITableViewStylePlain];
    self.catsTable.delegate = self;
    self.catsTable.dataSource = self;
    self.catsTable.alpha = 0.0f;
    //self.catsTable.translatesAutoresizingMaskIntoConstraints = NO;
    //[self.view addSubview:self.catsTable]
	
    //if (self.navigationController.popoverPresentationController == nil || self.navigationController.popoverPresentationController.presentationStyle == UIModalPresentationFullScreen) {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];

    //}
    [self.itemsTable registerClass:[ItemCell class] forCellReuseIdentifier:@"ItemCell"];
    [self.catsTable registerClass:[ItemCell class] forCellReuseIdentifier:@"ItemCellCat"];
    
    [self.showZeroLabel setText:NSLocalizedString(@"Show zero-count items", @"Show zero-count items")];
    [self.showZeroSwitch setOn:[AppController sharedAppController].showZeroCounts];
    showSwitchStartedOn = self.showZeroSwitch.on;
    
    [self.displayTypeSegmentedControl setTitle:NSLocalizedString(@"Items", @"Items") forSegmentAtIndex:0];
    [self.displayTypeSegmentedControl setTitle:NSLocalizedString(@"Categories", @"Categories") forSegmentAtIndex:1];
    
    showLongList = self.showZeroSwitch.on;
    
    self.totalValueLabel.text = @"";
    
    CALayer *layer = self.itemsTable.layer;
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:12.0f];
    
    CALayer *catLayer = self.catsTable.layer;
    [catLayer setMasksToBounds:YES];
    [catLayer setCornerRadius:12.0f];
    
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeRecognizer];
    
    UISwipeGestureRecognizer *swipeRightRec = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeRightRec.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRightRec];
    
    UISwipeGestureRecognizer *swipeLeftRec = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeLeftRec.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeftRec];
    
}

- (void)viewDidLayoutSubviews
{
    // prevent navbar from covering our sub-views
    self.navigationController.navigationBar.translucent = NO;
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	// if coming from sub-view, don't reload
    
    self.totalValueLabel.alpha = 0.0f;
    self.totalsLabel.text = @"";
    
    [self updateFonts];
    [self clearUncategoryTotals];
    
    [self updateDisplayForSelectedView];
    [self updateLayoutForTraitCollection:self.traitCollection animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.catsTable.frame = CGRectMake(400.0f, self.itemsTable.frame.origin.y, self.itemsTable.frame.size.width, self.itemsTable.frame.size.height);
}

- (void)viewWillDisappear:(BOOL)animated {
	
    [super viewWillDisappear:animated];
    
    if (self.showZeroSwitch.on != showSwitchStartedOn) {
        [[AppController sharedAppController] updateShowZeroToUserDefaultsForEnabled:self.showZeroSwitch.on];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.catsTable.frame = [self frameForCatsTableFromItemsFrame:self.itemsTable.frame];
        
    }];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateLayoutForTraitCollection:newCollection animated:YES];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}


- (void)updateFonts
{
            if (!cellHeightDictionary) {
                cellHeightDictionary = @{UIContentSizeCategoryExtraSmall : @40,
                                         UIContentSizeCategorySmall : @42,
                                         UIContentSizeCategoryMedium : @44,
                                         UIContentSizeCategoryLarge : @50,
                                         UIContentSizeCategoryExtraLarge : @56,
                                         UIContentSizeCategoryExtraExtraLarge : @60,
                                         UIContentSizeCategoryExtraExtraExtraLarge : @72,
                                         UIContentSizeCategoryAccessibilityMedium: @72,
                                         UIContentSizeCategoryAccessibilityLarge: @72,
                                         UIContentSizeCategoryAccessibilityExtraLarge: @78,
                                         UIContentSizeCategoryAccessibilityExtraExtraLarge: @80,
                                         UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @82 };
        }
        NSString *userSize = [[UIApplication sharedApplication] preferredContentSizeCategory];
        NSNumber *cellHeight = cellHeightDictionary[userSize];
        [self.itemsTable setRowHeight:cellHeight.floatValue];
        [self.itemsTable reloadData];

}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    //return [tableContent numberOfSections];  
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    if (/*self.displayTypeSegmentedControl.selectedSegmentIndex == 0*/ tableView == self.itemsTable) {
        if (limitDisplayToCategoryAtIndex >= 0) {
            NSArray *items = [self itemsInCategoryAtIndex:limitDisplayToCategoryAtIndex];

            return items.count;
        }
        else if (showLongList) {
            return pItemsLongPack.itemList.count;
        }
        return pItemsShortPack.itemList.count;
    }
    NSInteger cnt = [[DTCountCategoryStore sharedStore] allCategories].count;
    return cnt + 1;  // for uncategorized
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellID = @"ItemCell";
    if (tableView == self.catsTable) {
        cellID = @"ItemCellCat";
    }
    NSArray* items = nil;
    if (limitDisplayToCategoryAtIndex >= 0) {
        
        items = [self itemsInCategoryAtIndex:limitDisplayToCategoryAtIndex];
    }
    else {
        items = pItemsShortPack.itemList;
        if (showLongList) {
            items = pItemsLongPack.itemList;
        }
    }
    
	ItemCell *cell = (ItemCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
		cell = [[ItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        
        
	}
    if (tableView == self.itemsTable) {
        cell.isTotalType = YES;
        
        if ([indexPath row] >= items.count) {
            return cell;
        }
        
        DTCountItem *itm = [items objectAtIndex:[indexPath row]];
        AppController *ac = [AppController sharedAppController];

        NSInteger cnt = 0;
        NSInteger totalCnt = -1;
        NSArray *inventoriesForItem = [[itm valueForKey:@"inventories"] allObjects];
        for (DTCountInventory *mi in inventoriesForItem)
        {
            DTCountLocation *loc = [mi valueForKey:@"location"];
            if (loc) {
                NSString *locName = [loc valueForKey:@"label"];
                if (![locName isEqualToString:[ac totalCountsSecretLocationName]]) cnt += [[mi valueForKey:@"count"] intValue];
                else totalCnt = [[mi valueForKey:@"count"] intValue];
            }
        }
        [cell setItem:itm setCount:cnt setTotalCount:totalCnt];
    }
    else {
        NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];
        
        BOOL checked = (limitDisplayToCategoryAtIndex == indexPath.row);
        NSUInteger uncatCount;
        if (showLongList){
            uncatCount = pUncatLongPack.itemList.count;
        }
        else {
            uncatCount = pUncatShortPack.itemList.count;
        }
        
        if (indexPath.row >= allCats.count) {
            [cell setUniversalLabel:NSLocalizedString(@"Uncategorized", @"Uncategorized")
                          withCount:uncatCount
                     withTotalCount:-1 withDescription:@""
                          isChecked:checked];
        }
        else {
            [cell setCategoryItem:[allCats objectAtIndex:indexPath.row]
                        isChecked:checked];
        }
        
    }
    
    return cell;
}

/*
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
 {
 return [tableContent headers];
 
 }
 */

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    if (tablesSliding) {
        return;
    }
	[self.searchBar setText:@""];
    [self.searchBar resignFirstResponder];
    
    if (tableView == self.itemsTable) {
        curSrchIdx = (int)[indexPath row];
        if (limitDisplayToCategoryAtIndex >= 0) {
            NSArray *items = [self itemsInCategoryAtIndex:limitDisplayToCategoryAtIndex];
            [detailViewController setItem:[items objectAtIndex:curSrchIdx]];
        }
        else if (showLongList) {
            [detailViewController setItem:[pItemsLongPack.itemList objectAtIndex:curSrchIdx]];
        }
        else {
            [detailViewController setItem:[pItemsShortPack.itemList objectAtIndex:curSrchIdx]];
        }
        
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
    else {
        if (limitDisplayToCategoryAtIndex == indexPath.row) {
            limitDisplayToCategoryAtIndex = -1;
        }
        else {
            limitDisplayToCategoryAtIndex = (int)indexPath.row;
        }
        [self.displayTypeSegmentedControl setSelectedSegmentIndex:0];
        //[self animateTableViewDisplay];
        [self animateTableViewSlide];
    }
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (tablesSliding) {
        return;
    }
    if (action == @selector(copy:)) {
        NSString *label = @"";
        
        if (tableView == self.itemsTable) {
            curSrchIdx = (int)[indexPath row];
            if (limitDisplayToCategoryAtIndex >= 0) {
                NSArray *items = [self itemsInCategoryAtIndex:limitDisplayToCategoryAtIndex];
                DTCountItem *item = [items objectAtIndex:curSrchIdx];
                label = [item valueForKey:@"label"];
            }
            else if (showLongList) {
                DTCountItem *item = [pItemsLongPack.itemList objectAtIndex:curSrchIdx];
                label = [item valueForKey:@"label"];
            }
            else {
                DTCountItem *item = [pItemsShortPack.itemList objectAtIndex:curSrchIdx];
                label = [item valueForKey:@"label"];
            }
        }
        else {
            // not actually supporting this at this time
            NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];
            DTCountCategory *cat = [allCats objectAtIndex:indexPath.row];
            label = [cat valueForKey:@"label"];
        }
        
        UIPasteboard *gpBoard = [UIPasteboard generalPasteboard];
        [gpBoard setValue:label forPasteboardType:@"public.utf8-plain-text"];
    }
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (tablesSliding) {
        return NO;
    }
    if (tableView == self.itemsTable) {
        return (action == @selector(copy:));
    }
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.itemsTable) {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark searchbar

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    
    NSArray *items = pItemsShortPack.itemList;
    
    if (self.displayTypeSegmentedControl.selectedSegmentIndex == 1) {
        items = [[DTCountCategoryStore sharedStore] allCategories];
    }
    else if (limitDisplayToCategoryAtIndex >= 0) {
        items = [self itemsInCategoryAtIndex:limitDisplayToCategoryAtIndex];
    }
    else if (showLongList) {
        items = pItemsLongPack.itemList;
    }
	if ([searchText length] != 0)
	{
		if (curSrchIdx >= items.count) curSrchIdx = 0;
        if (items.count > curSrchIdx)
        {
            NSString *label = nil;
            if (self.displayTypeSegmentedControl.selectedSegmentIndex == 0) {
                DTCountItem *itm = (DTCountItem *)[items objectAtIndex:curSrchIdx];
                label = [itm valueForKey:@"label"];
            }
            else {
                DTCountCategory *cat = (DTCountCategory *)[items objectAtIndex:curSrchIdx];
                label = [cat valueForKey:@"label"];
            }
            
            if ([[label lowercaseString] compare:[searchText lowercaseString]] > 0) {
                curSrchIdx = 0;
            }
            for (int i = curSrchIdx; i < items.count; ++i) {
                if (self.displayTypeSegmentedControl.selectedSegmentIndex == 0) {
                    DTCountItem *itm = (DTCountItem *)[items objectAtIndex:i];
                    label = [itm valueForKey:@"label"];
                }
                else {
                    DTCountCategory *cat = (DTCountCategory *)[items objectAtIndex:i];
                    label = [cat valueForKey:@"label"];
                }
                
                if ([[label lowercaseString] hasPrefix:[searchText lowercaseString]]) {
                    curSrchIdx = i;
                    NSIndexPath *ip = [NSIndexPath indexPathForRow:curSrchIdx inSection:0];
                    if (self.displayTypeSegmentedControl.selectedSegmentIndex == 0) {
                       [self.itemsTable selectRowAtIndexPath:ip animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                    }
                    else {
                        [self.catsTable selectRowAtIndexPath:ip animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                    }
                    break;
                }
                
            }   
        }
	}
	else curSrchIdx = 0;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}


- (void)dealloc {
    // not using
    //NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    //[defaultCenter removeObserver:self];
    
}


#pragma mark - DataDoc Delegate


- (void)dataDocSendMailWithFileURL:(NSURL *)exportedFileUrl forFileName:(NSString *)fileName
{
    [self.dataDocDelegate dataDocSendMailWithFileURL:exportedFileUrl forFileName:fileName];
}

- (void)dataDocumentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker forImport:(BOOL)isImport
{
    // this appears to get in the way of next animation
    //[self.navigationController dismissViewControllerAnimated:YES completion:^{
    [self.dataDocDelegate dataDocumentMenu:documentMenu didPickDocumentPicker:documentPicker forImport:isImport];
    //}];
}

- (void)dataDocShareQRCodeImage:(UIImage *)qrImage atFileURL:(NSURL *)exportedFileUrl
{
    [self.dataDocDelegate dataDocShareQRCodeImage:qrImage atFileURL:exportedFileUrl];
}

- (void)dataDocOpenInWithURL:(NSURL *)exportedFileUrl
{
    [self.dataDocDelegate dataDocOpenInWithURL:exportedFileUrl];
}

- (void)printRequestForOutputText:(NSString *)text
{
    [self.dataDocDelegate printRequestForOutputText:text];

}

#pragma mark - loc select delegate

- (void) selectedLocation:(DTCountLocation *)loc selectedItemLabel:(NSString *)label
{
    [self.locSelectDelegate selectedLocation:loc selectedItemLabel:label];
}

#pragma mark - itemDetail updated delegate

- (void)itemDetailValueUpdated
{
    [self clearTotalPacks];
}

#pragma mark - other

- (void)actionButtonSelected:(UIBarButtonItem *)sender
{
    DataDocViewController *exportViewController = [[DataDocViewController alloc] init];

    exportViewController.exportFileName = NSLocalizedString(@"dCount_totals", @"dCount_totals");
    exportViewController.delegate = self;
    
    if (limitDisplayToCategoryAtIndex >= 0) {
        NSArray *itemsToExport;
        if (showLongList) {
            itemsToExport = [pUncatLongPack.itemList copy];
        }
        else {
            itemsToExport =[pUncatShortPack.itemList copy];
        }
        NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];
        if (limitDisplayToCategoryAtIndex >= allCats.count) {
            exportViewController.itemsToExport = itemsToExport;
            exportViewController.categoryTitle = self.showZeroLabel.text;
            exportViewController.exportFileName = [exportViewController.exportFileName stringByAppendingString:[NSString stringWithFormat:@"-%@", NSLocalizedString(@"Uncategorized", @"Uncategorized")]];
        }
        else {
            DTCountCategory *cat = [allCats objectAtIndex:limitDisplayToCategoryAtIndex];
            NSSet *items = [cat valueForKey:@"items"];
            exportViewController.itemsToExport = [items allObjects];
            exportViewController.categoryTitle = self.showZeroLabel.text;
            exportViewController.exportFileName = [exportViewController.exportFileName stringByAppendingString:[NSString stringWithFormat:@"-%@", [cat valueForKey:@"label"]]];
        }
    }
    else if (showLongList) {
        exportViewController.itemsToExport = self.itemsLongList;
    }
    else {
        exportViewController.itemsToExport = self.itemsShortList;
    }
    exportViewController.includeImport = YES;
    exportViewController.needsDoneButton = NO;
    exportViewController.includeEmailExport = self.emailExportSupported;
    exportViewController.showMismatchSwitch = hasTotalCountLocation;
    exportViewController.dismissBlock = ^{
        [self done:nil];
    };
    exportViewController.navigationItem.title = NSLocalizedString(@"Export/Import Totals", @"Export/Import Totals");
    exportViewController.headerText = NSLocalizedString(@"Totals", @"Totals");
    exportViewController.preferredContentSize = self.preferredContentSize;
    [self.navigationController pushViewController:exportViewController animated:YES];
}

- (NSArray *)itemsInCategoryAtIndex:(int)index
{
    NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];

    if (index >= (int)allCats.count) {
        if (showLongList) {
            return pUncatLongPack.itemList;
        }
        return pUncatShortPack.itemList;
    }

    DTCountCategory *cat = [allCats objectAtIndex:index];
    NSSet *catSet = [cat valueForKey:@"items"];
    NSMutableArray *items = [NSMutableArray arrayWithArray:[catSet allObjects]];
    
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"label" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [items sortUsingDescriptors:@[sd]];
    return [items copy];
    
}

- (void)clearUncategoryTotals
{
    pUncatShortPack = nil;
    pUncatLongPack = nil;
}

- (void)clearTotalPacks
{
    pItemsShortPack.totalCount = 0;
    pItemsShortPack.totalInventory = 0;
    pItemsShortPack.totalValue = 0.0f;
    pItemsLongPack.totalCount = 0;
    pItemsLongPack.totalInventory = 0;
    pItemsLongPack.totalValue = 0.0f;
}

- (IBAction)showZeroSwitchChanged:(UISwitch *)sender
{
    [self.searchBar resignFirstResponder];
    [[AppController sharedAppController] updateShowZeroToUserDefaultsForEnabled:sender.on];

    //[self.showZeroSwitch setEnabled:NO];
    // wait for close to update settings preference
    self.curSrchIdx = -1;
    
    [self animateTableUpdateForItemsChangeShowLongList:self.showZeroSwitch.on];
    
}
- (IBAction)displayTypeSegmentValueChanged:(id)sender
{
    self.searchBar.text = @"";
    if (self.displayTypeSegmentedControl.selectedSegmentIndex == 0) {
        self.searchBar.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }
    else {
        self.searchBar.keyboardType = UIKeyboardTypeDefault;
    }
    //[self animateTableViewDisplay];
    [self animateTableViewSlide];
}

- (void)done:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:self.dismissBlock];
}

/**
 *
 */
- (void)animateTableViewSlide
{
    tablesSliding = YES;
    CGFloat shiftVal = 0.0f;
    CGFloat catShiftVal = -tableShiftX;
    CGFloat itemsAlpha = 1.0f;
    CGFloat catsAlpha = 0.0f;
    
    if (self.displayTypeSegmentedControl.selectedSegmentIndex == 1) {
        itemsAlpha = 0.0f;
        catsAlpha = 1.0f;
        shiftVal = tableShiftX;
        catShiftVal = 0.0f;

        [self.catsTable reloadData];
    }
    else {
        [self.itemsTable reloadData];
        
    }
    CGRect itemsFrame = CGRectMake(shiftVal,
                                   self.itemsTable.frame.origin.y,
                                   self.itemsTable.frame.size.width,
                                   self.itemsTable.frame.size.height);
    CGRect catsFrame = [self frameForCatsTableFromItemsFrame:itemsFrame];
    
    [UIView animateWithDuration:0.20f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.totalsLabel.alpha = 0.1f;
                         self.showZeroSwitch.alpha = 0.0f;
                         self.showZeroLabel.alpha = 0.0f;
                         self.totalValueLabel.alpha = 0.0f;
                         
                     }
                     completion:^(BOOL finished) {
                         [self updateDisplayForSelectedView];

                         [UIView animateWithDuration:0.3333f
                                               delay:0.1f
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              
                                              self.itemsTable.alpha = itemsAlpha;
                                              self.catsTable.alpha = catsAlpha;
                                              if (catsAlpha > 0.1f) {
                                                  self.totalsLabel.alpha = catsAlpha;
                                              }
                                              //if (totalValue > 0.0f && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
                                              //    self.totalValueLabel.alpha = 1.0f;
                                             // }
                                              self.itemsTable.frame = itemsFrame;
                                              self.itemTableLeftSpaceConstraint.constant = shiftVal;
                                              if (shiftVal == 0) {
                                                  self.itemTableRightSpaceConstraint.constant = 0.0f;
                                              }
                                              else self.itemTableRightSpaceConstraint.constant = -1 * shiftVal;
                                              
                                              self.catTableLeftSpaceConstraint.constant = catShiftVal;
                                              if (catShiftVal == 0.0f) {
                                                  self.catTableRightSpaceConstraint.constant = 0.0f;
                                              }
                                              else self.catTableRightSpaceConstraint.constant = -catShiftVal;
                                              
                                              self.catsTable.frame = catsFrame;
                                          }
                                          completion:^(BOOL finished){
                                              tablesSliding = NO;

                                          }];
                     }];
    
}

- (void)animateTableBounceInDirection:(UISwipeGestureRecognizerDirection)direction
{
    CGRect tableFrame = self.itemsTable.frame;
    
    CGFloat offset = -48.0 + tableShiftX;
    CGFloat resetX = tableShiftX;
    if (direction == UISwipeGestureRecognizerDirectionRight) {
        offset = 48.0f;
        resetX = 0.0f;
    }
    
    CGRect targetFrame = CGRectMake(offset, tableFrame.origin.y, tableFrame.size.width, tableFrame.size.height);
    CGRect targetResetFrame = CGRectMake(resetX, tableFrame.origin.y, tableFrame.size.width, tableFrame.size.height);

    [UIView animateWithDuration:0.21f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.itemsTable.frame = targetFrame;
                         self.catsTable.frame = [self frameForCatsTableFromItemsFrame:targetFrame];
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.12f
                                               delay:0.0667f
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.itemsTable.frame = tableFrame;
                                              self.catsTable.frame = [self frameForCatsTableFromItemsFrame:targetResetFrame];
                                          }
                                          completion:nil];
                     }];
    
}

- (void)updateSwitchAlphasForViewAndTraitCollection:(UITraitCollection *)traitCollection
{
    CGFloat switchAlpha = 1.0f;
    CGFloat switchLabelAlpha = 1.0f;
    
    if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        switchAlpha = 0.0f;
        switchLabelAlpha = 0.0f;
    }
    else {
        if (self.displayTypeSegmentedControl.selectedSegmentIndex == 0) {
            if (limitDisplayToCategoryAtIndex >= 0) {
                switchAlpha = 0.0f;
            }
            else if (self.itemsShortList == nil ||
                     self.itemsLongList.count == self.itemsShortList.count) {
                switchLabelAlpha = 0.0f;
                switchAlpha = 0.0f;
            }
        }
        else {
            switchAlpha = 0.0f;
        }
    }
    self.showZeroSwitch.alpha = switchAlpha;
    self.showZeroLabel.alpha = switchLabelAlpha;
}

/**
 *  also calls updateSwitchAlpha ...
 */
- (void)updateLayoutForTraitCollection:(UITraitCollection *)traitCollection animated:(BOOL)animated
{
    CGFloat totalValueAlpha = 0.0f;
    if (self.totalValueLabel.text.length > 0) {
        totalValueAlpha = 1.0f;
    }
    CGFloat itemsTableTopConstraint = 8.0f;
    CGFloat totalLabelBottomConstraint = 8.0f;
    CGRect totalsFrame = CGRectMake(self.totalsLabel.frame.origin.x,
                                    self.totalValueLabel.frame.origin.y - 8.0f - self.totalsLabel.frame.size.height,
                                    self.totalsLabel.frame.size.width,
                                    self.totalsLabel.frame.size.height);
    CGRect itemsTableFrame = CGRectMake(0.0f,
                                        88.0f,
                                        self.itemsTable.frame.size.width,
                                        totalsFrame.origin.y - 8.0f - 88.0f);
    if (self.displayTypeSegmentedControl.selectedSegmentIndex == 1) {
        itemsTableFrame = CGRectMake(tableShiftX,
                                     88.0f,
                                     self.itemsTable.frame.size.width,
                                     self.itemsTable.frame.size.height);
    }
    
    
    if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        // hide the top label and total value, stretch table
        
        totalLabelBottomConstraint = 8.0f - self.totalsLabel.frame.size.height;
        itemsTableTopConstraint = -31.0f;
        
        totalsFrame = CGRectMake(self.totalsLabel.frame.origin.x, self.totalValueLabel.frame.origin.y, self.totalsLabel.frame.size.width, self.totalsLabel.frame.size.height);
        
        itemsTableFrame = CGRectMake(itemsTableFrame.origin.x, 54.0f, self.itemsTable.frame.size.width, totalsFrame.origin.y - self.showZeroLabel.frame.origin.y);
        
        totalValueAlpha = 0.0f;
    }
    else {
       
        if (self.displayTypeSegmentedControl.selectedSegmentIndex > 0) {
            totalValueAlpha = 0.0f;
        }
    }
    
    CGRect catTableFrame = [self frameForCatsTableFromItemsFrame:itemsTableFrame];
    
    if (animated) {
        [UIView animateWithDuration:0.50f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.totalsLabel.frame= totalsFrame;
                             self.itemsTable.frame = itemsTableFrame;
                             self.catsTable.frame = catTableFrame;
                             self.catTableLeftSpaceConstraint.constant = catTableFrame.origin.x;
                             self.catTableRightSpaceConstraint.constant = -1 * catTableFrame.origin.x;
                             self.itemTableLeftSpaceConstraint.constant = itemsTableFrame.origin.x;
                             self.itemTableRightSpaceConstraint.constant = -1 * itemsTableFrame.origin.x;
                             
                             self.totalValueLabel.alpha = totalValueAlpha;
                             [self.switchBottomSpaceConstraint setConstant:itemsTableTopConstraint];
                             [self.totalsLabelBottomSpaceConstraint setConstant:totalLabelBottomConstraint];
                             [self updateSwitchAlphasForViewAndTraitCollection:traitCollection];
                         }
                         completion:nil];
    }
    else {
        self.totalsLabel.frame= totalsFrame;
        self.itemsTable.frame = itemsTableFrame;
        self.catsTable.frame = catTableFrame;
        self.catTableLeftSpaceConstraint.constant = catTableFrame.origin.x;
        self.catTableRightSpaceConstraint.constant = -1 * catTableFrame.origin.x;
        self.itemTableLeftSpaceConstraint.constant = itemsTableFrame.origin.x;
        self.itemTableRightSpaceConstraint.constant = -1 * itemsTableFrame.origin.x;
        self.totalValueLabel.alpha = totalValueAlpha;
        [self.switchBottomSpaceConstraint setConstant:itemsTableTopConstraint];
        [self.totalsLabelBottomSpaceConstraint setConstant:totalLabelBottomConstraint];
        [self updateSwitchAlphasForViewAndTraitCollection:traitCollection];
    }
}

- (void)updateDisplayForSelectedView
{
    [self updateSwitchAlphasForViewAndTraitCollection:self.traitCollection];
    
    if (self.displayTypeSegmentedControl.selectedSegmentIndex == 0) {
        [self setActionButton];
        NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];
        if (categoryCount != allCats.count) {
            limitDisplayToCategoryAtIndex = -1;
            categoryCount = (int)allCats.count;
            //[self.itemsTable reloadData];
        }
        if (limitDisplayToCategoryAtIndex >= 0) {
            BOOL needToRecountUncatItems = YES;
            
            if (showLongList && pUncatLongPack) {
                needToRecountUncatItems = NO;
            }
            else if (!showLongList && pUncatShortPack) {
                needToRecountUncatItems = NO;
            }
            if (needToRecountUncatItems) {
                
                // need to recount uncat to get the total uncat item count to display
                
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
                [self enableTableSelect:NO];
                dispatch_async(queue, ^{
                    if (showLongList) {
                        [self calcTotalCountCompValForItems:pItemsLongPack.itemList forDisplaySegmentIndex:0];
                    }
                    else {
                        [self calcTotalCountCompValForItems:pItemsShortPack.itemList forDisplaySegmentIndex:0];
                    }
                    if (limitDisplayToCategoryAtIndex >= allCats.count) {
                        self.showZeroLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"category:", @"category"), NSLocalizedString(@"Uncategorized", @"Uncategorized")];
                        
                        if (showLongList) {
                            [self updateTotalCountsFromList:pUncatLongPack.itemList];
                        }
                        else {
                            [self updateTotalCountsFromList:pUncatShortPack.itemList];
                        }
                        
                    }
                    else {
                        DTCountCategory *cat = [allCats objectAtIndex:limitDisplayToCategoryAtIndex];
                        self.showZeroLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"category:", @"category"), [cat valueForKey:@"label"]];
                        //self.showZeroLabel.textAlignment = NSTextAlignmentCenter;
                        NSSet *items = [cat valueForKey:@"items"];
                        [self updateTotalCountsFromList:[items allObjects]];
                    }
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.itemsTable reloadData];
                        [self enableTableSelect:YES];
                    });
                });
            }
            else if (limitDisplayToCategoryAtIndex >= allCats.count) {
                self.showZeroLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"category:", @"category"), NSLocalizedString(@"Uncategorized", @"Uncategorized")];

                if (showLongList) {
                    [self updateTotalCountsFromList:pUncatLongPack.itemList];
                }
                else {
                    [self updateTotalCountsFromList:pUncatShortPack.itemList];
                }

            }
            else {
                DTCountCategory *cat = [allCats objectAtIndex:limitDisplayToCategoryAtIndex];
                self.showZeroLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"category:", @"category"), [cat valueForKey:@"label"]];
                //self.showZeroLabel.textAlignment = NSTextAlignmentCenter;
                NSSet *items = [cat valueForKey:@"items"];
                [self updateTotalCountsFromList:[items allObjects]];
            }
        }
        else {
            if (pItemsLongPack.itemList.count > pItemsShortPack.itemList.count) {
                self.showZeroLabel.text = NSLocalizedString(@"show zero-count items", @"show zero-count items");
            }
            
            if (showLongList) {
                [self updateTotalCountsFromList:pItemsLongPack.itemList];
            }
            else {
                [self updateTotalCountsFromList:pItemsShortPack.itemList];
            }
        }
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
        self.totalsLabel.text = [NSString stringWithFormat:@"%@ %lu", NSLocalizedString(@"categories: ", @"categories: "), (unsigned long)[[DTCountCategoryStore sharedStore] allCategories].count];
        self.showZeroLabel.text = NSLocalizedString(@"select a category", @"select a category");
    }
}

- (void)animateTableUpdateForItemsChangeShowLongList:(BOOL)showLong
{
    if (showLong == showLongList) {
        // no change, bail out
        return;
    }
    showLongList = showLong;
    
    [UIView animateWithDuration:0.333f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.itemsTable.alpha = 0.0f;
                         self.totalsLabel.alpha = 0.0f;
                         self.totalValueLabel.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         if (showLongList) {
                             [self updateTotalCountsFromList:pItemsLongPack.itemList];
                         }
                         else {
                             [self updateTotalCountsFromList:pItemsShortPack.itemList];
                         }
                         [self.itemsTable reloadData];
                         
                         [UIView animateWithDuration:0.333f
                                               delay:0.1f
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.itemsTable.alpha = 1.0f;
                                              //self.totalsLabel.alpha = 1.0f;
                                          }
                                          completion:^(BOOL fin){
                                              if (self.searchBar.text.length > 0) {
                                                  
                                                  [self searchForText:self.searchBar.text];
                                              }
                                          }];
                     }];

}


- (void)reloadData {
	[self.itemsTable reloadData];
    [self.catsTable reloadData];
    NSArray * items = pItemsShortPack.itemList;
    if (showLongList) {
        items = pItemsLongPack.itemList;
    }
	if (items.count > 0)
	{
        if (curSrchIdx >= 0 && curSrchIdx < items.count)
        {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:curSrchIdx inSection:0];
            [self.itemsTable selectRowAtIndexPath:ip animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        }
		else curSrchIdx = -1;
	}
}

- (CGRect)frameForCatsTableFromItemsFrame:(CGRect)itemsFrame
{
    CGRect frame = CGRectMake(itemsFrame.origin.x - tableShiftX, itemsFrame.origin.y, itemsFrame.size.width, itemsFrame.size.height);
    return frame;
}

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)recognizer
{
    [self.view endEditing:YES];
    if (!self.displayTypeSegmentedControl.enabled) {
        return;
    }
    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        if (self.displayTypeSegmentedControl.selectedSegmentIndex == 0) {
            [self.displayTypeSegmentedControl setSelectedSegmentIndex:1];
            [self displayTypeSegmentValueChanged:nil];
        }
        else {
            [self animateTableBounceInDirection:recognizer.direction];
        }
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        if (self.displayTypeSegmentedControl.selectedSegmentIndex == 1) {
            [self.displayTypeSegmentedControl setSelectedSegmentIndex:0];
            [self displayTypeSegmentValueChanged:nil];
        }
        else {
            [self animateTableBounceInDirection:recognizer.direction];
        }
    }
}



- (void)searchForText:(NSString *)txt
{
    if ([detailViewController isViewLoaded]) 
    {
        [[self navigationController] popViewControllerAnimated:YES];
    }
    [self.searchBar setText:txt];
    [self searchBar:self.searchBar textDidChange:txt];
}



- (void)setActionButton
{
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonSelected:)];
    actionButton.tintColor = [AppController sharedAppController].barButtonColor;
    self.navigationItem.rightBarButtonItem = actionButton;
}

- (void)updateTotalCountsFromList:(NSArray *)items
{
    [self enableTableSelect:NO];
    self.totalValueLabel.text = @"";
    self.totalsLabel.text = @"";
    BOOL needToCalc = YES;
    NSUInteger cnt = 0;
    NSUInteger invCnt = 0;
    CGFloat totalValue = 0.0f;
    
    int segIndex = (int)self.displayTypeSegmentedControl.selectedSegmentIndex;
    
    NSArray *allCats = [[DTCountCategoryStore sharedStore] allCategories];

        
    if ((pUncatLongPack && showLongList) || (pUncatShortPack && !showLongList)) {
    
        if (segIndex == 0) {
            if (limitDisplayToCategoryAtIndex < 0) {
                if (showLongList) {
                    if (pItemsLongPack.totalCount > 0) {
                        needToCalc = NO;
                        cnt = pItemsLongPack.totalCount;
                        invCnt = pItemsLongPack.totalInventory;
                        totalValue = pItemsLongPack.totalValue;
                    }
                }
                else {
                    if (pItemsShortPack.totalCount > 0) {
                        needToCalc = NO;
                        cnt = pItemsShortPack.totalCount;
                        invCnt = pItemsShortPack.totalInventory;
                        totalValue = pItemsShortPack.totalValue;
                    }
                }
            }
            else if (limitDisplayToCategoryAtIndex >= allCats.count) {
                if (showLongList) {
                    if (pUncatLongPack.totalCount > 0 || pUncatLongPack.totalInventory > 0) {
                        cnt = pUncatLongPack.totalCount;
                        invCnt = pUncatLongPack.totalInventory;
                        totalValue = pUncatLongPack.totalValue;
                        needToCalc = NO;
                    }
                }
                else if (pUncatShortPack.totalCount > 0 || pUncatShortPack.totalInventory > 0) {
                    needToCalc = NO;
                    cnt = pUncatShortPack.totalCount;
                    invCnt = pUncatShortPack.totalInventory;
                    totalValue = pUncatShortPack.totalValue;
                }
                
            }
            
        }
    }
    
    if (needToCalc) {
        self.totalsLabel.alpha = 0.0f;
        self.totalValueLabel.alpha = 0.0f;
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        dispatch_async(queue, ^{
           NSArray *totalsArray = [self calcTotalCountCompValForItems:items forDisplaySegmentIndex:segIndex];
            
            NSNumber *num = [totalsArray objectAtIndex:0];
            NSInteger totalCnt = [num integerValue];
            num = [totalsArray objectAtIndex:1];
            NSInteger totalComp = [num integerValue];
            num = [totalsArray objectAtIndex:2];
            CGFloat val = [num floatValue];
            
            if (segIndex == 0) {
                if (limitDisplayToCategoryAtIndex < 0) {
                    if (showLongList) {
                        pItemsLongPack.totalValue = val;
                        pItemsLongPack.totalCount = totalCnt;
                        pItemsLongPack.totalInventory = totalComp;
                    }
                    else {
                        pItemsShortPack.totalValue = val;
                        pItemsShortPack.totalCount = totalCnt;
                        pItemsShortPack.totalInventory = totalComp;
                    }
                }
                else if (limitDisplayToCategoryAtIndex >= [[DTCountCategoryStore sharedStore] allCategories].count) {
                    if (showLongList) {
                        pUncatLongPack.totalValue = val;
                        pUncatLongPack.totalCount = totalCnt;
                        pUncatLongPack.totalInventory = totalComp;
                    }
                    else {
                        pUncatShortPack.totalValue = val;
                        pUncatShortPack.totalCount = totalCnt;
                        pUncatShortPack.totalInventory = totalComp;
                    }
                }
                
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                [self updateTotalsLabelsWithitemCount:items.count withTotalCount:totalCnt withTotalCompare:totalComp withTotalValue:val];
                

            });
        });
        
        
    }
    else {
        [self updateTotalsLabelsWithitemCount:items.count withTotalCount:cnt withTotalCompare:invCnt withTotalValue:totalValue];
    }
    
}

- (void)enableTableSelect:(BOOL)enabled
{
    self.displayTypeSegmentedControl.enabled = enabled;
}

- (void)updateTotalsLabelsWithitemCount:(NSInteger)itemCnt withTotalCount:(NSInteger)cnt withTotalCompare:(NSInteger)invCnt withTotalValue:(CGFloat)totalValue
{
    if (self.displayTypeSegmentedControl.selectedSegmentIndex != 0) {
        return;
    }
    AppController *ac = [AppController sharedAppController];
    NSString *itemListCountString = [ac formatNumber:itemCnt];
    NSString *countsString = [ac formatNumber:cnt];
    NSString *invCountsString = [ac formatNumber:invCnt];
    
    //UIToolbar *toolbar = [[self navigationController] toolbar];
    //[[self navigationController] setToolbarHidden:NO animated:YES];
    //UIColor *textColor = textColor = [[AppController sharedAppController] barColor];
    
    NSString *countTotalString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"counts:", @"counts:"), countsString];
    if (invCnt > 0 && invCnt != cnt && invCnt < 1000000) {
        countTotalString = [NSString stringWithFormat:@"%@ %@ / %@", NSLocalizedString(@"counts:", @"counts:"), countsString, invCountsString];
    }
    
    self.totalsLabel.text = [NSString stringWithFormat:@"%@ %@   %@", NSLocalizedString(@"items:", @"items:"), itemListCountString, countTotalString];
    
    if (totalValue > 0.0f) {
        self.totalValueLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"value:", @"value:"), [ac formatNSNumber:[NSNumber numberWithFloat:totalValue]]];
    }
    else {
        self.totalValueLabel.text = @"";
    }
    
    [UIView animateWithDuration:0.25f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         if (totalValue > 0.0f && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
                             self.totalValueLabel.alpha = 1.0f;
                         }
                         self.totalsLabel.alpha = 1.0f;
                     }
                     completion:^(BOOL fin) {
                         [self enableTableSelect:YES];
                     }];
}

/**
 *  returns NSNumber array of totalCount, totalInventory, totalValue(CGFloat)
 */
- (NSArray *)calcTotalCountCompValForItems:(NSArray *)items forDisplaySegmentIndex:(int)segIndex
{
    NSInteger cnt = 0;
    NSInteger invCnt = 0;
    CGFloat totalValue = 0.0f;
    
    BOOL updateUncat = NO;
    NSMutableArray *itemsUncategory;
    
    if (pUncatLongPack == nil && showLongList) {
        pUncatLongPack = [[DTCountTotalsPack alloc] init];
        itemsUncategory = [[NSMutableArray alloc] initWithCapacity:items.count / 2];
        updateUncat = YES;
    }
    if (pUncatShortPack == nil && !showLongList) {
        pUncatShortPack = [[DTCountTotalsPack alloc] init];
        itemsUncategory = [[NSMutableArray alloc] initWithCapacity:items.count / 2];
        updateUncat = YES;
    }
    
    if (items == nil) {
        if (showLongList) {
            items = pItemsLongPack.itemList;
        }
        else {
            items = pItemsShortPack.itemList;
        }
    }
    
    for (int i = 0; i < items.count; ++i) {
        DTCountItem *itm = (DTCountItem *)[items objectAtIndex:i];
        NSInteger itmCount = 0;
        
        if (updateUncat) {
            DTCountCategory *cat = [itm valueForKey:@"category"];
            if (cat == nil) {
                [itemsUncategory addObject:itm];
            }
        }
        
        NSArray *inventoriesForItem = [[itm valueForKey:@"inventories"] allObjects];
        for (int invIndex = 0; invIndex < (int)inventoriesForItem.count; ++invIndex) {
            DTCountInventory *mi = (DTCountInventory *)[inventoriesForItem objectAtIndex:invIndex];
            
            DTCountLocation *miLoc = [mi valueForKey:@"location"];
            if (miLoc) {
                NSString *miLocName = [miLoc valueForKey:@"label"];
                
                if ([miLocName isEqualToString:[[AppController sharedAppController] totalCountsSecretLocationName]] == NO) {
                    itmCount += [[mi valueForKey:@"count"] intValue];
                }
                else {
                    invCnt += [[mi valueForKey:@"count"] intValue];
                    hasTotalCountLocation = YES;
                }
            }
            //else {
            //    NSLog(@" totals found itm, %@, inv without a location!! -ignoring", [itm valueForKey:@"label"]);
            //}
        }
        totalValue += [[itm valueForKey:@"value"] floatValue] * itmCount;
        cnt += itmCount;
    }
    
    if (itemsUncategory.count > 0) {
        if (showLongList) {
            pUncatLongPack.itemList = [itemsUncategory copy];
        }
        else {
            pUncatShortPack.itemList = [itemsUncategory copy];
        }
    }
    
    
    return [NSArray arrayWithObjects:[NSNumber numberWithInteger:cnt], [NSNumber numberWithInteger:invCnt], [NSNumber numberWithFloat:totalValue], nil];
}



@end
