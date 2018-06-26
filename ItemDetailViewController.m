    //
//  ItemDetailViewController_iPad.m
//  DCount
//
//  Created by David Shrock on 12/21/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//

#import "ItemDetailViewController.h"
#import "DTCountLocation.h"
#import "AppController.h"
#import "DTCategoryPickViewController.h"

//#import "AppController_Shared.h";

@interface ItemDetailViewController () <UITextFieldDelegate> {
    NSMutableArray *locations;
    
    BOOL descriptionHasBeenUpdated;
    BOOL valueHasBeenUpdated;
}
@property (weak, nonatomic) IBOutlet UITextField *descTextField;
@property (weak, nonatomic) IBOutlet UITextField *totalCountTextField;
@property (weak, nonatomic) IBOutlet UITextField *totalCompareCountTextField;
@property (weak, nonatomic) IBOutlet UITableView *locsTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *categoryBarButton;

@property (weak, nonatomic) IBOutlet UITextField *valueTextField;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UILabel *inventoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationsLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inventoryCountTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inventoryCountRightSpace;
@end

@implementation ItemDetailViewController
@synthesize descTextField, totalCompareCountTextField, totalCountTextField, locsTableView;
@synthesize locSelectDelegate;



static NSDictionary *cellHeightDictionary;


 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (id)init
{
    self = [super init];
    if (!self) return nil;
    locations = [[NSMutableArray alloc] init];

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

        //[upcTextField setText:[item valueForKey:@"label"]];
    [self.navigationItem setTitle:[self.item valueForKey:@"label"]];
    
    if (self.needsDoneButton) {
        self.preferredContentSize = CGSizeMake(366.0, 500.0);
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        self.navigationItem.leftBarButtonItem = doneItem;
    }
    
    descriptionHasBeenUpdated = NO;
    valueHasBeenUpdated = NO;

    [descTextField setText:[self.item valueForKey:@"desc"]];
    NSString *valString = @"0";

    valString = [[AppController sharedAppController] formatNSNumber:[self.item valueForKey:@"value"]];
    self.valueTextField.text = valString;
    
    NSString *catString = [self.item.category valueForKey:@"label"];
    if (!catString) {
        catString = NSLocalizedString(@"None", @"None - no cat label");
    }

    self.categoryBarButton.title = [NSString stringWithFormat:@" %@ %@ ", NSLocalizedString(@"Category:", @"Category:"), catString];
    self.descTextField.placeholder = NSLocalizedString(@"name / description", @"name / description");
    
    //[totalCountTextField setText:totalCntString];	
    int totalCnt = 0;
    

    //int totalCnt = 0;
    BOOL hasCompareCounts = NO;
    AppController *ac = [AppController sharedAppController];
    NSArray *inventoriesForItem = [[self.item valueForKey:@"inventories"] allObjects];
    [locations removeAllObjects];
    
    for (DTCountInventory *mi in inventoriesForItem) {
        NSInteger countVal = [[mi valueForKey:@"count"] intValue];
        if (countVal > 0) {
            DTCountLocation *loc = [mi valueForKey:@"location"];
            if (loc) {
                NSString *locName = [loc valueForKey:@"label"];
                
                if ([locName isEqualToString:[ac totalCountsSecretLocationName]])
                {
                    hasCompareCounts = YES;
                    NSString *countValStr = [ac formatNumber:countVal];
                    
                    [totalCompareCountTextField setText:[NSString stringWithFormat:@"%@", countValStr]];
                }
                else
                {
                    [locations addObject:loc];
                    totalCnt += [[mi valueForKey:@"count"] intValue];
                }
            }
        }
    }
    NSString *totalCountString = [ac formatNumber:totalCnt];
    //NSString *totalCountString = [NSString stringWithFormat:@"%d", totalCnt];
    if (hasCompareCounts == NO) {
        [totalCompareCountTextField setText:@" - "];
    }
    [totalCountTextField setText:totalCountString];
    [self updateFonts];
    
    [self layoutWithTraits:self.traitCollection];

}


- (void)viewDidLoad
{
	[super viewDidLoad];
    descTextField.delegate = self;
    self.valueTextField.delegate = self;
    
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeRecognizer];
    
    // localize the nib
    
    [locsTableView reloadData];
	[totalCountTextField setEnabled:NO];
    
    
}

- (void)viewDidLayoutSubviews
{
    // prevent navbar from covering our sub-views
    self.navigationController.navigationBar.translucent = NO;
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self layoutWithTraits:newCollection];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
    
}

- (void)layoutWithTraits:(UITraitCollection *)traitCollection
{
    CGFloat xAdj = 0.0f;
    CGFloat vWidth = self.navigationController.navigationBar.frame.size.width;
    if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        vWidth += 12.0f;  // add buffer for rotation adj
    }

    CGFloat rightSideSpace = 8.0f;
    
    if (vWidth < 340.0f) {
        xAdj = 324.0f - vWidth;
        if (xAdj > 0) {
            rightSideSpace = 8.0f - xAdj;
        }
    }

    if (self.navigationController.navigationBar.frame.size.width > 470.0f &&
        traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact &&
        traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact)
    {
        self.inventoryCountTopConstraint.constant = 11.0f;
        self.countLabel.frame = CGRectMake(self.countLabel.frame.origin.x, 67.0f, self.countLabel.frame.size.width, self.countLabel.frame.size.height);
        self.totalCountTextField.frame = CGRectMake(self.totalCountTextField.frame.origin.x, 63.0f, self.totalCountTextField.frame.size.width, self.totalCountTextField.frame.size.height);
        self.locationsLabel.frame = CGRectMake(self.locationsLabel.frame.origin.x, 114.0f, self.locationsLabel.frame.size.width, self.locationsLabel.frame.size.height);
        self.locsTableView.frame = CGRectMake(self.locsTableView.frame.origin.x, 145.0f, self.locsTableView.frame.size.width, self.locsTableView.frame.size.height);
        
    }
    else {
        self.inventoryCountTopConstraint.constant = 60.0f;
        self.countLabel.frame = CGRectMake(vWidth - 310.0f + xAdj, 116.0f, self.countLabel.frame.size.width, self.countLabel.frame.size.height);
        self.totalCountTextField.frame = CGRectMake(self.countLabel.frame.origin.x + 56.0f, 111.0f, self.totalCountTextField.frame.size.width, self.totalCountTextField.frame.size.height);
        self.locationsLabel.frame = CGRectMake(self.locationsLabel.frame.origin.x, 161.0f, self.locationsLabel.frame.size.width, self.locationsLabel.frame.size.height);
        self.locsTableView.frame = CGRectMake(self.locsTableView.frame.origin.x, 192.0f, self.locsTableView.frame.size.width, self.locsTableView.frame.size.height);
        
        self.valueTextField.alpha = 1.0f;
        self.valueLabel.alpha = 1.0f;
    }
    self.inventoryLabel.frame = CGRectMake(self.countLabel.frame.origin.x + 135.0f, self.countLabel.frame.origin.y, self.inventoryLabel.frame.size.width, self.inventoryLabel.frame.size.height);
    self.totalCompareCountTextField.frame = CGRectMake(self.countLabel.frame.origin.x + 217.0f, self.totalCountTextField.frame.origin.y, self.totalCompareCountTextField.frame.size.width, self.totalCompareCountTextField.frame.size.height);
   
    self.inventoryCountRightSpace.constant = rightSideSpace;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (void)updateFonts
{

        //UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        //descTextField.font = font;
        //totalCompareCountTextField.font = font;
        //totalCountTextField.font = font;
        
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
        [locsTableView setRowHeight:cellHeight.floatValue];
        [locsTableView reloadData];
}

#pragma mark -
#pragma mark tableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    //return [tableContent numberOfSections];  
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [locations count];
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)path
{
    return path;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemDetailLocationCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ItemDetailLocationCell"];
        //[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIView *v = [[UIView alloc] init];
        v.backgroundColor = [[AppController sharedAppController] barColor];
        cell.selectedBackgroundView = v;
        
        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        cell.textLabel.font = font;

	}
    
	if ([locations count] > 0)
    {
        DTCountLocation *loc = [locations objectAtIndex:[indexPath row]];
        NSString *inventorySummary = [NSString stringWithFormat:@"%@", 
                                      [loc valueForKey:@"label"]];
        [cell.textLabel setText:inventorySummary];
        DTCountInventory *inventory = [self inventoryForLocationOfItem:loc];
        
        if (inventory)
        {
            int count = [[inventory valueForKey:@"count"] intValue];
            NSString *countStr = [[AppController sharedAppController] formatNumber:count];
            //NSString *countStr = [NSString stringWithFormat:@"%d", count];
            NSString *inventoryDetail = [NSString stringWithFormat:@"%@", countStr];
            [cell.detailTextLabel setText:inventoryDetail];
        }
        else [cell.detailTextLabel setText:@""];
    }
	
    
    return cell;	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DTCountLocation *loc = (DTCountLocation *)[locations objectAtIndex:indexPath.row];
    [self.locSelectDelegate selectedLocation:loc selectedItemLabel:[self.navigationItem title]];
}



#pragma mark -
#pragma mark memory

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *filteredString = [[string componentsSeparatedByCharactersInSet:[[AppController sharedAppController] badCharacters]] componentsJoinedByString:@""];
    if ([filteredString isEqualToString:string] == NO) {
        return NO;
    }
    return YES;
}

#pragma mark - gestures

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer.direction == UISwipeGestureRecognizerDirectionDown) {
        [self.view endEditing:YES];
    }
}

- (IBAction)valueFieldChanged:(id)sender
{
    if (valueHasBeenUpdated == NO) {
        valueHasBeenUpdated = YES;
        [self.updateDelegate itemDetailValueUpdated];
    }
}

#pragma mark - outlets

- (IBAction)updateDescription
{
    AppController *ac = [AppController sharedAppController];
	NSString *newDesc = [descTextField text];
	if (newDesc.length > [ac maxDescLength]) newDesc = [newDesc substringToIndex:[ac maxDescLength]];
	newDesc = [ac stripBadCharactersFromString:newDesc];
    newDesc = [newDesc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	[descTextField setText:newDesc];
	[self.item setValue:newDesc forKey:@"desc"];
    
}
- (IBAction)valueFieldEditEnd:(id)sender
{
    NSNumber *num = [NSNumber numberWithFloat:[self.valueTextField.text floatValue]];
    [self.item setValue:num forKey:@"value"];
}
- (IBAction)categoryButtonTouchAction:(id)sender
{
    [self.view endEditing:YES];
    
    DTCategoryPickViewController *catPickController = [[DTCategoryPickViewController alloc] init];
    catPickController.item = self.item;
    catPickController.preferredContentSize = self.view.bounds.size;
    
    [self.navigationController pushViewController:catPickController animated:YES];
}

#pragma mark - methods

- (DTCountInventory *)inventoryForLocationOfItem:(NSManagedObject *)loc
{
	NSArray *inventoriesForItem = [[self.item valueForKey:@"inventories"] allObjects];
	for (DTCountInventory *mi in inventoriesForItem) {
		if ([mi valueForKey:@"location"] == loc) {
			return mi;
		}
	}
	return nil;
}

- (void)done:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:self.dismissBlock];
}

@end
