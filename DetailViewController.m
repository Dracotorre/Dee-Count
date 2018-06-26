//
//  DetailViewController.m
//  Dee Count
//
//  Created by David G Shrock on 8/7/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
//  updated from 2010 version 1, DetailViewController_iPad
//  - ARC and style and iOS 8 layout
//  - delegate improvements
//  - moved locals and IBOutlets to implementation file
//  - added configureLayout method to support various sizes

#import "DetailViewController.h"
#import "AppController.h"
#import "DTCountInventory.h"
#import "DTCountItem.h"
#import "DTCountLocation.h"
#import "DTCountCategoryStore.h"
#import "ImageCache.h"
#import "ItemCell.h"
#import "CountPadSelectController.h"
#import "ItemDetailViewController.h"
#import "TotalCountViewController.h"
#import "ToolsActionViewController.h"
#import "DataDocViewController.h"
#import "InventoryUpdateOperation.h"
#import "DTCBGOperationsWorker.h"
#import "DeleteConfirmViewController.h"
#import "EditPhotoTableView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "DTScanCode/DTScanCodeViewController.h"
#import "DTScanCode/DTScanCodeMetaControl.h"
#import "DTCountCategory.h"
#import "DTCategoryPickViewController.h"
#import "DTCountLogEntry.h"
#import "DTCountLogItems.h"
#import "DTCountAidManageViewController.h"

typedef void(^myEnableCompletion)(BOOL);
typedef void(^configureLayoutCompletion)(BOOL);


@interface DetailViewController () <ItemCellActionDelegate, CountPadDoneDelegate, ScanBarCodeSelectedActionDelegate, LocationselectActionDelegate, ToolsActionsDelegate, UpdateInventoryOperationDelegate, DataDocDelegate, DeleteConfirmDelegate, EditPhotoDelegate, CountAidDelegate, DTCategoryPickDelegate, UIGestureRecognizerDelegate> {
    BOOL hasUserImage;
    BOOL displayLog;
    BOOL addCountReturning;
    BOOL cellMenuShowing;
    BOOL kbShowing;
    BOOL kbWillHide;
    BOOL layoutIsNarrow;
    BOOL documentPickerForImport;
    BOOL tipLocationViewed;
    BOOL tipUPCViewed;
    BOOL viewIsLoaded;
    BOOL viewOnStartupLoad;    // coming from a setDetail in hidden view
    BOOL isRestartingAll;
    BOOL isPinchingImageDown;
    
    int countBy;
    int countByCustom;
    NSUInteger locationTotalItemCount;
    int addCount;      // use this to keep track of when to save
    
    /**
     * iPad will subtract size of master even though will disappear
     */
    CGFloat displayNarrowWidthLimit;
    CGFloat displayCompactHeightLimit;
    
    NSString *selectedDetailLabel;
    
    NSMutableArray *itemsTotalList;          // all items
    NSMutableArray *itemsAtLoc;              // location items
    NSMutableArray *itemsShortList;          // no zero counts
    NSMutableArray *itemsTempList;           // for when no totals that need merging
    
    DTCountLogItems *logItems;
}

// outlets
@property (weak, nonatomic) IBOutlet UIButton *negateCountToggle;
@property (weak, nonatomic) IBOutlet UISegmentedControl *countBySegmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *itemCountAddField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *itemCountAddFieldConstrantTopSpace;
@property (weak, nonatomic) IBOutlet UITextField *locTotalCntTextField;
@property (weak, nonatomic) IBOutlet UITableView *itemListTableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *locImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locImageContrainstWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locImageContranstHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locImageConstraintTopSpace;

@property (weak, nonatomic) IBOutlet UIImageView *shadowImageView;

@property (weak, nonatomic) IBOutlet UIButton *scanItemCodeButton;
@property (weak, nonatomic) IBOutlet UIButton *scanTitleCodeButton;
@property (weak, nonatomic) IBOutlet UITextView *itemCountLogTextView;
@property (weak, nonatomic) IBOutlet UIButton *locImageButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locImageEditContraintWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locImageEditConstraintHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locImageEditContraintTopSpace;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *okCountButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UIImageView *segmentPointImage;
@property (weak, nonatomic) IBOutlet UITextField *locationTitleTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locationTitleConstraintVertSpace;
@property (weak, nonatomic) IBOutlet UITextView *importTextView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *itemListWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locTotalWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *itemLogTopAlignToTableConstraint;

// controls without outlets
@property (strong, nonatomic) UIBarButtonItem *countTotalButton;
@property (strong, nonatomic) UIBarButtonItem *actionButton;
@property (strong, nonatomic) UIBarButtonItem *toolsButton;
@property (strong, nonatomic) UIBarButtonItem *cameraButton;

@property (strong, nonatomic) UIBarButtonItem *toggleLogListButton;
@property (strong, nonatomic) UIBarButtonItem *cancelImportButton;
@property (strong, nonatomic) UIButton *incrementCountForCurTextButton;
@property (strong, nonatomic) UIBarButtonItem *logToggleButton;
@property (strong, nonatomic) UITextField *locTotalCntBlinkTextField;
@property (strong, nonatomic) UILabel *tipTextLabel;
@property (strong, nonatomic) UIBarButtonItem *categoryBarButton;


// other properties
@property (strong, nonatomic) UIImage *defaultLocationImage;
@property (strong, nonatomic) UIImage *currentImage;
@property (strong, nonatomic) CALayer *shadowImageLayer;
//@property (strong, nonatomic) UIColor *defLocationColor;
@property (nonatomic) BOOL showOKCountButton;
@property (nonatomic, strong) DTCBGOperationsWorker *pendingCountUpdateOps;
@property (nonatomic, strong) NSDictionary *cellHeightDictionary;
@property (nonatomic) CGSize mySize;
@property (nonatomic, readonly) CGFloat shadowOpacityDefault;
@property (nonatomic, readonly) CGFloat logAlphaDefault;
@property (nonatomic, readonly) CGFloat imageEditButtonAlphaDefault;

@property (nonatomic) BOOL isPlusPhone;

//@property (strong, nonatomic) UIPopoverPresentationController *countTotalPopoverController;
@property (weak, nonatomic) UIImagePickerController *imageLocationPickerController;
@property (nonatomic, weak) CountPadSelectController *countPadController;
@property (nonatomic, weak) DTScanCodeViewController *scanCodeViewController;
@property (nonatomic, weak) UINavigationController *itemDetailNavController;
@property (nonatomic, strong) UINavigationController *totalCountNavController;
@property (nonatomic, weak) UINavigationController *toolsMenuNavController;
@property (nonatomic, weak) UINavigationController *exportMenuNavController;
@property (nonatomic, weak) UINavigationController *deleteConfirmNavController;
@property (nonatomic, strong) UIDocumentInteractionController *docToOpenInOtherController;
@property (nonatomic, weak) UINavigationController *editPhotoNavController;
@property (nonatomic, weak) UINavigationController *categoryPickNavController;
@property (nonatomic, strong) UINavigationController *compareHelpNavController;
@property (nonatomic, strong) UIDocumentPickerViewController *docPickerController;


@end

@implementation DetailViewController

@synthesize showOKCountButton, layoutMode;
@synthesize myShortItems = itemsShortList;

#pragma mark - implementation
#pragma mark - init

- (CGFloat)shadowOpacityDefault
{
    return 0.75f;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        countBy = 1;
        countByCustom = (int)[[AppController sharedAppController] getCustomCountValue];
        
        itemsTotalList = nil;
        NSString* imageName = [[NSBundle mainBundle] pathForResource:@"defback" ofType:@"png"];
        self.defaultLocationImage = [[UIImage alloc] initWithContentsOfFile:imageName];
        
        displayNarrowWidthLimit = 564.0;
        displayCompactHeightLimit = 360.0f;
        
        documentPickerForImport = NO;
        
        logItems = [[DTCountLogItems alloc] init];
        
    }
    return self;
}

#pragma mark - custom settings/getters

- (NSArray *)myTotalItems
{
    return [itemsTotalList copy];
}

- (NSArray *)myTempTotalItems
{
    return [itemsTempList copy];
}

- (CGFloat)logAlphaDefault
{
    return 0.50f;
}

- (CGFloat)imageEditButtonAlphaDefault
{
    return 0.6667f;
}

- (void)setLayoutMode:(DisplayLayoutMode)mode
{
    layoutMode = mode;
    [self checkPopoversToDismiss];
    [self.progressView setProgress:0.0f];
    [self.itemCountAddField resignFirstResponder];
    
    if (layoutMode == EditingLayout) {
        [self setEditing:YES animated:YES];
        [self configureBarButtons:YES];
        
        if (self.importStartupError != 0) {
            [self handleStartupError];
        }
    }
    else if (layoutMode == ImportLayout || layoutMode == UpdateDataLayout) {
        itemsTotalList = nil;
        itemsShortList = nil;
        [self configureLayoutAnimated:NO completion:nil];
        [self configureBarButtons:NO];
    }
    else {
        [self.itemListTableView reloadData];
        [self configureLayoutAnimated:YES completion:^(BOOL fin){
            [self configureBarButtons:YES];
            if (self.importStartupError != 0) {
                [self handleStartupError];
            }
        }];
        
    }
}

- (void)setTotalItemsAll:(NSArray *)totals shortItems:(NSArray *)shortItems tempItems:(NSArray *)tmps
{
    if (itemsTempList == nil && tmps) {
        itemsTempList = [tmps mutableCopy];
    }
    if (totals) {
        if (itemsTempList.count > 0 || shortItems == nil || shortItems.count == 0) {
            [self setTotalItems:totals];
        }
        else {
            itemsTotalList = [totals mutableCopy];
            itemsShortList = [shortItems mutableCopy];
        }
    }
}

/**
 *  assumed called on main thread by MasterView - update total items
 *  once. see setTotalItemsAll: ...
 */
- (void)setTotalItems:(NSArray *)itms
{
    if (itms != nil) {
        itemsTotalList = [itms mutableCopy];
        itemsShortList = [[NSMutableArray alloc] init];
        
        if (itemsTempList != nil && itemsTempList.count > 0) {
            NSLog(@"checking to merge temp items");
            for (int tmpIdx = 0; tmpIdx < itemsTempList.count; ++tmpIdx) {
                DTCountItem *tmpItem = (DTCountItem *)[itemsTempList objectAtIndex:tmpIdx];
                NSString *itemLabel = [tmpItem valueForKey:@"label"];
                DTCountItem *checkItem = [self itemInTotalsWithLabel:itemLabel];
                if (checkItem == nil) {
                    NSLog(@"adding item to totals: %@", itemLabel);
                    [itemsTotalList addObject:tmpItem];
                }
                else {
                    NSLog(@" ! already have the items: %@", itemLabel);
                }
            }
            itemsTempList = nil;
        }
        
        for (int i = 0; i < itemsTotalList.count; ++i) {
            DTCountItem *itm = [itemsTotalList objectAtIndex:i];
            if ([self itemHasCount:itm]) {
                [itemsShortList addObject:itm];
            }
        }
        [self configureBarButtons:NO];
        //self.countTotalButton.enabled = YES;
        //self.toolsButton.enabled = YES;
    }
    else {
        NSLog(@" detail setTotalItems is nil");
    }
    
    
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {

        _detailItem = newDetailItem;
        itemsAtLoc = nil;
        if (self.editing) {
            self.editing = NO;
        }
        layoutMode = NormalLayout;
        
        // Update the detail item for view
        [self configureView];
        
        if (viewIsLoaded && !self.editButtonItem.enabled) {
            [self enableLayout:YES animated:YES forDuration:0.20f completion:^(BOOL fin){
                [self configureBarButtons:YES];
                if (self.importStartupError != 0) {
                    [self handleStartupError];
                }
            }];
        }
        else if (!viewIsLoaded && newDetailItem) {
            viewOnStartupLoad = YES;
        }
    }
}

- (BOOL)imageIsBig
{
    if (self.locImageView.alpha > 0.0f) {
        if (self.locImageView.frame.size.width > 280.0f) {
            return YES;
        }
        if (self.locImageView.frame.size.height > 212.0f) {
            return YES;
        }
    }
    
    return NO;
}

- (void)updateTitle:(NSString *)title
{
    if (title == nil || title.length == 0) {
        DTCountLocation *loc = (DTCountLocation *)self.detailItem;
        title = [loc valueForKey:@"label"];
    }
    int maxLen = 16;
    if (self.navigationController.navigationBar.frame.size.width > 512.0f) {
        maxLen = 28;
    }
    if (title.length > maxLen) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@...", [title substringToIndex:maxLen]];
    }
    else {
        self.navigationItem.title = title;
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    
    [self setMyTitle];
    
    if (self.detailItem != nil) {
        DTCountLocation *loc = (DTCountLocation *)self.detailItem;
        NSString *locLabel = [loc valueForKey:@"label"];
        [self configureCategoryButtonTitle:loc];
        
        if ([locLabel hasPrefix:@"NewLocation"] || [locLabel hasPrefix:NSLocalizedString(@"New Location", @"New Location")]) {
            self.locationTitleTextField.text = @"";
        }
        else self.locationTitleTextField.text = locLabel;
        
        NSString *imageKey = [loc valueForKey:@"picuuid"];
        
        if (imageKey) {
            hasUserImage = YES;
            UIImage *imageToDisplay = [[ImageCache sharedImageCache] imageForKey:imageKey];
            if (imageToDisplay == nil || imageToDisplay.size.width <= 0) {
                hasUserImage = NO;
                [loc setValue:nil forKey:@"picuuid"];
                [loc setPicture:nil];
                [self setDefaultPhoto];
            }
            else {
                [self updateLocationImage:imageToDisplay isNewImage:YES isZoomEnlarged:NO animated:NO withDuration:0.0f includeBounce:NO];
            }
        }
        else {
            hasUserImage = NO;
            [self setDefaultPhoto];
        }
        
        if (itemsAtLoc == nil) {
            [self reloadLocationItems];
        }
        
        [self.itemListTableView reloadData];
        
    }
    else {
        [self enableLayout:NO animated:NO forDuration:0.0f completion:nil];
        [self setDefaultPhoto];
    }
    [self.countBySegmentedControl setSelectedSegmentIndex:0];
    [self updateCountsValuesForTotalItemsCount:locationTotalItemCount fromOldValue:locationTotalItemCount withBlink:NO];
}

- (void)configureCategoryButtonTitle:(DTCountLocation *)loc
{
    NSString *defCatStr = [loc valueForKey:@"defCatLabel"];
    if (defCatStr.length > 0) {
        self.categoryBarButton.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Category:", @"Category:"), defCatStr];
    }
    else {
        self.categoryBarButton.title = NSLocalizedString(@"Category: None", @"Category: None");
    }
}

- (void)saveLocationDetails
{
    AppController *ac = [AppController sharedAppController];
    DTCountLocation *detailLoc = (DTCountLocation *)self.detailItem;
    
    NSString *locTitle = [[self.locationTitleTextField text]
                          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (locTitle.length > [ac maxTitleLength]) locTitle = [locTitle substringToIndex:[ac maxTitleLength]];
    
    detailLoc.oldName = [detailLoc valueForKey:@"label"];
    
    if (locTitle.length > 0)
    {
        locTitle = [ac stripBadCharactersFromString:locTitle];
        [self.locationTitleTextField setText:locTitle];
        [self.navigationItem setTitle:locTitle];
        
        [detailLoc setValue:locTitle forKey:@"label"];
    }
    else
    {
        locTitle = [detailLoc valueForKey:@"label"];
        [self.locationTitleTextField setText:locTitle];
        [self.navigationItem setTitle:locTitle];
    }
    
    //[self.locationTitleTextField setEnabled:NO];
    //[self.locationTitleTextField setTextColor:self.defLocationColor];
    [self.locationTitleTextField setBackgroundColor:[UIColor clearColor]];
    
    [ac saveContext];
    [self.delegate detailLocationSaved];
}


#pragma mark -
#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.itemListTableView registerClass:[ItemCell class] forCellReuseIdentifier:@"ItemCell"];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    if (screenWidth == 736.0f || screenHeight == 736.0f) {
        self.isPlusPhone = YES;
    }
    
    [self assetsLibraryCheck];
    
    if (itemsTotalList == nil) {
        self.countTotalButton.enabled = NO;
        self.toolsButton.enabled = NO;
    }
    
    self.okCountButton.alpha = 0.0f;
    
    self.categoryBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Category: None", "Category: None") style:UIBarButtonItemStylePlain target:self action:@selector(categoryButtonAction:)];
    self.categoryBarButton.tintColor = self.deleteLocationButton.tintColor;
    
    // make corners
    CALayer *layer = self.itemListTableView.layer;
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:12.0f];
    
    layer = self.itemCountLogTextView.layer;
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:12.0f];
    
    self.scanTitleCodeButton.alpha = 0.0f;
    self.scanItemCodeButton.alpha = 0.0f;
    
    // draw borders around buttons
    self.okCountButton.layer.borderWidth = 1.0f;
    self.okCountButton.layer.borderColor = [AppController sharedAppController].barColor.CGColor;
    self.okCountButton.layer.cornerRadius = 8.0f;
    
    [self.editButtonItem setTintColor:[AppController sharedAppController].barButtonColor];
    
    /*
     NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
     [UIColor blackColor],NSForegroundColorAttributeName,
     [UIColor whiteColor],NSBackgroundColorAttributeName,nil];
     
     self.navigationController.navigationBar.titleTextAttributes = textAttributes;
     */
    
    //self.activityIndicator.hidden = YES;
    
    // * * * add gestures
    
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeRecognizer];
    
    UISwipeGestureRecognizer *swipeRightRec = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeRightRec.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRightRec];
    
    UISwipeGestureRecognizer *swipeLeftRec = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeLeftRec.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeftRec];
    
    // turn on interaction for gestures
    self.locImageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    [self.locImageView addGestureRecognizer:doubleTapRecognizer];
    
    UITapGestureRecognizer *singleTapImageRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
    singleTapImageRecognizer.numberOfTapsRequired = 1;
    
    singleTapImageRecognizer.delaysTouchesBegan = YES;
    [singleTapImageRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    [self.locImageView addGestureRecognizer:singleTapImageRecognizer];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleImagePinchGesture:)];
    [self.locImageView addGestureRecognizer:pinchRecognizer];
    
    // * * * get ready
    
    /*
     self.scanItemCodeButton.layer.borderWidth = 1.0f;
     self.scanItemCodeButton.layer.borderColor = [UIColor purpleColor].CGColor;
     self.scanItemCodeButton.layer.cornerRadius = 8.0f;
     
     self.scanTitleCodeButton.layer.borderWidth = 1.0f;
     self.scanTitleCodeButton.layer.borderColor = [UIColor purpleColor].CGColor;
     self.scanTitleCodeButton.layer.cornerRadius = 8.0f;
     */
    self.itemCountAddField.delegate = self;
    self.locationTitleTextField.delegate = self;
    
    [self updateSegmentControlFont];
    
    [self.countBySegmentedControl setTitle:[NSString stringWithFormat:@"%d", countByCustom] forSegmentAtIndex:2];
    [self.countBySegmentedControl setSelectedSegmentIndex:0];
    
    [self.itemCountLogTextView setText:@""];
    
    //[locTotalCntTextField setText:[NSString stringWithFormat:@"%lu", (unsigned long)itmsTotalCnt]];
    
    self.locTotalCntBlinkTextField = [[UITextField alloc] initWithFrame:self.locTotalCntTextField.frame];
    self.locTotalCntBlinkTextField.alpha = 0.0f;
    self.locTotalCntBlinkTextField.textAlignment = NSTextAlignmentRight;
    self.locTotalCntBlinkTextField.font = self.locTotalCntTextField.font;
    self.locTotalCntBlinkTextField.userInteractionEnabled = NO;
    [self.view addSubview:self.locTotalCntBlinkTextField];
    
    //[self.itemListTableView setRowHeight:66.0f];
    self.itemCountLogTextView.alpha = 0.0f;
    
    
    // configure for detail item
    [self configureView];
    
    
    /* * * *
     * Setup launch
     */
    
    
    if (layoutMode == EditingLayout) {
        [self.locationTitleTextField becomeFirstResponder];
    }
    else if (itemsAtLoc != nil) {
        
        if (selectedDetailLabel != nil) {
            
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                [self selectItemByLabel:selectedDetailLabel showDetails:YES withScroll:UITableViewScrollPositionMiddle];
            }
            else {
                [self selectItemByLabel:selectedDetailLabel showDetails:NO withScroll:UITableViewScrollPositionTop];
            }
        }
        else if (layoutMode == NormalLayout && [AppController sharedAppController].autoSetItemInputOnLocPick) {
            [self.itemCountAddField becomeFirstResponder];
        }
    }
    else if (layoutMode == NormalLayout && [AppController sharedAppController].autoSetItemInputOnLocPick) {
        [self.itemCountAddField becomeFirstResponder];
    }
    
    //NSManagedObjectContext *moc =  [[AppController sharedAppController] managedObjectContext];
    //NSLog(@"Managed object count: %lu", (unsigned long)[moc registeredObjects].count);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    viewIsLoaded = YES;
    
    if (viewOnStartupLoad) {
        viewOnStartupLoad = NO;
        [self configureLayoutAnimated:YES completion:^(BOOL fin) {
            
            if (hasUserImage) {
                [self animateImageBounce];
            }
        }];
    }
    if (self.importStartupError != 0) {
        [self handleStartupError];
    }
    self.importStartupError = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.mySize.width <= 1.0f) {
        self.mySize = self.view.frame.size;
    }
    
    
    // set default button
    if ([AppController sharedAppController].showNegateToggle) {
        [self.negateCountToggle setEnabled:YES];
        if (self.layoutMode == NormalLayout && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
            [self.negateCountToggle setAlpha:1.0f];
        }
        else {
            [self.negateCountToggle setAlpha:0.0f];
        }
        if (self.negateCountToggle.selected) {
            [self toggleNegateCountColorsAndValues];
        }
    }
    else {
        [self.negateCountToggle setEnabled:NO];
        [self.negateCountToggle setAlpha:0.0f];
    }
    layoutIsNarrow = [self checkNeedNarrowLayoutForSize:self.mySize forTraitCollection:self.traitCollection];
    
    if (viewOnStartupLoad || self.detailItem == nil) {
        // hide the view for a fade-in
        [self configureBarButtons:NO];
        [self compactLayoutAnimated:NO forTraitCollection:self.traitCollection];
        [self updateLocationImageFrameAndShadowForTraitCollection:self.traitCollection forEnlaged:[self imageIsBig] forNarrowLayout:layoutIsNarrow];
        //[self setPhotoShadowShape];
        [self enableLayout:NO animated:NO forDuration:0.0f completion:nil];
        //[self configureLayoutAnimated:NO completion:nil];
    }
    
    // * * * *
    // start notifications
    
    [self updateFonts];
    [self updateLocale];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:@selector(keyboardDidShow:)
                   name:UIKeyboardDidShowNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(keyboardDidHide:)
                   name:UIKeyboardDidHideNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(updateFonts)
                   name:UIContentSizeCategoryDidChangeNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(updateLocale)
                   name:NSCurrentLocaleDidChangeNotification
                 object:nil];
    [center addObserver:self selector:@selector(assetsLibraryCheck) name:ALAssetsLibraryChangedNotification object:nil];
    
    [center addObserver:self
               selector:@selector(defaultsChanged:)
                   name:NSUserDefaultsDidChangeNotification
                 object:nil];
}

- (void)defaultsChanged:(NSNotification *)notification
{
    NSUserDefaults *defaults = (NSUserDefaults *)[notification object];
    BOOL negToggleVal = [defaults boolForKey:@"show_negate_toggle_preference"];
    
    [self negateToggleChangedTo:negToggleVal];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    viewIsLoaded = NO;
    
    // remove notifications
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [center removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    [center removeObserver:self name:NSCurrentLocaleDidChangeNotification object:nil];
    [center removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
    [center removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    // also happens within a rotation, but not after
    // only shows vertical changes
    
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (previousTraitCollection.verticalSizeClass != self.traitCollection.verticalSizeClass) {
        if (viewIsLoaded) {
            [self compactLayoutAnimated:NO forTraitCollection:self.traitCollection];
            [self updateLocationImageFrameAndShadowForTraitCollection:self.traitCollection forEnlaged:[self imageIsBig] forNarrowLayout:layoutIsNarrow];
        }
    }
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // note that this is called on rotations plus traitCollectionDidChange, and on switching then only traitCollectionDidChange
    // may only show vertical changes, horizontal unknown until later
    
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    // if iPad in split-view need to disable camera buttons; re-enable in normal
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (newCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
            self.isCameraAvailable = NO;
            self.isScanCodeAvailable = NO;
            [self.delegate cameraStatusUpdated];
        }
        else if (newCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            [self assetsLibraryCheck];
            [self.delegate cameraStatusUpdated];
        }
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        [self compactLayoutAnimated:NO forTraitCollection:newCollection];
        if (self.isEditing) {
            if (self.isPhotoLibAvailable) {
                if ((self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular || self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular)) {
                    self.locImageButton.alpha = self.imageEditButtonAlphaDefault;
                }
                else {
                    // prevent opening image picker in landscape per Apple Guide and smoother experience
                    self.locImageButton.alpha = 0.0f;
                }
            }
        }
        //BOOL layoutWillBeNarrow = NO;
        // horizontal class never reported during rotation, and viewWillSize doesn't help for image positioning
        // only case we care about is if iPhone 6 Plus which always rotates to narrow in our setup
        
        //[self updateLocationImageFrameAndShadowForTraitCollection:newCollection forEnlaged:NO forNarrowLayout:layoutWillBeNarrow];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
    
    
}

// replaces willRotateToInterfaceOrientation and didRotate
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // to simplify matters, we could design only for compact vs regular, but sometimes our layout fits in compact
    
    //NSLog(@"viewWill size: %f x %f", size.width, size.height);
    
    self.mySize = size;
    //NSLog(@" trans in size %f x %f done", self.mySize.width, self.mySize.height);
    BOOL wasNarrow = layoutIsNarrow;
    
    // must set flag now before anim for didTraitChange
    
    layoutIsNarrow = [self checkNeedNarrowLayoutForSize:size forTraitCollection:self.traitCollection];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        //UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        // do orientation stuff here
        self.mySize = self.view.frame.size;
        // check again for iPhone 6 Plus conditions known by now
        BOOL narrowCheck = [self checkNeedNarrowLayoutForSize:size forTraitCollection:self.traitCollection];
        
        if (narrowCheck != layoutIsNarrow) {
            if (narrowCheck) {
                [self narrowLayoutAnimated:NO];
            }
            else {
                [self wideLayoutAnimated:NO];
            }
        }
        else if (layoutIsNarrow && !wasNarrow) {
            [self narrowLayoutAnimated:NO];
            [self configureBarButtons:NO];
        }
        else if (!narrowCheck && wasNarrow) {
            [self wideLayoutAnimated:NO];
            [self configureBarButtons:NO];
        }
        if (self.isEditing) {
            [self configureBarButtons:YES];
        }
        
        
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // wrong - buttons don't work out here
        
        self.mySize = self.view.frame.size;
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateFonts
{
    if (!self.cellHeightDictionary) {
        self.cellHeightDictionary = @{UIContentSizeCategoryExtraSmall : @40,
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
    NSNumber *cellHeight = self.cellHeightDictionary[userSize];
    [self.itemListTableView setRowHeight:cellHeight.floatValue];
    [self.itemListTableView reloadData];
}

- (void)updateLocale
{
    [self updateCountsValuesForTotalItemsCount:locationTotalItemCount fromOldValue:locationTotalItemCount withBlink:NO];
    [self.itemListTableView reloadData];
}

- (void)updateSegmentControlFont
{
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
    
    if (self.negateCountToggle.selected) {
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    font, NSFontAttributeName,
                                    [UIColor redColor], NSForegroundColorAttributeName,
                                    nil];
        [self.countBySegmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
        
        
    }
    else {
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    font, NSFontAttributeName,
                                    [AppController sharedAppController].barButtonColor, NSForegroundColorAttributeName,
                                    nil];
        [self.countBySegmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    }
    NSDictionary *highAttribs = [NSDictionary dictionaryWithObjectsAndKeys:
                                 font, NSFontAttributeName,
                                 [UIColor whiteColor], NSForegroundColorAttributeName
                                 , nil];
    [self.countBySegmentedControl setTitleTextAttributes:highAttribs forState:UIControlStateHighlighted];
    
}



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)itemsListTableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)itemsListTableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return itemsAtLoc.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)itemsListTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ItemCell *cell = (ItemCell *)[itemsListTableView dequeueReusableCellWithIdentifier:@"ItemCell"];
    if (cell == nil) {
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        cell = [[ItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ItemCell"];
    }
    
    // Configure the cell...
    [cell setCellActionDelegate:self];
    
    DTCountItem *itm = [itemsAtLoc objectAtIndex:[indexPath row]];
    //NSString *inventorySummary = [NSString stringWithFormat:@"%@",
    //							  [itm valueForKey:@"label"]];
    //[[cell textLabel] setText:inventorySummary];
    DTCountInventory *inventory = [self inventoryForItemAtLocation:itm];
    
    if (inventory)
    {
        [cell setItem:itm setCount:[[inventory valueForKey:@"count"] intValue] setTotalCount:-1];
    }
    else [cell setItem:itm setCount:0 setTotalCount:-1];
    //else [[cell detailTextLabel] setText:@"0"];
    
    return cell;
}


- (void)tableView:(UITableView *)itemsListTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [self deleteItemAtLocation:(int)indexPath.row peformLog:YES];
        
        [itemsListTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }
}

- (void)tableView:(UITableView *)itemsListTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     if ([itemDetailPopoverController isPopoverVisible]) {
     [itemDetailPopoverController dismissPopoverAnimated:YES];
     }
     [itemViewController setItem:[itemsAtLoc objectAtIndex:[indexPath row]]];
     //[itemViewController setTotalCntString:@""];
     //UITableViewCell *cell = [itemsListTableView cellForRowAtIndexPath:indexPath];
     CGRect rect = CGRectInset([itemsListTableView frame], -60.0f, 0.0f);
     [itemDetailPopoverController presentPopoverFromRect:rect
     inView:[self view]
     permittedArrowDirections:UIPopoverArrowDirectionAny
     animated:YES];
     */
    //if (![countTotalPopoverController isPopoverVisible]) [self showCountTotalController:countTotalButton];
    //[countTotalViewController searchForText:[[itemsAtLoc objectAtIndex:[indexPath row]] valueForKey:@"label"]];
    cellMenuShowing = YES;
    [self.itemCountAddField resignFirstResponder];
    
    ItemCell *cell = (ItemCell *)[itemsListTableView cellForRowAtIndexPath:indexPath];
    [cell showCopyMenuWithNegate:self.negateCountToggle.selected];
    
    cellMenuShowing = NO;
    [self animateOKButtonEnabled:NO];
    
}


#pragma mark - Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (self.tipTextLabel != nil) {
        [self hideTipTextAnimated:YES];
    }
    
    [self checkPopoversToDismiss];
    
    [self.itemListTableView setEditing:editing animated:animated];
    
    // do not do configureLayout; configure edit transitions here
    
    if (self.view.isHidden == NO) {
        
        self.itemCountAddField.enabled = !editing;
        //self.locationTitleTextField.enabled = editing;
        
        if (animated) {
            [UIView animateWithDuration:0.33f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [self controlsAlphaForEditing:editing];
                             }
                             completion:nil];
        }
        else {
            [self controlsAlphaForEditing:editing];
        }
        if (editing && self.locationTitleTextField.text.length == 0) {
            [self.locationTitleTextField becomeFirstResponder];
        }
    }
    if (editing) {
        layoutMode = EditingLayout;
        
        if ([self imageIsBig]) {
            [self animateImageZoom];
        }
        
        [self locImageHidden:NO animated:animated];
        
        if (self.isFirstLocation && !tipLocationViewed && ![AppController sharedAppController].userHasSeenStartupTip) {
            
            NSString *tip = NSLocalizedString(@"firstLocationTip", @"Divide your area into small, manageable, locations (shelf-1, bin1).");
            CGRect rect = [self tipViewFrameForTextLenght:tip.length withYOffest:-16.0f];
            
            if (self.isScanCodeAvailable) {
                tip = [tip stringByAppendingString:[NSString stringWithFormat:@" %@",NSLocalizedString(@"firstLocationTip2", @"If your location has a QR code, you may scan it.")]];
            }
            if ([self displayTipText:tip withRect:rect animated:YES]) {
                tipLocationViewed = YES;
            }
        }
    }
    else {
        layoutMode = NormalLayout;
        [self saveLocationDetails];
        
        [self locImageHidden:layoutIsNarrow animated:animated];
        
        if (self.isFirstLocation && !tipUPCViewed && itemsAtLoc.count == 0  && ![AppController sharedAppController].userHasSeenStartupTip) {
            
            NSString *tipText = NSLocalizedString(@"firstItemEntryTip", @"Select a count-by value and enter your item ID optionally by scanning a bar code.");
            CGRect rect = [self tipViewFrameForTextLenght:tipText.length withYOffest:0.0f];
            [self animateCountBySegment];
            
            if ([self displayTipText:tipText withRect:rect animated:YES]) {
                tipUPCViewed = YES;
                [[AppController sharedAppController] updateHAsSeenStartupTips:YES];
            }
        }
        if ([AppController sharedAppController].autoSetItemInputOnLocPick) {
            [self.itemCountAddField becomeFirstResponder];
        }
    }
    
    [self configureBarButtons:animated];
}

#pragma mark - Layout
#pragma mark - layout animations

- (void)animateCountBySegment
{
    if (self.countBySegmentedControl.alpha < 0.1f) {
        return;
    }
    //CGRect origFrame = self.countBySegmentedControl.frame;
    //CGRect miniFrame = CGRectMake(origFrame.origin.x + 8.0f, origFrame.origin.y + 8.0f, origFrame.size.width - 16.0f, origFrame.size.height - 16.0f);
    [UIView animateWithDuration:0.40f
                          delay:0.85f
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.countBySegmentedControl.alpha = 0.20f;
                         //self.countBySegmentedControl.frame = miniFrame;
                     }
                     completion:^(BOOL finished){
                         //[self.countBySegmentedControl setSelectedSegmentIndex:1];
                         [UIView animateWithDuration:0.3333f
                                               delay:0.25f
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              self.countBySegmentedControl.alpha = 1.0f;
                                              //self.countBySegmentedControl.frame = origFrame;
                                              
                                          }
                                          completion:^(BOOL finished){
                                              //[self.countBySegmentedControl setSelectedSegmentIndex:0];
                                          }];
                     }];
}

- (void)animateTableAndLogBounceInDirection:(UISwipeGestureRecognizerDirection)direction
{
    CGRect tableFrame = self.itemListTableView.frame;
    CGRect logFrame = self.itemCountLogTextView.frame;
    CGFloat offset = -48.0f;
    if (direction == UISwipeGestureRecognizerDirectionRight) {
        offset = 48.0f;
    }
    CGRect targetTableFrame = CGRectMake(tableFrame.origin.x + offset, tableFrame.origin.y, tableFrame.size.width, tableFrame.size.height);
    CGRect targetLogFrame = CGRectMake(logFrame.origin.x + offset, logFrame.origin.y, logFrame.size.width, logFrame.size.height);
    
    [UIView animateWithDuration:0.21f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.itemListTableView.frame = targetTableFrame;
                         self.itemCountLogTextView.frame = targetLogFrame;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.12f
                                               delay:0.0667f
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.itemListTableView.frame = tableFrame;
                                              self.itemCountLogTextView.frame = logFrame;
                                          }
                                          completion:nil];
                     }];
    
}

- (void)animateImageBounce
{
    CGRect imageRect = self.locImageView.bounds;
    CGRect shadowRect = self.shadowImageView.bounds;
    CGFloat adjustStep = 6.0f;
    CGFloat adjustStep2 = 10.0f;
    
    CGRect imageBulgeRect = CGRectMake(imageRect.origin.x - adjustStep,
                                       imageRect.origin.y - adjustStep,
                                       imageRect.size.width + adjustStep2,
                                       imageRect.size.height + adjustStep2);
    CGRect shadowBultRect = CGRectMake(shadowRect.origin.x - adjustStep,
                                       shadowRect.origin.y - adjustStep,
                                       shadowRect.size.width + adjustStep2,
                                       shadowRect.size.height + adjustStep2);
    
    [UIView animateWithDuration:0.30f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.locImageView setBounds:imageBulgeRect];
                         [self.shadowImageView setBounds:shadowBultRect];
                         
                     }
                     completion:^(BOOL fin) {
                         [self animateImageBounceToRect:imageRect withShadowRect:shadowRect];
                     }];
}

-(void)animateImageBounceToRect:(CGRect)rect withShadowRect:(CGRect)shadowRect
{
    [UIView animateWithDuration:0.16f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self.locImageView setBounds:rect];
                         [self.shadowImageView setBounds:shadowRect];
                     }
                     completion:nil
     ];
}

/**
 *  toggle decision for large / small loc photo image
 */
- (void)animateImageZoom
{
    BOOL enlarge = YES;
    BOOL isNewImage = NO;
    //CGFloat otherCompsAlpha = 0.50f;
    
    UIImage *imageToDisplay = nil;
    if ([self imageIsBig]) {
        enlarge = NO;
        imageToDisplay = self.locImageView.image;
        //otherCompsAlpha = 1.0f;
    }
    else {
        
        DTCountLocation *loc = (DTCountLocation *)self.detailItem;
        NSString *imageKey = [loc valueForKey:@"picuuid"];
        
        if (imageKey) {
            imageToDisplay = [[ImageCache sharedImageCache] imageForKey:imageKey];
            if (imageToDisplay == nil || imageToDisplay.size.width <= 0) {
                hasUserImage = NO;
                [loc setValue:nil forKey:@"picuuid"];
                [loc setPicture:nil];
                imageToDisplay = self.defaultLocationImage;
                isNewImage = YES;
            }
        }
        else {
            imageToDisplay = self.defaultLocationImage;
            isNewImage = YES;
        }
    }
    [self updateLocationImage:imageToDisplay isNewImage:isNewImage isZoomEnlarged:enlarge animated:YES withDuration:0.3333f includeBounce:NO];
}

- (void)locImageHidden:(BOOL)hidden animated:(BOOL)animated
{
    CGFloat photoAlpha = 1.0f;
    CGFloat buttonAlpha = 0.0f;
    CGFloat delay = 0.667f;
    //self.shadowImageLayer.opacity = 0.0f;
    if (hidden) {
        photoAlpha = 0.0f;
        delay = 0.0f;
    }
    else if (self.isEditing) {
        // only allow selecting photos in portrait, iPad all, or phone-plus all
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular || self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
            buttonAlpha = self.imageEditButtonAlphaDefault;
        }
        
    }
    
    if (animated) {
        [UIView animateWithDuration:0.50f
                              delay:delay
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.locImageView.alpha = photoAlpha;
                             self.shadowImageView.alpha = photoAlpha;
                             if (self.isPhotoLibAvailable) {
                                 self.locImageButton.alpha = buttonAlpha;
                             }
                         }
                         completion:^(BOOL finished){
                             if (self.tipTextLabel) {
                                 [self.tipTextLabel.layer setZPosition:1.0f];
                             }
                             
                         }];
    }
    else {
        self.locImageView.alpha = photoAlpha;
        self.shadowImageView.alpha = photoAlpha;
        if (self.isPhotoLibAvailable) {
            self.locImageButton.alpha = buttonAlpha;
        }
        //self.shadowImageLayer.opacity = opacity;
    }
    
}

- (void)animateOKButtonEnabled:(BOOL)enabled
{
    CGFloat alpha = 0.0f;
    if (enabled) {
        alpha = 1.0f;
    }
    if (alpha == self.okCountButton.alpha) {
        return;
    }
    [UIView animateWithDuration:0.3333f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.okCountButton.alpha = alpha;
                     }
                     completion:nil];
}

- (void)animateLogFadeVisible:(BOOL)visible
{
    CGFloat alpha = self.logAlphaDefault;
    if (!visible) {
        alpha = 0.0f;
    }
    [UIView animateWithDuration:0.667f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.itemCountLogTextView.alpha = alpha;
                     }
                     completion:nil];
}

/**
 *  swaps blink and normal. set blink text field beforehand
 */
- (void)animateTotalCountTextFieldToValue:(NSString *)valStr withBlinkColor:(UIColor *)color
{
    self.locTotalCntBlinkTextField.text = valStr;
    self.locTotalCntBlinkTextField.textColor = color;
    self.locTotalCntBlinkTextField.frame = self.locTotalCntTextField.frame;
    
    if (self.locTotalCntTextField.alpha <= 0.1f) {
        // not showing, skip blink
        self.locTotalCntTextField.text = valStr;
        return;
    }
    
    [UIView animateWithDuration:0.16f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.locTotalCntBlinkTextField.alpha = 1.0f;
                         self.locTotalCntTextField.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.locTotalCntTextField.text = valStr;
                         [UIView animateWithDuration:0.16f
                                               delay:0.3333f
                                             options:UIViewAnimationOptionCurveLinear
                                          animations:^{
                                              self.locTotalCntTextField.alpha = 1.0f;
                                              self.locTotalCntBlinkTextField.alpha = 0.0f;
                                          }
                                          completion:^(BOOL finished) {
                                              
                                          }];
                     }];
}

- (BOOL)displayTipText:(NSString *)text withRect:(CGRect)rect animated:(BOOL)animated
{
    if (self.tipTextLabel) {
        return NO;
    }
    self.tipTextLabel = [[UILabel alloc] initWithFrame:rect];
    self.tipTextLabel.numberOfLines = 0;
    self.tipTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.tipTextLabel.textAlignment = NSTextAlignmentCenter;
    self.tipTextLabel.textColor = [UIColor grayColor];
    self.tipTextLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    self.tipTextLabel.backgroundColor = [UIColor colorWithRed:0.953f green:0.976f blue:0.353f alpha:0.9f];
    self.tipTextLabel.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTipTapGesture:)];
    tapRecognizer.numberOfTapsRequired = 1;
    [self.tipTextLabel addGestureRecognizer:tapRecognizer];

    
    [self.view addSubview:self.tipTextLabel];
    self.tipTextLabel.alpha = 0.0f;
    CALayer *layer = self.tipTextLabel.layer;
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:12.0f];
    
    self.tipTextLabel.text = text;
    
    
    if (animated) {
        [UIView animateWithDuration:0.72f
                              delay:0.2f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.tipTextLabel.alpha = 0.92f;
                         }
                         completion:nil];
    }
    else {
        self.tipTextLabel.alpha = 0.92f;
    }
    return YES;
}

- (void)hideTipTextAnimated:(BOOL)animated
{
    if (self.tipTextLabel == nil) {
        return;
    }
    if (animated) {
        [UIView animateWithDuration:0.367f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.tipTextLabel.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             self.tipTextLabel = nil;
                         }];
    }
    else {
        self.tipTextLabel.alpha = 0.0f;
        self.tipTextLabel = nil;
    }
}

#pragma mark - layout updates

- (BOOL)checkNeedNarrowLayoutForSize:(CGSize)size forTraitCollection:(UITraitCollection *)traitCollection
{
    BOOL regularByRegular = NO;
    BOOL isPlusSizedLandscape = NO;
    
    // note that trait collections may not report horizontal
    
    if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        // check this with future devices - assumption: everything should always fit in full regular;
        // check other changes in trait transition
        regularByRegular = YES;
    }
    else if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        isPlusSizedLandscape = YES;
    }
    else if (self.isPlusPhone && traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        isPlusSizedLandscape = YES;
    }
    
    CGFloat width = size.width;
    
    if (width < displayNarrowWidthLimit && regularByRegular) {
        // let's assume splitter will collapse - note that mode-change delegate not called for trait changes
        width += 180.0f;   // small buffer
    }
    else if (isPlusSizedLandscape && self.splitViewController.displayMode == UISplitViewControllerDisplayModeAllVisible) {
        width -= 280.0f;
    }
    
    if (width < displayNarrowWidthLimit && regularByRegular == NO) {
        return YES;
    }
    return NO;
}


/**
 *  do not call from setEditing or rotations -
 *   configures based on layoutMode (sets layoutIsNarrow flag) and calls enableLayout
 */
- (void)configureLayoutAnimated:(BOOL)animated completion:(configureLayoutCompletion) completeBlock
{
    layoutIsNarrow = [self checkNeedNarrowLayoutForSize:self.mySize forTraitCollection:self.traitCollection];
    
    CGFloat itemListWidth = 294.0f;
    
    if (self.navigationController.navigationBar.frame.size.width > 696.0f) {
        itemListWidth = 356.0f;
    }
    
    self.locTotalWidthConstraint.constant += itemListWidth - self.itemListWidthConstraint.constant;
    self.locTotalCntTextField.frame = CGRectMake(self.locTotalCntTextField.frame.origin.x,
                                                 self.locTotalCntTextField.frame.origin.y,
                                                 self.locTotalWidthConstraint.constant,
                                                 self.locTotalCntTextField.frame.size.height);
     
    self.itemListWidthConstraint.constant = itemListWidth;
    
    [self setMyTitle];
    
    switch (layoutMode) {
        case NormalLayout: {
            self.locationTitleTextField.alpha = 0.0f;
            
            self.progressView.alpha = 0.0f;
            [self enableLayout:YES animated:animated forDuration:0.333f completion:^(BOOL fin) {
                if (completeBlock) {
                    completeBlock(fin);
                }
                else {
                    [self.activityIndicator stopAnimating];
                }
            }];
            
            break;
        }
        case EditingLayout: {
            if (!self.isEditing) {
                // need to call -
                [self enableLayout:YES animated:NO forDuration:0.0f completion:^(BOOL fin) {
                    [self setEditing:YES animated:animated];
                    if (completeBlock) {
                        completeBlock(fin);
                    }
                }];
            }
            else {
                [self enableLayout:YES animated:NO forDuration:0.0f completion:^(BOOL fin) {
                    [self controlsAlphaForEditing:self.isEditing];
                    if (completeBlock) {
                        completeBlock(fin);
                    }
                }];
            }
            break;
        }
        case ImportLayout: {
            
            [self enableLayout:NO animated:animated forDuration:0.333f completion:^(BOOL fin) {
                [self.activityIndicator setHidden:NO];
                self.activityIndicator.alpha = 1.0f;
                //[self.activityIndicator setHidesWhenStopped:YES];
                [self.activityIndicator startAnimating];
                self.progressView.alpha = 1.0f;
                self.importTextView.alpha = 1.0f;
                [self.importTextView setText:NSLocalizedString(@"ImportDetailMessage", @"Importing descriptions and item quantities for comparison. This will not replace your counts.")];
                if (completeBlock) {
                    completeBlock(fin);
                }
            }];
            
            break;
        }
        case UpdateDataLayout: {
            [self enableLayout:NO animated:animated forDuration:0.33f completion:^(BOOL fin) {
                [self.activityIndicator setHidden:NO];
                self.activityIndicator.alpha = 1.0f;
                //[self.activityIndicator setHidesWhenStopped:YES];
                [self.activityIndicator startAnimating];
                self.progressView.alpha = 1.0f;
                self.importTextView.alpha = 1.0f;
                [self.importTextView setText:NSLocalizedString(@"UpdateDetailMessage", @"Updating your data. Please wait.")];
                if (completeBlock) {
                    completeBlock(fin);
                }
            }];
            
            break;
        }
        case LoadingLayout: {
            [self enableLayout:NO animated:animated forDuration:0.33f completion:^(BOOL fin) {
                [self.activityIndicator setHidden:NO];
                self.activityIndicator.alpha = 1.0f;
                //[self.activityIndicator setHidesWhenStopped:YES];
                [self.activityIndicator startAnimating];
                //self.progressView.alpha = 1.0f;
                self.importTextView.alpha = 0.0f;
                if (completeBlock) {
                    completeBlock(fin);
                }
            }];
            
            break;
        }
        default:
            break;
    }
}


- (void)setMyTitle
{
    if (layoutMode == LoadingLayout) {
        [self.navigationItem setTitle:NSLocalizedString(@"Loading", @"Loading")];
    }
    else if (layoutMode == ImportLayout) {
        [self.navigationItem setTitle:NSLocalizedString(@"Importing", @"Importing")];
    }
    else if (layoutMode == UpdateDataLayout) {
        [self.navigationItem setTitle:NSLocalizedString(@"Updating", @"Updating")];
    }
    else if (self.detailItem) {
        DTCountLocation *loc = (DTCountLocation *)self.detailItem;
        NSString *locLabel = [loc valueForKey:@"label"];
        [self updateTitle:locLabel];
    }
    else {
        self.navigationItem.title = @"No Location";
    }
}



/**
 *  only for trait changes
 *  height limited in space, hide unecessaries for compact layout
 *  also calls barbuttons
 */
- (void)compactLayoutAnimated:(BOOL)animated forTraitCollection:(UITraitCollection *)traitCollection
{
    CGRect addBoxRect;
    CGRect totalRect;
    CGRect tableRect;
    CGRect okRect;
    CGRect logRect;
    CGRect scanCodeButtonRect;
    CGFloat addFieldConstraintTopSpace;
    CGFloat alphaOptionalCompact = 0.0f;
    CGRect locTextFieldRect;
    CGFloat locTitleTopSpace;
    CGFloat logTopToTableDiff = -67.0f;
    CGFloat logY = self.itemListTableView.frame.origin.y + logTopToTableDiff;
    
    if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        
        addBoxRect = CGRectMake(self.itemCountAddField.frame.origin.x,
                                self.countBySegmentedControl.frame.origin.y - 14.0f,
                                self.itemCountAddField.frame.size.width,
                                self.itemCountAddField.frame.size.height);
        totalRect = CGRectMake(self.locTotalCntTextField.frame.origin.x,
                               addBoxRect.origin.y + addBoxRect.size.height + 4.0f,
                               self.locTotalCntTextField.frame.size.width,
                               self.locTotalCntTextField.frame.size.height);
        tableRect = CGRectMake(self.itemListTableView.frame.origin.x,
                               totalRect.origin.y + totalRect.size.height + 14.0f,
                               self.itemListTableView.frame.size.width,
                               self.itemListTableView.frame.size.height);
        okRect = CGRectMake(self.okCountButton.frame.origin.x,
                            addBoxRect.origin.y,
                            self.okCountButton.frame.size.width,
                            self.okCountButton.frame.size.height);
        
        addFieldConstraintTopSpace = -36.0f;
        scanCodeButtonRect = self.negateCountToggle.frame;
        
        locTextFieldRect = CGRectMake(self.locationTitleTextField.frame.origin.x,
                                      72.0f,
                                      self.locationTitleTextField.frame.size.width,
                                      self.locationTitleTextField.frame.size.height);
        
        locTitleTopSpace = 8.0f;
        if (layoutIsNarrow) {
            logY = self.itemListTableView.frame.origin.y;
            logTopToTableDiff = 0.0f;
        }
    }
    else {
        if (layoutIsNarrow)
        {
            
            // need to miss the image
            locTextFieldRect = CGRectMake(self.locationTitleTextField.frame.origin.x,
                                          72.0f,
                                          self.locationTitleTextField.frame.size.width,
                                          self.locationTitleTextField.frame.size.height);
            locTitleTopSpace = 8.0f;
            logTopToTableDiff = 0.0f;
            logY = self.itemListTableView.frame.origin.y;
            
        }
        else {
            locTextFieldRect = CGRectMake(12.0f, 97.0f,
                                          self.locationTitleTextField.frame.size.width,
                                          self.locationTitleTextField.frame.size.height);
            locTitleTopSpace = 33.0f;
        }
        
        addBoxRect = CGRectMake(self.itemCountAddField.frame.origin.x,
                                126.0f,
                                self.itemCountAddField.frame.size.width,
                                self.itemCountAddField.frame.size.height);
        totalRect = CGRectMake(self.locTotalCntTextField.frame.origin.x,
                               164.0f,
                               self.locTotalCntTextField.frame.size.width,
                               self.locTotalCntTextField.frame.size.height);
        tableRect = CGRectMake(self.itemListTableView.frame.origin.x,
                               236.0f,
                               self.itemListTableView.frame.size.width,
                               self.itemListTableView.frame.size.height);
        okRect = CGRectMake(self.okCountButton.frame.origin.x,
                            addBoxRect.origin.y,
                            self.okCountButton.frame.size.width,
                            self.okCountButton.frame.size.height);
        
        addFieldConstraintTopSpace = 8.0f;
        alphaOptionalCompact = 1.0f;
        scanCodeButtonRect = CGRectMake(addBoxRect.origin.x - 47.0f, addBoxRect.origin.y - 1.0f, self.scanItemCodeButton.frame.size.width, self.scanItemCodeButton.frame.size.height);
        
    }
    if (layoutMode != NormalLayout) {
        alphaOptionalCompact = 0.0f;
    }
    
    logRect = CGRectMake(self.itemCountLogTextView.frame.origin.x,
                         logY,
                         self.itemCountLogTextView.frame.size.width,
                         self.itemCountLogTextView.frame.size.height);
    
    CGRect locScanButtonRect = CGRectMake(self.scanTitleCodeButton.frame.origin.x,
                                          locTextFieldRect.origin.y - 1.0f,
                                          self.scanTitleCodeButton.frame.size.width,
                                          self.scanTitleCodeButton.frame.size.height);
    
    if (animated) {
        [UIView animateWithDuration:0.50f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             if (layoutMode == NormalLayout) {
                                 if ([AppController sharedAppController].showNegateToggle) {
                                     self.negateCountToggle.alpha = alphaOptionalCompact;
                                 }
                                 self.countBySegmentedControl.alpha = alphaOptionalCompact;
                                 self.segmentPointImage.alpha = alphaOptionalCompact;
                             }
                             self.itemCountAddField.frame = addBoxRect;
                             self.locTotalCntTextField.frame = totalRect;
                             self.locTotalCntBlinkTextField.frame = totalRect;
                             self.itemListTableView.frame = tableRect;
                             self.itemCountLogTextView.frame = logRect;
                             self.itemLogTopAlignToTableConstraint.constant = logTopToTableDiff;
                             self.scanItemCodeButton.frame = scanCodeButtonRect;
                             self.okCountButton.frame = okRect;
                             [self.itemCountAddFieldConstrantTopSpace setConstant:addFieldConstraintTopSpace];
                             [self.locationTitleTextField setFrame:locTextFieldRect];
                             [self.locationTitleConstraintVertSpace setConstant:locTitleTopSpace];
                             [self.scanTitleCodeButton setFrame:locScanButtonRect];
                             if (self.tipTextLabel != nil) {
                                 self.tipTextLabel.frame = [self tipViewFrameForTextLenght:self.tipTextLabel.text.length withYOffest:0.0f];
                             }
                             [self configureBarButtons:NO];
                         }
                         completion:^(BOOL fin){
                             
                         }];
    }
    else {
        if (layoutMode == NormalLayout) {
            if ([AppController sharedAppController].showNegateToggle) {
                self.negateCountToggle.alpha = alphaOptionalCompact;
            }
            self.countBySegmentedControl.alpha = alphaOptionalCompact;
            self.segmentPointImage.alpha = alphaOptionalCompact;
        }
        self.itemCountAddField.frame = addBoxRect;
        self.locTotalCntTextField.frame = totalRect;
        self.locTotalCntBlinkTextField.frame = totalRect;
        self.itemListTableView.frame = tableRect;
        self.itemCountLogTextView.frame = logRect;
        self.itemLogTopAlignToTableConstraint.constant = logTopToTableDiff;
        self.scanItemCodeButton.frame = scanCodeButtonRect;
        self.okCountButton.frame = okRect;
        [self.itemCountAddFieldConstrantTopSpace setConstant:addFieldConstraintTopSpace];
        [self.locationTitleConstraintVertSpace setConstant:locTitleTopSpace];
        [self.locationTitleTextField setFrame:locTextFieldRect];
        [self.scanTitleCodeButton setFrame:locScanButtonRect];
        if (self.tipTextLabel != nil) {
            self.tipTextLabel.frame = [self tipViewFrameForTextLenght:self.tipTextLabel.text.length withYOffest:0.0f];
        }
        [self configureBarButtons:animated];
    }
    
}

/**
 *  for when there isn't enough width for everything
 *  regardless of compact trait
 */
- (void)narrowLayoutAnimated:(BOOL)animated
{
    layoutIsNarrow = YES;

    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.view.bounds.size.width <= 320.0f && self.isScanCodeAvailable) {
        self.isCameraAvailable = NO;
        self.isScanCodeAvailable = NO;
        
        [self.delegate cameraStatusUpdated];
    }
    
    if (self.isCameraAvailable == NO) {
        self.scanItemCodeButton.alpha = 0.0f;
        self.scanTitleCodeButton.alpha = 0.0f;
    }
    CGFloat logAlpha = 0.0f;
    CGFloat itemsListAlpha = 1.0f;
    CGFloat logTopToTableDiff = 0.0f;
    CGRect logFrame = CGRectMake(self.itemCountLogTextView.frame.origin.x,
                                 self.itemListTableView.frame.origin.y,
                                 self.itemCountLogTextView.frame.size.width,
                                 self.itemCountLogTextView.frame.size.height + 67.0f);
    
    if (self.isEditing) {
        itemsListAlpha = 0.0f;
    }
    else {
        [self locImageHidden:YES animated:animated];
        if (displayLog) {
            logAlpha = self.logAlphaDefault;
            itemsListAlpha = 0.0f;
        }
    }
    
    
    if (animated) {
        [UIView animateWithDuration:0.50f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.itemCountLogTextView.alpha = logAlpha;
                             self.itemListTableView.alpha = itemsListAlpha;
                             self.locTotalCntTextField.alpha = itemsListAlpha;
                             self.itemCountLogTextView.frame = logFrame;
                             self.itemLogTopAlignToTableConstraint.constant = logTopToTableDiff;
                             
                             [self updateLocationImageFrameAndShadowForTraitCollection:self.traitCollection forEnlaged:NO forNarrowLayout:layoutIsNarrow];
                             
                             
                         }
                         completion:^(BOOL fin){
                             //[self setPhotoShadowShape];
                             [self configureBarButtons:animated];
                             self.itemCountLogTextView.alpha = logAlpha;
                             self.itemListTableView.alpha = itemsListAlpha;
                             self.locTotalCntTextField.alpha = itemsListAlpha;
                         }];
    }
    else {
        self.itemCountLogTextView.alpha = logAlpha;
        self.itemListTableView.alpha = itemsListAlpha;
        self.locTotalCntTextField.alpha = itemsListAlpha;
        self.itemCountLogTextView.frame = logFrame;
        self.itemLogTopAlignToTableConstraint.constant = logTopToTableDiff;
        
        [self updateLocationImageFrameAndShadowForTraitCollection:self.traitCollection forEnlaged:NO forNarrowLayout:layoutIsNarrow];
        
        
        //[self setPhotoShadowShape];
        [self configureBarButtons:animated];
    }
}

/**
 *  there's enough width to display all
 *  regardless of compact/full trait
 */
- (void)wideLayoutAnimated:(BOOL)animated
{
    layoutIsNarrow = NO;

    if (self.isScanCodeAvailable == NO && self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        // do we need to turn back on?
        [self assetsLibraryCheck];
        [self.delegate cameraStatusUpdated];
    }
    
    CGFloat logAlpha = self.logAlphaDefault;
    CGFloat scanItemAlpha = 0.0f;
    CGFloat scanTitleAlpha = 0.0f;
    CGFloat logTopToTableDiff = -67.0f;
    CGRect logFrame = CGRectMake(self.itemCountLogTextView.frame.origin.x,
                                 self.itemListTableView.frame.origin.y + logTopToTableDiff,
                                 self.itemCountLogTextView.frame.size.width,
                                 self.itemCountLogTextView.frame.size.height + logTopToTableDiff);
    
    if (self.isEditing) {
        logAlpha = 0.0f;
        if (self.isScanCodeAvailable) {
            scanTitleAlpha = 1.0f;
        }
    }
    else {
        [self locImageHidden:NO animated:animated];
        if (self.isScanCodeAvailable) {
            scanItemAlpha = 1.0f;
        }
    }
    if (animated) {
        [UIView animateWithDuration:0.50f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             if (self.itemCountLogTextView.text.length > 0) {
                                 self.itemCountLogTextView.alpha = logAlpha;
                             }
                             self.itemListTableView.alpha = 1.0f;
                             self.locTotalCntTextField.alpha = 1.0f;
                             self.itemCountLogTextView.frame = logFrame;
                             self.itemLogTopAlignToTableConstraint.constant = logTopToTableDiff;
                             self.scanTitleCodeButton.alpha = scanTitleAlpha;
                             self.scanItemCodeButton.alpha = scanItemAlpha;
                             [self updateLocationImageFrameAndShadowForTraitCollection:self.traitCollection forEnlaged:NO forNarrowLayout:layoutIsNarrow];
                         }
                         completion:^(BOOL fin){
                             
                             [self configureBarButtons:animated];
                             
                         }];
    }
    else {
        if (self.itemCountLogTextView.text.length > 0) {
            self.itemCountLogTextView.alpha = logAlpha;
            self.itemListTableView.alpha = 1.0f;
            self.locTotalCntTextField.alpha = 1.0f;
            self.itemCountLogTextView.frame = logFrame;
            self.itemLogTopAlignToTableConstraint.constant = logTopToTableDiff;
            [self updateLocationImageFrameAndShadowForTraitCollection:self.traitCollection forEnlaged:NO forNarrowLayout:layoutIsNarrow];
             [self configureBarButtons:animated];

        }
        self.scanTitleCodeButton.alpha = scanTitleAlpha;
        self.scanItemCodeButton.alpha = scanItemAlpha;
    }
}

/**
 *  for switching when overlapped (iPhone) on toggle
 */
- (void)toggleItemListLogSwitchAnimated:(BOOL)animated
{
    displayLog = !displayLog;
    NSString *title = NSLocalizedString(@"Counts", @"Counts");
    CGRect listFrame = self.itemListTableView.frame;
    CGRect logFrame = self.itemCountLogTextView.frame;
    CGRect totalNumFrame = self.locTotalCntTextField.frame;
    CGRect listAltFrame = CGRectMake(listFrame.origin.x - 300.0f, listFrame.origin.y, listFrame.size.width, listFrame.size.height);
    CGRect logAltFrame = CGRectMake(logFrame.origin.x + 300.0f, logFrame.origin.y, logFrame.size.width, logFrame.size.height);
    CGRect totalNumAltFrame = CGRectMake(totalNumFrame.origin.x - 200.0f, totalNumFrame.origin.y, totalNumFrame.size.width, totalNumFrame.size.height);
    CGFloat logAlpha = self.logAlphaDefault;
    CGFloat listAlpha = 0.0f;
    CGFloat totalNumAlpha = 0.0f;
    
    if (!displayLog) {
        logAlpha = 0.0f;
        listAlpha = 1.0f;
        totalNumAlpha = 1.0f;
        title = NSLocalizedString(@"Log", @"Log");
        self.itemListTableView.frame = listAltFrame;
        self.locTotalCntTextField.frame = totalNumAltFrame;
    }
    else {
        self.itemCountLogTextView.frame = logAltFrame;
    }
    if (animated) {
        [UIView animateWithDuration:0.32f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             
                             if (displayLog) {
                                 self.itemListTableView.frame = listAltFrame;
                                 self.locTotalCntTextField.frame = totalNumAltFrame;
                                 self.itemCountLogTextView.frame = logFrame;
                             }
                             else {
                                 self.itemListTableView.frame = listFrame;
                                 self.locTotalCntTextField.frame = totalNumFrame;
                                 self.itemCountLogTextView.frame = logAltFrame;
                             }
                             self.itemCountLogTextView.alpha = logAlpha;
                             self.itemListTableView.alpha = listAlpha;
                             self.locTotalCntTextField.alpha = totalNumAlpha;
                         }
                         completion:^(BOOL finished) {
                             [self.logToggleButton setTitle:title];
                             self.itemCountLogTextView.frame = logFrame;
                             self.itemListTableView.frame = listFrame;
                             self.locTotalCntTextField.frame = totalNumFrame;
                             self.itemCountLogTextView.alpha = logAlpha;
                             self.itemListTableView.alpha = listAlpha;
                             self.locTotalCntTextField.alpha = totalNumAlpha;
                         }];
    }
    else {
        self.itemCountLogTextView.alpha = logAlpha;
        self.itemListTableView.alpha = listAlpha;
        self.locTotalCntTextField.alpha = totalNumAlpha;
        [self.logToggleButton setTitle:title];
    }
    
}

/**
 * call before other layout changes - careful to call in correct order
 */
- (void)enableLayout:(BOOL)enabled animated:(BOOL)animated forDuration:(CGFloat)duration completion:(myEnableCompletion) completeBlock
{
    self.editButtonItem.enabled = enabled;

    CGFloat alpha = 1.0f;
    CGFloat okButtonAlpha = 0.0f;
    CGFloat negateCountAlpha = 0.0f;
    CGFloat countBySegAlpha = 0.0f;
    CGFloat loadingCtlsAlpha = 0.0f;
    CGFloat importCtlsAlpha = 0.0f;
    //CGFloat imageAlpha = 1.0f;
    BOOL showImage = YES;
    CGFloat logAlpha = 0.5f;
    CGFloat itemsListAlpha = 1.0f;
    if (enabled) duration = 0.75f;
    
    self.deleteLocationButton.enabled = enabled;
    self.countTotalButton.enabled = enabled;
    self.toolsButton.enabled = enabled;
    self.actionButton.enabled = enabled;
    
    
    if (enabled) {
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
            if ([AppController sharedAppController].showNegateToggle) {
                negateCountAlpha = 1.0f;
            }
            countBySegAlpha = 1.0f;
        }
        [self.activityIndicator stopAnimating];
        
        if (itemsTotalList == nil) {
            self.countTotalButton.enabled = NO;
            self.toolsButton.enabled = NO;
        }
        if (self.itemCountLogTextView.text.length == 0) {
            logAlpha = 0.0f;
        }
        if (layoutIsNarrow) {
            if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.view.bounds.size.width <= 320.0f) {
                NSLog(@" compact");
                self.isCameraAvailable = NO;
                self.isScanCodeAvailable = NO;
            }
            if (layoutMode == EditingLayout) {
                itemsListAlpha = 0.0f;
                logAlpha = 0.0f;
                //if (self.locationTitleTextField.text.length == 0) {
                //    showImage = NO;
                //}
            }
            else {
                //imageAlpha = 0.0f;
                
                showImage = NO;
                if (displayLog) {
                    itemsListAlpha = 0.0f;
                }
                else logAlpha = 0.0f;
            }
        }
    }
    else {
        // not enabled - set alphas
        alpha = 0.0f;
        countBySegAlpha = 0.0f;
        negateCountAlpha = 0.0f;
        //imageAlpha = 0.0f;
        showImage = NO;
        logAlpha = 0.0f;
        itemsListAlpha = 0.0f;
        if (layoutMode == ImportLayout) {
            loadingCtlsAlpha = 1.0f;
            importCtlsAlpha = 1.0f;
        }
        else if (layoutMode == LoadingLayout) {
            loadingCtlsAlpha = 1.0f;
        }
    }
    
    if (animated) {
        [UIView animateWithDuration:duration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.okCountButton.alpha = okButtonAlpha;
                             self.negateCountToggle.alpha = negateCountAlpha;
                             [self setPrimaryControlsAlpha:alpha];
                             self.toolBar.alpha = alpha;
                             self.importTextView.alpha = importCtlsAlpha;
                             self.countBySegmentedControl.alpha = countBySegAlpha;
                             self.segmentPointImage.alpha = countBySegAlpha;
                             self.activityIndicator.alpha = loadingCtlsAlpha;
                             self.progressView.alpha = importCtlsAlpha;
                             self.itemCountLogTextView.alpha = logAlpha;
                             self.itemListTableView.alpha = itemsListAlpha;
                             self.locTotalCntTextField.alpha = itemsListAlpha;
                             
                             [self locImageHidden:!showImage animated:NO];
                         }
                         completion:^(BOOL finished) {
                             if (selectedDetailLabel != nil && selectedDetailLabel.length > 0) {
                                 [self selectItemByLabel:selectedDetailLabel
                                             showDetails:[[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad
                                              withScroll:UITableViewScrollPositionMiddle];
                             }
                             
                             if (completeBlock) {
                                 completeBlock(finished);
                             }
                         }];
    }
    else {
        self.okCountButton.alpha = okButtonAlpha;
        self.negateCountToggle.alpha = negateCountAlpha;
        [self setPrimaryControlsAlpha:alpha];
        self.toolBar.alpha = alpha;
        self.importTextView.alpha = importCtlsAlpha;
        self.countBySegmentedControl.alpha = countBySegAlpha;
        self.segmentPointImage.alpha = countBySegAlpha;
        self.activityIndicator.alpha = loadingCtlsAlpha;
        self.progressView.alpha = importCtlsAlpha;
        self.itemCountLogTextView.alpha = logAlpha;
        self.itemListTableView.alpha = itemsListAlpha;
        self.locTotalCntTextField.alpha = itemsListAlpha;
        
        [self locImageHidden:!showImage animated:NO];
        if (completeBlock) {
            completeBlock(YES);
        }
        
    }
    
}

- (void)setPrimaryControlsAlpha:(CGFloat)alpha
{
    if (self.incrementCountForCurTextButton) {
        self.incrementCountForCurTextButton.alpha = alpha;
    }
    else {
        self.incrementCountForCurTextButton.alpha = 0.0f;
    }
    self.itemCountAddField.alpha = alpha;
    
    
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        self.countBySegmentedControl.alpha = alpha;
        self.segmentPointImage.alpha = alpha;
    }
    else {
        self.countBySegmentedControl.alpha = 0.0f;
        self.segmentPointImage.alpha = 0.0f;
    }
    
    if (self.isScanCodeAvailable) {
        self.scanItemCodeButton.alpha = alpha;
    }
    else {
        self.scanItemCodeButton.alpha = 0.0f;
        self.scanTitleCodeButton.alpha = 0.0f;
    }
    
}

- (void)setDefaultPhoto
{
    [self.locImageView setImage:self.defaultLocationImage];
    //[self setPhotoShadowShape];
    [self updateLocationImageFrameAndShadowForTraitCollection:self.traitCollection forEnlaged:NO forNarrowLayout:layoutIsNarrow];
}

/**
 *  set opacity zero inside animations, update at end of animation
 */
- (void)setPhotoShadowShape
{
    
    self.shadowImageView.frame = self.locImageView.frame;
    
    if (self.locImageView.alpha > 0.0) {
        CALayer *l = self.locImageView.layer;
        [l setMasksToBounds:YES];
        [l setCornerRadius:20.0];
        if (self.shadowImageLayer == nil) {
            //self.shadowImageLayer = [CALayer layer];
            self.shadowImageLayer = self.shadowImageView.layer;
            [self.shadowImageLayer setBackgroundColor:[[UIColor grayColor] CGColor]];
            //[shadLayer setBorderColor:[[UIColor blackColor] CGColor]];
            //[shadLayer setBorderWidth:2.0f];
            [self.shadowImageLayer setShadowOffset:CGSizeMake(-3.0f, 4.0f)];
            [self.shadowImageLayer setShadowRadius:5.0f];
            [self.shadowImageLayer setShadowColor:[UIColor blackColor].CGColor];
            [self.shadowImageLayer setShadowOpacity:0.75];
            
            [self.shadowImageLayer setCornerRadius:20.0f];
            //self.shadowImageLayer.opacity = self.shadowOpacityDefault;
            
            //[self.view.layer addSublayer:self.shadowImageLayer];
            
        }
        [self.shadowImageLayer setFrame:l.frame];
        [self.shadowImageLayer setZPosition:0.80f];
        [l setZPosition:0.96f];
        [[self.locImageButton layer] setZPosition:0.97f];
        if (self.tipTextLabel != nil) {
            [self.tipTextLabel.layer setZPosition:1.0f];
            //[self.shadowTipTextLayer setZPosition:0.99f];
        }
        
    }
}

- (void)controlsAlphaForEditing:(BOOL)editing
{
    CGFloat editCtlsAlpha = 0.0f;
    CGFloat nonEditCtlsAlpha = 1.0f;
    CGFloat logAlpha = self.logAlphaDefault;
    CGFloat listAlpha = 1.0f;
    
    
    if (editing) {
        editCtlsAlpha = 1.0f;
        //imageEditAlpha = 0.6667f;
        nonEditCtlsAlpha = 0.0f;
        logAlpha = 0.0f;
        
        if (layoutIsNarrow) {
            listAlpha = 0.0f;
        }
        else if (itemsAtLoc.count == 0) {
            listAlpha = 0.0f;
        }
    }
    else if (layoutIsNarrow) {
        
        if (displayLog) {
            listAlpha = 0.0f;
        }
        else {
            logAlpha = 0.0f;
        }
    }
    else {
        if (self.itemCountLogTextView.text.length == 0) {
            logAlpha = 0.0f;
        }
    }
    if (self.traitCollection.verticalSizeClass != UIUserInterfaceSizeClassCompact) {
        self.segmentPointImage.alpha = nonEditCtlsAlpha;
        self.countBySegmentedControl.alpha = nonEditCtlsAlpha;
        if ([AppController sharedAppController].showNegateToggle) {
            self.negateCountToggle.alpha = nonEditCtlsAlpha;
        }
        else self.negateCountToggle.alpha = 0.0f;
    }
    self.locationTitleTextField.alpha = editCtlsAlpha;
    
    self.itemCountAddField.alpha = nonEditCtlsAlpha;
    
    if (self.showOKCountButton) {
        self.okCountButton.alpha = nonEditCtlsAlpha;
    }
    else {
        self.okCountButton.alpha = 0.0f;
    }
    
    self.itemCountLogTextView.alpha = logAlpha;
    self.itemListTableView.alpha = listAlpha;
    self.locTotalCntTextField.alpha = listAlpha;
    if (self.isScanCodeAvailable) {
        self.scanTitleCodeButton.alpha = editCtlsAlpha;
        self.scanItemCodeButton.alpha = nonEditCtlsAlpha;
    }
}

- (void)toggleNegateCountColorsAndValues
{
    if (self.negateCountToggle.selected) {
        //self.negateCountToggle.backgroundColor = posColor;
        self.negateCountToggle.selected = NO;
        
        [self updateSegmentControlFont];
        
        [self.countBySegmentedControl setTitle:@"1" forSegmentAtIndex:0];
        [self.countBySegmentedControl setTitle:@"3" forSegmentAtIndex:1];
        if (countByCustom > 0) {
            [self.countBySegmentedControl setTitle:[NSString stringWithFormat:@"%d", countByCustom] forSegmentAtIndex:2];
        }
    }
    else {
        //self.negateCountToggle.backgroundColor = negColor;
        self.negateCountToggle.selected = YES;
        
        [self updateSegmentControlFont];
        
        [self.countBySegmentedControl setTitle:@"-1" forSegmentAtIndex:0];
        [self.countBySegmentedControl setTitle:@"-3" forSegmentAtIndex:1];
        if (countByCustom > 0) {
            [self.countBySegmentedControl setTitle:[NSString stringWithFormat:@"-%d", countByCustom] forSegmentAtIndex:2];
        }
    }
    
}

- (void)fadeVisibleNonImageComponentsToAlpha:(CGFloat)alpha
{
    if (self.itemCountLogTextView.alpha > 0.0f) {
        self.itemCountLogTextView.alpha = self.logAlphaDefault;
    }
    if (self.itemListTableView.alpha > 0.0f) {
        self.itemListTableView.alpha = alpha;
    }
    if (self.itemCountAddField.alpha > 0.0f) {
        self.itemCountAddField.alpha = alpha;
    }
    if (self.countBySegmentedControl.alpha > 0.0f) {
        self.countBySegmentedControl.alpha = alpha;
        self.segmentPointImage.alpha = alpha;
    }
    if (self.okCountButton.alpha > 0.1f) {
        self.okCountButton.alpha = alpha;
    }
    if (self.locTotalCntTextField.alpha > 0.0f) {
        self.locTotalCntTextField.alpha = alpha;
    }
    if (self.locationTitleTextField.alpha > 0.0f) {
        self.locationTitleTextField.alpha = alpha;
    }
    if (self.negateCountToggle.alpha > 0.0f) {
        self.negateCountToggle.alpha = alpha;
    }
    if (self.scanItemCodeButton.alpha > 0.0f) {
        self.scanItemCodeButton.alpha = alpha;
    }
}

/**
 *   shape and contents; If don't anchor, then make sure is anchored for your starting point
 */
- (void)updateLocationImage:(UIImage *)imageToDisplay isNewImage:(BOOL)isNew isZoomEnlarged:(BOOL)enlarged animated:(BOOL)animated withDuration:(CGFloat)duration includeBounce:(BOOL)bounce
{
    float width = imageToDisplay.size.width;
    float height = imageToDisplay.size.height;
    
    CGSize sizeLimit = [self locationImageSizeLimitForEnlarged:enlarged];
    
    if (height > sizeLimit.height) {
        float multiplier = sizeLimit.height / imageToDisplay.size.height;
        width *= multiplier;
        height = sizeLimit.height;
    }
    if (width > sizeLimit.width) {
        float multiplier = sizeLimit.width / width;
        height *= multiplier;
        width = sizeLimit.width;
    }

    CGRect imageRect = CGRectMake(0, 0, width, height);
    
    // Begin context
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(imageRect.size, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(imageRect.size);
    }
    
    // render image onto context
    [imageToDisplay drawInRect:imageRect];
    // use image for screen
    self.currentImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    

    if (animated) {
        // establish current position before anim
        if (enlarged || isNew) {
            [self.locImageView setImage:self.currentImage];
        }
        
        [UIView animateWithDuration:duration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self updateLocationImageFrameAndShadowForTraitCollection:self.traitCollection forEnlaged:enlarged forNarrowLayout:layoutIsNarrow];
                             if (enlarged) {
                                 [self fadeVisibleNonImageComponentsToAlpha:0.5f];
                             }
                             else {
                                 [self fadeVisibleNonImageComponentsToAlpha:1.0f];
                             }
                             //[self.view layoutIfNeeded];
                             
                         }
                         completion:^(BOOL fin) {
                             if (!enlarged) {
                                 [self.locImageView setImage:self.currentImage];
                             }
                             if (bounce) {
                                 [self animateImageBounce];
                             }
                             
                         }];
    }
    else {
        [self.locImageView setImage:self.currentImage];
        [self updateLocationImageFrameAndShadowForTraitCollection:self.traitCollection forEnlaged:enlarged forNarrowLayout:layoutIsNarrow];
        //[self setPhotoShadowShape];
    }
}


/**
 *  avoid calling within a rotation
 *  does not call setPHotoShadow
 */
- (void)updateLocationImageFrameAndShadowForTraitCollection:(UITraitCollection *)traitCollection forEnlaged:(BOOL)enlarged forNarrowLayout:(BOOL)narrow
{
    CGFloat width = self.locImageView.image.size.width;
    CGFloat height = self.locImageView.image.size.height;
    if (width <= 0 || height <= 0) {
        return;
    }
    CGFloat y = [self imageYPositionForTraitCollection:traitCollection forNarrowLayout:narrow];
    
    CGFloat widthLimit = 232.0f;
    CGFloat heightLimit = 168.0f;
    
    if (enlarged) {
        widthLimit = self.locImageView.image.size.width;
        heightLimit = self.locImageView.image.size.height;
    }
    else if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        heightLimit = 152.0f;
    }
    
    
    if (height > heightLimit) {
        CGFloat multiplier = heightLimit / height;
        height = heightLimit;
        width *= multiplier;
    }
    if (width > widthLimit) {
        CGFloat multiplier = widthLimit / width;
        height *= multiplier;
        width = widthLimit;
    }
    
    if (self.mySize.width > 240.0f) {
        CGFloat adj = 16.0f;
        if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            adj = 20.0f;
        }
        CGFloat x = self.mySize.width - adj - width;
        
        CGRect newRect = CGRectMake(x, y, width, height);
        [self.locImageView setFrame:newRect];
        
        [self updateLocationImagePositionButtonAndShadowBasedOnImageFrameForTrait:traitCollection];
    }
    
}

- (void)updateLocationImagePositionButtonAndShadowBasedOnImageFrameForTrait:(UITraitCollection *)traitCollection
{
    CGRect frame = self.locImageView.frame;
    
    [self.locImageButton setFrame:CGRectMake(frame.origin.x + 10.0f, frame.origin.y + 10.0f,
                                             frame.size.width - 20.0f, frame.size.height - 20.0f)];
    
    CALayer *butLayer = self.locImageButton.layer;
    [butLayer setMasksToBounds:YES];
    [butLayer setCornerRadius:20.0f];
    
    [self.locImageContrainstWidth setConstant:frame.size.width];
    [self.locImageContranstHeight setConstant:frame.size.height];
    [self.locImageEditContraintWidth setConstant:frame.size.width - 20.0f];
    [self.locImageEditConstraintHeight setConstant:frame.size.height - 20.0f];
    
    CGFloat topAdj = 64.0f;
    if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        
        topAdj = self.navigationController.navigationBar.frame.size.height;
        
    }
    [self.locImageConstraintTopSpace setConstant:frame.origin.y - topAdj];
    [self.locImageEditContraintTopSpace setConstant:frame.origin.y - topAdj + 10.0f];
    
    [self setPhotoShadowShape];
}

#pragma mark - barbutton layout

- (void)configureBarButtons:(BOOL)animated
{
    NSArray *rightBarButtons = nil;
    NSMutableArray *bottomButtons = [self.toolBar.items mutableCopy];
    
    while (bottomButtons.count > 1) {
        [bottomButtons removeLastObject];
    }
    self.countTotalButton = nil;
    self.actionButton = nil;
    self.toolsButton = nil;
    self.logToggleButton = nil;
    self.cameraButton = nil;
    
    if (layoutMode == NormalLayout) {
        
        if (self.countTotalButton == nil) {
            /*
             self.countTotalButton = [[UIBarButtonItem alloc] initWithTitle:@"\u2211"
             style:UIBarButtonItemStylePlain
             target:self
             action:@selector(countTotalAction:)];
             */
            self.countTotalButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sigmaIcon"]
                                                                     style:UIBarButtonItemStylePlain target:self
                                                                    action:@selector(countTotalAction:)];
            
            [self.countTotalButton setTintColor:[AppController sharedAppController].barButtonColor];
            [self.countTotalButton setTitleTextAttributes:
             [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AmericanTypewriter" size:22.0], NSFontAttributeName, nil] forState:UIControlStateNormal];
            if (itemsTotalList == nil) {
                self.countTotalButton.enabled = NO;
            }
        }
        if (self.actionButton == nil) {
            self.actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                              target:self
                                                                              action:@selector(actionMenuAction:)];
            [self.actionButton setTintColor:[AppController sharedAppController].barButtonColor];
        }
        if (self.toolsButton == nil) {
            self.toolsButton = [[UIBarButtonItem alloc] initWithTitle:@"\u2699"
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(toolsMenuAction:)];
            UIFont *f1 = [UIFont fontWithName:@"Helvetica" size:24.0];
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:f1, NSFontAttributeName, nil];
            
            [self.toolsButton setTitleTextAttributes:dict forState:UIControlStateNormal];
            [self.toolsButton setTintColor:[AppController sharedAppController].barButtonColor];
            
        }
        UIBarButtonItem *spacerNavButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        UIBarButtonItem *spacerNavButton2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        UIBarButtonItem *spacerNavButton3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spacerNavButton.width = 21.0f;
        spacerNavButton2.width = 18.0f;
        spacerNavButton3.width = 18.0f;
        
        if (layoutIsNarrow) {
            
            //if (/*traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular && */traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
            spacerNavButton.width = 18.0f;
            spacerNavButton2.width = 16.0f;
            spacerNavButton3.width = 16.0f;
            rightBarButtons = [[NSArray alloc] initWithObjects:self.editButtonItem, nil];
            
            UIBarButtonItem *bigSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            [bottomButtons addObject:bigSpace];
            
            NSString *logButtonTitle = NSLocalizedString(@"Log", @"Log");
            if (displayLog) {
                logButtonTitle = NSLocalizedString(@"Counts", @"Counts");
            }
            
            if (self.logToggleButton == nil) {
                self.logToggleButton = [[UIBarButtonItem alloc]
                                        initWithTitle:logButtonTitle
                                        style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(toggleItemListLogAction)];
                self.logToggleButton.tintColor = [AppController sharedAppController].barButtonColor;
            }
            [bottomButtons addObject:self.logToggleButton];
            UIBarButtonItem *fixedBut = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            UIBarButtonItem *fixedBut2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            fixedBut.width = 16.0f;
            fixedBut2.width = 16.0f;
            [bottomButtons addObject:spacerNavButton2];
            [bottomButtons addObject:self.countTotalButton];
            [bottomButtons addObject:fixedBut];
            if (itemsTotalList.count > 0) {
                [bottomButtons addObject:self.toolsButton];
                [bottomButtons addObject:fixedBut2];
            }
            [bottomButtons addObject:self.actionButton];
        }
        else {
            
            UIBarButtonItem *bigSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            
            if (self.navigationController.navigationBar.frame.size.width > 700.0f)
            {
                rightBarButtons = [[NSArray alloc] initWithObjects:self.editButtonItem, spacerNavButton, self.actionButton, spacerNavButton3, self.countTotalButton, nil];
                
                [bottomButtons addObject:spacerNavButton2];
                [bottomButtons addObject:self.categoryBarButton];
                [bottomButtons addObject:bigSpace];
            }
            else {
                rightBarButtons = [[NSArray alloc] initWithObjects:self.editButtonItem, spacerNavButton, self.countTotalButton, nil];
                
                [bottomButtons addObject:bigSpace];
                [bottomButtons addObject:self.actionButton];
                [bottomButtons addObject:spacerNavButton2];
            }
            if (itemsTotalList.count > 0) {
                [bottomButtons addObject:self.toolsButton];
            }
        }
        
        if (self.itemCountLogTextView.text.length > 0) {
            UIBarButtonItem *undoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(undoAddCountItem:)];
            undoButton.tintColor = [[AppController sharedAppController] barButtonColor];
            UIBarButtonItem *fixedBut = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            fixedBut.width = 16.0f;
            [bottomButtons addObject:fixedBut];
            [bottomButtons addObject:undoButton];
        }
    }
    else if (layoutMode == EditingLayout) {
        UIBarButtonItem *fixedBut = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedBut.width = 16.0f;
        [bottomButtons addObject:fixedBut];
        [bottomButtons addObject:self.categoryBarButton];
        
        if (self.isCameraAvailable &&
            (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular || self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular))
        {
            if (self.cameraButton == nil) {
                self.cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraAction)];
                self.cameraButton.tintColor = [AppController sharedAppController].barButtonColor;
            }
            
            if (layoutIsNarrow) {
                UIBarButtonItem *flexySpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
                [bottomButtons addObject:flexySpace];
                [bottomButtons addObject:self.cameraButton];
                
                rightBarButtons = [[NSArray alloc] initWithObjects:self.editButtonItem, nil];
            }
            else {
                UIBarButtonItem *fixedBut2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
                fixedBut2.width = 20.0f;
                rightBarButtons = [[NSArray alloc] initWithObjects:self.editButtonItem, fixedBut2, self.cameraButton, nil];
            }
        }
        else {
            rightBarButtons = [[NSArray alloc] initWithObjects:self.editButtonItem, nil];
        }
    }
    else if (layoutMode == ImportLayout) {
        UIBarButtonItem *cancelImportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelImport)];
        rightBarButtons = [[NSArray alloc] initWithObjects:cancelImportButton, nil];
        
    }
    else if (layoutMode == LoadingLayout) {
        
    }
    
    NSArray *newBottomButtons = [[NSArray alloc] initWithArray:[bottomButtons copy]];
    
    [self.navigationItem setRightBarButtonItems:rightBarButtons animated:animated];
    [self.toolBar setItems:newBottomButtons animated:animated];
}

- (void)addUndoButtonAnimated:(BOOL)animated
{
    NSMutableArray *bottomButtons = [self.toolBar.items mutableCopy];
    
    UIBarButtonItem *undoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(undoAddCountItem:)];
    undoButton.tintColor = [[AppController sharedAppController] barButtonColor];
    UIBarButtonItem *fixedBut = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedBut.width = 16.0f;
    [bottomButtons addObject:fixedBut];
    [bottomButtons addObject:undoButton];
    [self.toolBar setItems:bottomButtons animated:animated];
}

- (void)removeUndoButton:(BOOL)animated
{
    NSMutableArray *bottomButtons = [self.toolBar.items mutableCopy];
    [bottomButtons removeLastObject];
    [bottomButtons removeLastObject];
    [self.toolBar setItems:bottomButtons animated:animated];
}


#pragma mark -
#pragma mark - Outlet Actions

- (IBAction)addCountItem:(id)sender
{
    if (kbWillHide && !addCountReturning) {
        return;
    }
    if (cellMenuShowing) return;
    
    NSString *countText = [[AppController sharedAppController] stripBadCharactersFromString:self.itemCountAddField.text];
    countText = [countText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSInteger value = countBy;
    if (self.negateCountToggle.selected) {
        value = value * -1;
    }
    [self addCountForLabel:countText withValue:value performLog:YES showSelectedItem:YES];
    
    // ensure reset
    [self.itemCountAddField setText:(@"")];
    
    //[self.incrementCountForCurTextButton setHidden:YES];
    
    if (self.negateCountToggle.selected) {
        // reset
        [self toggleNegateCountColorsAndValues];
        if (self.countBySegmentedControl.selectedSegmentIndex >= 2) {
            self.countBySegmentedControl.selectedSegmentIndex = 0;
            countBy = 1;
        }
    }
}

- (void)addCountForLabel:(NSString *)countText withValue:(NSInteger)value performLog:(BOOL)logIt showSelectedItem:(BOOL)selectItemInTable
{
    NSUInteger oldTotalCount = locationTotalItemCount;
    AppController *ac = [AppController sharedAppController];
    
    BOOL logHasTextBefore = (self.itemCountLogTextView.text.length > 0);
    BOOL totalsHasCountsBefore = (itemsTotalList.count > 0);
    
    if (countText.length > 0) {
        addCount++;
        if (countText.length > 24) {
            countText = [countText substringToIndex:24];
        }
        
        int cnt = (int)value;
        int countByReported = cnt;   // number to use in log - always positive
        if (value < 0) {
            countByReported = countByReported * -1;
        }
        
        BOOL foundAtLocation = NO;
        BOOL needToReload = NO;
        
        
        /* * *
         * Begin table updates
         */
        [self.itemListTableView beginUpdates];
        
        // check if exists at location
        for (int i = 0; i < itemsAtLoc.count; ++i) {
            DTCountItem *locItem = [itemsAtLoc objectAtIndex:i];
            NSString *locLabel = [locItem valueForKey:@"label"];
            if (([locLabel compare:countText options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
                
                foundAtLocation = YES;
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                DTCountInventory *inventoryAtLocation = [self inventoryForItemAtLocation:locItem];
                int locItemCount = [[inventoryAtLocation valueForKey:@"count"] intValue];
                
                cnt += locItemCount;
                if (cnt <= 0) {
                    //countByReported = cnt + countBy;
                    cnt = 0;
                    countByReported = 0;  // turn off since deleteItemAtLoc will update log
                    [self deleteItemAtLocation:i peformLog:logIt];
                    
                    [self.itemListTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                }
                else {
                    NSNumber *num = [NSNumber numberWithInt:cnt];
                    [inventoryAtLocation setValue:num forKey:@"count"];
                    [self.itemListTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                break;
            }
        }
        
        if (!foundAtLocation) {
            DTCountLocation *detailLoc = (DTCountLocation *)self.detailItem;
            
            if (cnt > 0) {
                // does item exist in totals?
                NSManagedObjectContext *moc = [AppController sharedAppController].managedObjectContext;
                DTCountItem *itemToAdd = nil;
                DTCountInventory *inventoryAtLocation = nil;
                
                itemToAdd = [self itemInTotalsWithLabel:countText];
                if (itemToAdd) {
                    // if no count, add to short list
                    if ([self itemHasCount:itemToAdd] == NO) {
                        [itemsShortList addObject:itemToAdd];
                    }
                    
                    // does it need a category?
                    
                    DTCountCategory *cat = [itemToAdd valueForKey:@"category"];
                    if (!cat) {
                        cat = [[DTCountCategoryStore sharedStore] categoryWithLabel:[detailLoc valueForKey:@"defCatLabel"]];
                        if (cat) {
                            itemToAdd = [[DTCountCategoryStore sharedStore] itemSetCategory:cat forItem:itemToAdd];
                        }
                    }
                    
                    // set inventory for this location
                    inventoryAtLocation = [self inventoryForItemAtLocation:itemToAdd];
                    if (!inventoryAtLocation) {
                        inventoryAtLocation = [NSEntityDescription insertNewObjectForEntityForName:@"Inventory" inManagedObjectContext:moc];
                    }
                }
                else {
                    // make new item
                    
                    itemToAdd = [[DTCountCategoryStore sharedStore] createNewItemWithLabel:countText withCategoryByLabel:[detailLoc valueForKey:@"defCatLabel"]];
                    
                    if (itemsTotalList == nil) {
                        if (itemsTempList == nil) {
                            itemsTempList = [[NSMutableArray alloc] init];
                        }
                        [itemsTempList addObject:itemToAdd];
                    }
                    else {
                        [itemsShortList addObject:itemToAdd];
                        [itemsTotalList addObject:itemToAdd];
                    }
                    
                    inventoryAtLocation = [NSEntityDescription insertNewObjectForEntityForName:@"Inventory" inManagedObjectContext:moc];
                }
                
                [[detailLoc mutableSetValueForKey:@"inventories"] addObject:inventoryAtLocation];
                [[itemToAdd mutableSetValueForKey:@"inventories"] addObject:inventoryAtLocation];
                
                NSNumber *num = [NSNumber numberWithInt:cnt];
                [inventoryAtLocation setValue:num forKey:@"count"];
                
                [itemsAtLoc addObject:itemToAdd];
                
                [self resortItems];
                
                NSIndexPath *indexPathOfInsert = [self indexPathForItemWithLabel:countText];
                if (indexPathOfInsert != nil) {
                    
                    [self.itemListTableView insertRowsAtIndexPaths:@[indexPathOfInsert] withRowAnimation:UITableViewRowAnimationLeft];
                }
                else {
                    needToReload = YES;
                }
            }
            else {
                // reset since nothing added
                countByReported = 0;
            }
        }
        
        
        [self.itemListTableView endUpdates];
        /*
         * done table updates
         * * * */
        
        if (countByReported != 0) {
            if (value < 0) {
                if (locationTotalItemCount < countByReported) {
                    locationTotalItemCount = 0;
                }
                else locationTotalItemCount -= countByReported;
                
                if (logIt) {
                    DTCountLogEntry *logEntry = [[DTCountLogEntry alloc] initWithLabel:countText withValue:countByReported * -1];
                    [logItems addLogEntry:logEntry];
                }
                
            }
            else {
                locationTotalItemCount += countByReported;
                if (logIt) {
                    DTCountLogEntry *logEntry = [[DTCountLogEntry alloc] initWithLabel:countText withValue:countByReported];
                    [logItems addLogEntry:logEntry];
                }
            }
            [self.itemCountLogTextView setText:logItems.log];
            
            if (!logHasTextBefore && logItems.count > 0) {
                //[self addUndoButton];
                [self configureBarButtons:YES];
            }
            else if (logItems.count == 0) {
                //[self removeUndoButton];
                [self configureBarButtons:YES];
            }
            else if (!totalsHasCountsBefore && itemsTotalList.count > 0) {
                [self configureBarButtons:YES];
            }
            
            if (self.itemCountLogTextView.alpha == 0 && !layoutIsNarrow) {
                [self animateLogFadeVisible:YES];
            }
            
            [self updateCountsValuesForTotalItemsCount:locationTotalItemCount fromOldValue:oldTotalCount withBlink:YES];
        }
        
        if (needToReload) {
            NSLog(@"! addCount - Reloading the table!!");
            [self.itemListTableView reloadData];
        }
        
        if (cnt > 0 && selectItemInTable) {
            [self selectItemByLabel:countText showDetails:NO withScroll:UITableViewScrollPositionTop];
        }
        
        
        if (addCount > 32)
        {
            // save every few for safety
            [ac saveContext];
            addCount = 0;
        }
    }
}

- (IBAction)addCountEditingChanged:(id)sender
{
    if (!kbShowing && self.itemCountAddField.text.length > 0) {
        [self animateOKButtonEnabled:YES];
    }
    else {
        [self animateOKButtonEnabled:NO];
    }
    
    if (self.itemCountAddField.text.length > 0) {
        [self.incrementCountForCurTextButton setHidden:NO];
        [self.incrementCountForCurTextButton setEnabled:YES];
    }
    else {
        [self.incrementCountForCurTextButton setHidden:YES];
    }
    
    if (self.tipTextLabel != nil && self.itemCountAddField.text.length == 1 && self.tipTextLabel.alpha >= 0.65f) {
        [self hideTipTextAnimated:YES];
    }
}

- (IBAction)countBySegmentControllerValueChanged:(id)sender
{
    NSUInteger idx = self.countBySegmentedControl.selectedSegmentIndex;
    if (idx == 0) countBy = 1;
    else if (idx == 1) countBy = 3;
    else if (idx == 2)
    {
        if (countByCustom <= 0) countBy = 12;
        else countBy = countByCustom;
    }
    else {
        if (countByCustom <= 0) countBy = 12;
        else countBy = countByCustom;
        
        [self.itemCountAddField resignFirstResponder];
        [self animateOKButtonEnabled:NO];
        //if (self.popoverController != nil) {
        //    [self.popoverController dismissPopoverAnimated:YES];
        // }
        
        float width = (float)self.countBySegmentedControl.frame.size.width * 0.25;
        float x = self.countBySegmentedControl.frame.origin.x + width * 3.0;
        float y = self.countBySegmentedControl.frame.origin.y;
        float height = self.countBySegmentedControl.frame.size.height;
        CGRect rect = CGRectMake(x, y, width, height);
        
        CountPadSelectController *countPad = [[CountPadSelectController alloc] init];
        [countPad setPadDoneDelegate:self];
        countPad.modalPresentationStyle = UIModalPresentationPopover;
        
        self.countPadController = countPad;
        
        /* the old way
         self.countTotalPopoverController = [[UIPopoverPresentationController alloc] initWithPresentedViewController:countPadController presentingViewController:self];
         self.countTotalPopoverController.delegate = self;
         self.countTotalPopoverController.sourceView = self.view;
         self.countTotalPopoverController.sourceRect = rect;
         */
        
        [self presentViewController:self.countPadController animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [self.countPadController popoverPresentationController];
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        presentationController.sourceRect = rect;
        presentationController.sourceView = self.view;
        presentationController.delegate = self;
        
        [self.countBySegmentedControl setSelectedSegmentIndex:2];
    }
}

- (IBAction)deleteLocationAction:(id)sender
{
    if (self.deleteConfirmNavController != nil) {
        [self.deleteConfirmNavController dismissViewControllerAnimated:YES completion:^{
            self.deleteConfirmNavController = nil;
        }];
    }
    else {
        DeleteConfirmViewController *delConfController = [[DeleteConfirmViewController alloc] init];
        delConfController.delegate = self;
        delConfController.navigationItem.title = NSLocalizedString(@"Confirm Delete", @"Confirm Delete");
        delConfController.deleteKey = 1;
        delConfController.dismissBlock = ^{
            self.deleteConfirmNavController = nil;
        };
        DTCountLocation *loc = (DTCountLocation *)self.detailItem;
        delConfController.message = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"confirmDeleteMessage", @"confirmDeleteMessage"), [loc valueForKey:@"label"]];
        
        UINavigationController *delNavCtl = [[UINavigationController alloc] initWithRootViewController:delConfController];
        delNavCtl.modalPresentationStyle = UIModalPresentationFormSheet;
        
        self.deleteConfirmNavController = delNavCtl;
        self.deleteConfirmNavController.preferredContentSize = CGSizeMake(296.0f, 176.0f);
        
        [self presentViewController:self.deleteConfirmNavController animated:YES completion:nil];
        UIPopoverPresentationController *presentController = [self.deleteConfirmNavController popoverPresentationController];
        presentController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        presentController.sourceView = self.view;
        presentController.barButtonItem = self.deleteLocationButton;
        presentController.delegate = self;
    }
    
}

- (IBAction)locationImageEditButtonAction:(id)sender
{
    // resign responders
    [self.view endEditing:YES];
    
    if (hasUserImage) {
        EditPhotoTableView *editPhotoTVController = [[EditPhotoTableView alloc] init];
        editPhotoTVController.delegate = self;
        editPhotoTVController.hasCurrentPhoto = hasUserImage;
        
        UINavigationController *navCtl = [[UINavigationController alloc] initWithRootViewController:editPhotoTVController];
        navCtl.modalPresentationStyle = UIModalPresentationPopover;
        
        self.editPhotoNavController = navCtl;
        
        [self presentViewController:self.editPhotoNavController animated:YES completion:nil];
        UIPopoverPresentationController *presentController = [self.editPhotoNavController popoverPresentationController];
        presentController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        presentController.sourceView = self.view;
        presentController.sourceRect = self.locImageButton.frame;
        presentController.delegate = self;
    }
    else {
        [self addPhoto];
    }
    
    
}

- (IBAction)negateToggleAction:(id)sender
{
    [self toggleNegateCountColorsAndValues];
}

- (IBAction)scanItemCodeAction:(id)sender
{
    if (addCount > 12) {
        [[AppController sharedAppController] saveContext];
        addCount = 0;
    }
    
    // resign responders
    [self.view endEditing:YES];
    
    self.scanItemCodeButton.enabled = NO;
    self.scanTitleCodeButton.enabled = NO;
    
    
    DTScanCodeViewController *scanController = [[DTScanCodeViewController alloc] initWithCodeSupport:DTCodeSupportBarOnly];
    scanController.scannedCodeSelectedDelegate = self;
    
    [[AppController sharedAppController] setScanCodeMetaControl:scanController.scanCodeMetaControl];
    
    scanController.dismissBlock = ^{
        [self closeScanCodeController];
    };
    
    self.scanCodeViewController = scanController;
    
    if ([AppController sharedAppController].noTapScanning) {
        self.scanCodeViewController.sendCodeOnTap = NO;
        [self.scanCodeViewController.instructionLabel setText:NSLocalizedString(@"Scan bar code-NoTap", @"Scan bar code (auto)")];
    }
    else {
        self.scanCodeViewController.sendCodeOnTap = YES;
        [self.scanCodeViewController.instructionLabel setText:NSLocalizedString(@"Tap to scan selected", @"Tap to scan selected")];
    }
    
    if (self.tipTextLabel != nil && self.tipTextLabel.alpha >= 0.8f) {
        [self hideTipTextAnimated:YES];
    }
    
    [self presentScanCodeControllerFromSourceRect:self.scanItemCodeButton.frame];
}

- (IBAction)scanTitleCodeAction:(id)sender
{
    // resign responders
    [self.view endEditing:YES];
    
    self.scanItemCodeButton.enabled = NO;
    self.scanTitleCodeButton.enabled = NO;
    
    DTScanCodeViewController *scanController = [[DTScanCodeViewController alloc] initWithCodeSupport:DTCodeSupportQROnly];
    scanController.scannedCodeSelectedDelegate = self;
    
    [[AppController sharedAppController] setScanCodeMetaControl:scanController.scanCodeMetaControl];
    
    scanController.dismissBlock = ^{
        [self closeScanCodeController];
    };
    
    self.scanCodeViewController = scanController;
    
    self.scanCodeViewController.sendCodeOnTap = NO;
    [self.scanCodeViewController.instructionLabel setText:NSLocalizedString(@"Location code", @"Location code")];
    if (self.tipTextLabel != nil && self.itemCountAddField.text.length == 1 && self.tipTextLabel.alpha >= 0.85f) {
        [self hideTipTextAnimated:YES];
    }
    
    [self presentScanCodeControllerFromSourceRect:self.scanTitleCodeButton.frame];
}

- (void)presentScanCodeControllerFromSourceRect:(CGRect)rect
{
    self.scanCodeViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    [self presentViewController:self.scanCodeViewController animated:YES completion:nil];
    UIPopoverPresentationController *presentationController = [self.scanCodeViewController popoverPresentationController];
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    presentationController.sourceRect = rect;
    presentationController.sourceView = self.view;
    presentationController.delegate = self;
}

- (IBAction)titleChanged:(id)sender
{
    [self updateTitle:self.locationTitleTextField.text];
    
    if (self.locationTitleTextField.text.length == 1) {
        if (self.locImageView.alpha == 0) {
            [self locImageHidden:NO animated:YES];
        }
        if (self.tipTextLabel != nil && self.tipTextLabel.alpha >= 0.75f) {
            [self hideTipTextAnimated:YES];
        }
    }
}

- (IBAction)titleEditDidEnd:(id)sender
{
    [self updateTitle:self.locationTitleTextField.text];
}


#pragma mark KB Actions
- (void) keyboardWillHide:(NSNotification *)notif
{
    kbWillHide = YES;
}

- (void) keyboardDidHide:(NSNotification *) notif
{
    
    if ([self.itemCountAddField isFirstResponder] && self.itemCountAddField.text.length > 0)
    {
        [self animateOKButtonEnabled:YES];
    }
    kbShowing = NO;
    kbWillHide = NO;
    
    // lower the table bottom to bottom
    CGRect frame = self.itemListTableView.frame;
    
    //float ht = [[[self view] window] frame].size.height;
    //if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
    //    ht = [[[self view] window] frame].size.width;
    //}
    
    CGRect logFrame = self.itemCountLogTextView.frame;
    float ht = logFrame.size.height - (frame.origin.y - logFrame.origin.y);
    CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, ht);
    [self.itemListTableView setFrame:newFrame];
    
}

- (void) keyboardDidShow:(NSNotification *) notif
{
    kbShowing = YES;
    kbWillHide = NO;
    [self animateOKButtonEnabled:NO];
    
    // lift table bottom to make it easier to see more
    
    CGRect frame = self.itemListTableView.frame;
    if (frame.size.height > 375.0) {
        CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height * 0.66667);
        [self.itemListTableView setFrame:newFrame];
    }
    
}



#pragma mark - Bar Button actions

- (void)cancelImport
{
    [self.importTextView setText:NSLocalizedString(@"Canceling", @"importLabel for cancel: Canceling...")];
    [self.delegate cancelImport];
}

- (void)categoryButtonAction:(id)sender
{
    if ([self checkPopoversToDismiss] == NO) {
        [self.view endEditing:YES];
        
        DTCountLocation *loc = (DTCountLocation *)self.detailItem;
        DTCategoryPickViewController *catPickController = [[DTCategoryPickViewController alloc] init];
        catPickController.location = loc;
        if (itemsAtLoc.count > 0) {
            catPickController.showUpdateAllOption = YES;
        }
        catPickController.delegate = self;
        catPickController.dismissBlock = ^{
            DTCountLocation *location = (DTCountLocation *)self.detailItem;
            [self configureCategoryButtonTitle:location];
            self.categoryPickNavController = nil;
        };
        
        UINavigationController *navCtl = [[UINavigationController alloc] initWithRootViewController:catPickController];
        navCtl.modalPresentationStyle = UIModalPresentationPopover;
        
        self.categoryPickNavController = navCtl;
        
        [self presentViewController:self.categoryPickNavController animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [self.categoryPickNavController popoverPresentationController];
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            presentationController.barButtonItem = self.categoryBarButton;
        }
        else {
            UIView *bView = (UIView *)[self.categoryBarButton performSelector:@selector(view)];
            CGRect superFrame = bView.superview.frame;
            CGRect frame = CGRectMake(bView.frame.origin.x + 5.0f, superFrame.origin.y + bView.frame.origin.y - 1.0f, 16.0f, 12.0f);
            presentationController.sourceRect = frame;
        }
        
        presentationController.sourceView = self.view;
        presentationController.delegate = self;
    }
}

- (void)countTotalAction:(id)sender
{
    if ([self checkPopoversToDismiss] == NO) {
        [self.itemCountAddField resignFirstResponder];
        [self animateOKButtonEnabled:NO];
        [self.incrementCountForCurTextButton setHidden:YES];
        
        
        TotalCountViewController *totalCountsController = [[TotalCountViewController alloc] init];
        totalCountsController.locSelectDelegate = self;
        totalCountsController.dataDocDelegate = self;
        if ([MFMailComposeViewController canSendMail]) {
            // We must always check whether the current device is configured for sending emails
            totalCountsController.emailExportSupported = YES;
        }
        totalCountsController.dismissBlock = ^{
            [self.itemListTableView reloadData];
            self.totalCountNavController = nil;
        };
        
        [totalCountsController setItemsLongList:itemsTotalList];
        [totalCountsController setItemsShortList:itemsShortList];
        
        
        self.totalCountNavController = [[UINavigationController alloc] initWithRootViewController:totalCountsController];
        
        // TODO: half-screen custom?
        //self.totalCountNavController.modalPresentationStyle = UIModalPresentationFullScreen;
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            self.totalCountNavController.modalPresentationStyle = UIModalPresentationPopover;
        }
        else {
            self.totalCountNavController.modalPresentationStyle = UIModalPresentationFullScreen;
        }
        
        
        [self presentViewController:self.totalCountNavController animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [self.totalCountNavController popoverPresentationController];
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            presentationController.barButtonItem = self.countTotalButton;
        }
        else {
            UIView *bView = (UIView *)[self.countTotalButton performSelector:@selector(view)];
            CGRect superFrame = bView.superview.frame;
            CGRect frame = CGRectMake(bView.frame.origin.x + 4.0f, superFrame.origin.y + bView.frame.origin.y - 6.0f, 12.0f, 12.0f);
            presentationController.sourceRect = frame;
        }
        presentationController.sourceView = self.view;
        presentationController.delegate = self;
    }
}

- (void)actionMenuAction:(id)sender
{
    if ([self checkPopoversToDismiss] == NO) {
        DTCountLocation *loc = (DTCountLocation *)self.detailItem;
        [self.itemCountAddField resignFirstResponder];
        [self animateOKButtonEnabled:NO];
        [self.incrementCountForCurTextButton setHidden:YES];
        
        DataDocViewController *exportViewController = [[DataDocViewController alloc] init];
        exportViewController.includeImport = NO;
        exportViewController.showMismatchSwitch = NO;
        exportViewController.exportFileName = [NSString stringWithFormat:@"dCount_%@", [loc valueForKey:@"label"]];
        exportViewController.locationName = [loc valueForKey:@"label"];
        exportViewController.itemsToExport = [itemsAtLoc copy];
        exportViewController.delegate = self;
        exportViewController.needsDoneButton = YES;
        if ([MFMailComposeViewController canSendMail]) {
            // We must always check whether the current device is configured for sending emails
            exportViewController.includeEmailExport = YES;
        }
        exportViewController.headerText = [loc valueForKey:@"label"];
        exportViewController.dismissBlock = ^{
            self.exportMenuNavController = nil;
        };
        
        UINavigationController *navCtl = [[UINavigationController alloc] initWithRootViewController:exportViewController];
        navCtl.modalPresentationStyle = UIModalPresentationPopover;
        
        self.exportMenuNavController = navCtl;
        
        [self presentViewController:self.exportMenuNavController animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [self.exportMenuNavController popoverPresentationController];
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            presentationController.barButtonItem = self.actionButton;
        }
        else {
            UIView *bView = (UIView *)[self.actionButton performSelector:@selector(view)];
            CGRect superFrame = bView.superview.frame;
            
            CGRect frame = CGRectMake(bView.frame.origin.x - 3.0f, superFrame.origin.y + bView.frame.origin.y - 4.0f, 12.0f, 12.0f);
            presentationController.sourceRect = frame;
        }
        presentationController.sourceView = self.view;
        presentationController.delegate = self;
    }
}

- (void)cameraAction
{
    // get location image with camera, else photo library
    
    // resign responders
    [self.view endEditing:YES];
    CGRect sourceRect = CGRectZero;
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    // image picker needs a delegate to respond to msgs
    [imagePicker setDelegate:self];
    
    // if device has cam, take pic else get from lib
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        
        // must be full-screen presentation per Apple documentation
        [imagePicker setModalPresentationStyle:UIModalPresentationFullScreen];
        
        self.imageLocationPickerController = imagePicker;
        
        [self presentViewController:self.imageLocationPickerController animated:YES completion:nil];
        
    }
    else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [imagePicker setModalPresentationStyle:UIModalPresentationCustom];
        sourceRect = self.importTextView.frame;
        
        self.imageLocationPickerController = imagePicker;
        
        
        [self presentViewController:self.imageLocationPickerController animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [self.imageLocationPickerController popoverPresentationController];
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        presentationController.sourceRect = sourceRect;
        presentationController.sourceView = self.view;
        presentationController.delegate = self;
    }
    
    
    // this shows up in console:
    // "Snapshotting a view that has not been rendered results in an empty snapshot. Ensure your view has been rendered at least once before snapshotting or snapshot after screen updates."
    
}


- (void)toggleItemListLogAction
{
    [self toggleItemListLogSwitchAnimated:YES];
}

- (void)toolsMenuAction:(id)sender
{
    if ([self checkPopoversToDismiss] == NO) {
        [self.itemCountAddField resignFirstResponder];
        [self.incrementCountForCurTextButton setHidden:YES];
        
        
        ToolsActionViewController *toolActionController = [[ToolsActionViewController alloc] init];
        toolActionController.toolsActionDelegate = self;
        toolActionController.dismissBlock = ^{
            self.toolsMenuNavController = nil;
        };
        toolActionController.scanCodeIsAvailable = self.isScanCodeAvailable;
        
        UINavigationController *navCtl = [[UINavigationController alloc] initWithRootViewController:toolActionController];
        navCtl.modalPresentationStyle = UIModalPresentationPopover;
        
        self.toolsMenuNavController = navCtl;
        
        // pointing popover from barButtonItem only works on iPad - gets lost on rotations in iPhone 6 Plus - use sourceRect
        //  still true in iOS 8.1
        
        [self presentViewController:self.toolsMenuNavController animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [self.toolsMenuNavController popoverPresentationController];
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;
        
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            presentationController.barButtonItem = self.toolsButton;
        }
        else {
            UIView *bView = (UIView *)[self.toolsButton performSelector:@selector(view)];
            CGRect superFrame = self.toolBar.frame;
            CGRect frame = CGRectMake(bView.frame.origin.x, superFrame.origin.y + bView.frame.origin.y - 4.0f, 12.0f, 12.0f);
            presentationController.sourceRect = frame;
        }
        presentationController.sourceView = self.view;
        presentationController.delegate = self;
    }
}

- (void)undoAddCountItem:(id)sender
{
    DTCountLogEntry *lastEntry = [logItems removeLastItem];
    if (lastEntry) {
        [self addCountForLabel:lastEntry.label withValue:(lastEntry.value * -1) performLog:NO showSelectedItem:NO];
    }
}

#pragma mark - gestures

- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)recognizer
{
    // double-tap usually means zooming which we'll do
    
    if (self.itemCountAddField.text.length == 0) {
        [self.view endEditing:YES];
    }
    if (!self.isEditing) {
        [self animateImageZoom];
    }
}

- (void)handleTipTapGesture:(UITapGestureRecognizer *)recognizer
{
    [self hideTipTextAnimated:YES];
}

- (void)handleSingleTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (self.itemCountAddField.text.length == 0) {
        [self.view endEditing:YES];
    }
    // bounce image to give user idea can double-tap
    [self animateImageBounce];
    
}


- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)recognizer
{
    if (self.itemCountAddField.text.length == 0 || recognizer.direction == UISwipeGestureRecognizerDirectionDown) {
        if (recognizer.direction == UISwipeGestureRecognizerDirectionDown) {
            self.itemCountAddField.text = @"";
        }
        [self.view endEditing:YES];
    }
    if (layoutIsNarrow) {
        if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
            if (!displayLog) {
                [self toggleItemListLogSwitchAnimated:YES];
            }
            else {
                [self animateTableAndLogBounceInDirection:recognizer.direction];
            }
        }
        else if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
            if (displayLog) {
                [self toggleItemListLogSwitchAnimated:YES];
            }
        }
    }
}

- (void)handleImagePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    if (!self.editing && hasUserImage) {
        
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            if (self.itemCountAddField.text.length == 0) {
                [self.view endEditing:YES];
            }
            
            UIImage *imageToDisplay = self.locImageView.image;
            if (self.locImageView.image.size.width < 300.0f || self.locImageView.image.size.height < 300.0f) {
                
                DTCountLocation *loc = (DTCountLocation *)self.detailItem;
                NSString *imageKey = [loc valueForKey:@"picuuid"];
                
                if (imageKey) {
                    imageToDisplay = [[ImageCache sharedImageCache] imageForKey:imageKey];
                    if (imageToDisplay && imageToDisplay != self.locImageView.image) {
                        self.locImageView.image = imageToDisplay;
                    }
                }
            }
            [self.locImageView setImage:imageToDisplay];
        }
        
        CGSize maxImageLimits = [self locationImageSizeLimitForEnlarged:YES];
        
        if ((recognizer.scale < 1.0 && recognizer.view.frame.size.height > 120.0f) ||
            (self.locImageView.frame.size.width < maxImageLimits.width && self.locImageView.frame.size.height < maxImageLimits.height)) {
            
            // scale on layer with CATrans if using IB auto-layout which anchors to the corner, else either works
            recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
            //recognizer.view.layer.transform = CATransform3DScale(recognizer.view.layer.transform, recognizer.scale, recognizer.scale, 1.0f);
            if (recognizer.scale < 1.0f) {
                isPinchingImageDown = YES;
            }
            else if (recognizer.scale > 1.0f) {
                isPinchingImageDown = NO;
            }
            // reset
            recognizer.scale = 1;
            
            [self checkAndAdjustImageLimitsForImageRecognizer:recognizer];
            [self setPhotoShadowShape];
            
        }
        
        if (recognizer.state == UIGestureRecognizerStateEnded) {

            BOOL isBig = (recognizer.view.frame.size.width > 300.0f);
            if (isBig && isPinchingImageDown) {
                isBig = NO;
            }
            else if (!isBig && !isPinchingImageDown) {
                isBig = YES;
            }
            
            CGRect frame = recognizer.view.frame;
            recognizer.view.transform = CGAffineTransformIdentity;
            self.locImageView.frame = frame;
            self.locImageContrainstWidth.constant = frame.size.width;
            self.locImageContranstHeight.constant = frame.size.height;

            [self updateLocationImage:self.locImageView.image isNewImage:NO isZoomEnlarged:isBig animated:YES withDuration:0.2f includeBounce:NO];
        }
        
        
    }
}

- (void)checkAndAdjustImageLimitsForImageRecognizer:(UIGestureRecognizer *)recognizer
{
    
    CGFloat imageY = [self imageYPositionForTraitCollection:self.traitCollection forNarrowLayout:layoutIsNarrow];
    
    CGFloat imageHalfWidth = recognizer.view.frame.size.width / 2;
    CGFloat imageHalfHeight = recognizer.view.frame.size.height / 2;
    CGFloat rightOverlap = recognizer.view.center.x + imageHalfWidth - (self.mySize.width - 24.0f);
    CGFloat topOverlap  = recognizer.view.center.y - imageHalfHeight - imageY;
    
    
    if (rightOverlap != 0) {
        recognizer.view.center = CGPointMake(-rightOverlap + recognizer.view.center.x, recognizer.view.center.y);
    }
    
    if (topOverlap != 0) {
        recognizer.view.center = CGPointMake(recognizer.view.center.x, -topOverlap + recognizer.view.center.y);
    }

}



#pragma mark - Delegates
#pragma mark - ImagePicker delegates


- (void)imagePickerControllerDidCancel: (UIImagePickerController *)picker
{
    [self.imageLocationPickerController dismissViewControllerAnimated:YES completion:^{
        self.imageLocationPickerController = nil;
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.imageLocationPickerController dismissViewControllerAnimated:YES completion:^{
        self.imageLocationPickerController = nil;
        
    }];
    
    DTCountLocation *loc = (DTCountLocation *)self.detailItem;
    
    NSString *oldKey = [loc valueForKey:@"picuuid"];
    
    if (oldKey) {
        [[ImageCache sharedImageCache] deleteImageForKey:oldKey];
    }
    // get picked image p193
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image.size.height > 512.0f)
    {
        float width = image.size.width;
        
        float multiplier = 512.0f / image.size.height;
        width *= multiplier;
        
        CGRect imageRect = CGRectMake(0, 0, width, 512);
        
        // Begin context
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
            UIGraphicsBeginImageContextWithOptions(imageRect.size, YES, 0.0);
        } else {
            UIGraphicsBeginImageContext(imageRect.size);
        }
        
        [image drawInRect:imageRect];
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    CFUUIDRef newUniqueID = CFUUIDCreate(kCFAllocatorDefault);
    
    // create string from uuid
    CFStringRef newUniqueIDString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueID);
    
    NSString *uidString = (__bridge NSString *)newUniqueIDString;
    
    [loc setValue:uidString forKey:@"picuuid"];
    
    // since used create, must release
    CFRelease(newUniqueIDString);
    CFRelease(newUniqueID);
    
    // store image in cache with key
    [[ImageCache sharedImageCache] setImage:image forKey:[loc valueForKey:@"picuuid"]];
    
    // save thumb
    [loc setDataFromImage:image];
    
    hasUserImage = YES;
    
    [self.delegate detailLocationThumbnailChanged];
    
    // put image into screen
    [self updateLocationImage:image isNewImage:YES isZoomEnlarged:NO animated:![self imageIsBig] withDuration:0.12f includeBounce:YES];
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    
    [theTextField resignFirstResponder];
    
    if (theTextField == self.itemCountAddField) {
        
        [self.itemCountAddField becomeFirstResponder];
    }
    else if (theTextField == self.locationTitleTextField) {
        [self setEditing:NO animated:YES];
    }
    
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

#pragma mark - Popovers delegates

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    if (self.countPadController != nil && self.countPadController == popoverPresentationController.presentedViewController) {
        self.countPadController = nil;
    }
    else if (self.scanCodeViewController != nil && self.scanCodeViewController == popoverPresentationController.presentedViewController) {
        [self closeScanCodeController];
    }
    else if (self.itemDetailNavController != nil && self.itemDetailNavController == popoverPresentationController.presentedViewController) {
        [self itemDetailsClosedForSelectedIndex:-1];
        self.itemDetailNavController = nil;
    }
    else if (self.totalCountNavController != nil && self.totalCountNavController == popoverPresentationController.presentedViewController) {
        [self.itemListTableView reloadData];
        self.totalCountNavController = nil;
    }
    else if (self.toolsMenuNavController != nil && self.toolsMenuNavController == popoverPresentationController.presentedViewController) {
        self.toolsMenuNavController = nil;
    }
    else if (self.exportMenuNavController != nil && self.exportMenuNavController == popoverPresentationController.presentedViewController) {
        self.exportMenuNavController = nil;
    }
    else if (self.deleteConfirmNavController != nil && self.deleteConfirmNavController == popoverPresentationController.presentedViewController) {
        self.deleteConfirmNavController = nil;
    }
    else if (self.editPhotoNavController != nil && self.editPhotoNavController == popoverPresentationController.presentedViewController) {
        self.editPhotoNavController = nil;
    }
    else if (self.categoryPickNavController != nil && self.categoryPickNavController == popoverPresentationController.presentedViewController) {
        DTCountLocation *loc = (DTCountLocation *)self.detailItem;
        [self configureCategoryButtonTitle:loc];
        self.categoryPickNavController = nil;
    }
    
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // only 2 choices: full-screen or over-full-screen
    
    if (controller.presentedViewController == self.editPhotoNavController ||
        controller.presentedViewController == self.deleteConfirmNavController) {
        
        return UIModalPresentationOverFullScreen;
    }
    return UIModalPresentationFullScreen;
}

#pragma mark - Category Picker delegate

- (void)updateCategoryForUncategorizedItemsForLocation:(DTCountLocation *)location
{
    [self updateInventoryForTask:UpdateEmptyCategoryForItems];
    
}

#pragma mark - CountPad Delegate

- (void)countPadResult:(int)result
{
    [self.countPadController dismissViewControllerAnimated:YES completion:^{
        self.countPadController = nil;
        
    }];
    
    if (result <= 1)
    {
        [self.countBySegmentedControl setSelectedSegmentIndex:0];
        result = 1;
    }
    else if (result == 3) [self.countBySegmentedControl setSelectedSegmentIndex:1];
    else {
        if (self.negateCountToggle.isSelected) {
            [self.countBySegmentedControl setTitle:[NSString stringWithFormat:@"-%d", result] forSegmentAtIndex:2];
        }
        else [self.countBySegmentedControl setTitle:[NSString stringWithFormat:@"%d", result] forSegmentAtIndex:2];
        
        countByCustom = result;
        [[AppController sharedAppController] saveCustomCountValue:countByCustom];
    }
    countBy = result;
    
    [self.itemCountAddField becomeFirstResponder];
}

#pragma mark - CountAid delegate

- (void)resetCountsNowReplacingCompare:(BOOL)replace;
{
    [self.compareHelpNavController dismissViewControllerAnimated:YES completion:^{
        self.compareHelpNavController = nil;
        if (replace) {
            //[self.delegate resetSecretLocationCounts];
            [self updateInventoryForTask:ClearAllCountsReplaceInventory];
        }
        else {
            [self updateInventoryForTask:ClearAllCountsKeepInventory];
        }
    }];
}

- (void)exportAidRequest
{
    [self.compareHelpNavController dismissViewControllerAnimated:YES completion:^{
        self.compareHelpNavController = nil;
    }];
    
    DataDocViewController *exportViewController = [[DataDocViewController alloc] initForExportOnly];
    exportViewController.includeImport = NO;
    exportViewController.showMismatchSwitch = NO;
    exportViewController.exportFileName = NSLocalizedString(@"dCount_totals", @"dCount_totals");
    exportViewController.itemsToExport = [itemsTotalList copy];
    exportViewController.delegate = self;
    exportViewController.needsDoneButton = YES;
    if ([MFMailComposeViewController canSendMail]) {
        // We must always check whether the current device is configured for sending emails
        exportViewController.includeEmailExport = YES;
    }
    exportViewController.headerText = NSLocalizedString(@"Totals", @"Totals");
    exportViewController.dismissBlock = ^{
        self.exportMenuNavController = nil;
    };
    
    UINavigationController *navCtl = [[UINavigationController alloc] initWithRootViewController:exportViewController];
    navCtl.modalPresentationStyle = UIModalPresentationPopover;
    
    self.exportMenuNavController = navCtl;
    
    [self presentViewController:self.exportMenuNavController animated:YES completion:nil];
    UIPopoverPresentationController *presentationController = [self.exportMenuNavController popoverPresentationController];
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    presentationController.barButtonItem = self.countTotalButton;
    presentationController.sourceView = self.view;
    presentationController.delegate = self;
}

- (void)importAidRequestIsGuided:(BOOL)guided
{
    [self.compareHelpNavController dismissViewControllerAnimated:YES completion:^{
        self.compareHelpNavController = nil;
        
        DataDocViewController *importViewController = [[DataDocViewController alloc] initForImportOnlyWithGuided:guided];
        importViewController.includeImport = YES;
        importViewController.showMismatchSwitch = NO;
        importViewController.delegate = self;
        importViewController.needsDoneButton = YES;
        importViewController.title = NSLocalizedString(@"Import", @"Import");
        importViewController.headerText = NSLocalizedString(@"Totals", @"Totals");
        importViewController.dismissBlock = ^{
            self.exportMenuNavController = nil;
        };
        
        UINavigationController *navCtl = [[UINavigationController alloc] initWithRootViewController:importViewController];
        navCtl.modalPresentationStyle = UIModalPresentationPopover;
        
        self.exportMenuNavController = navCtl;
        
        self.exportMenuNavController.modalPresentationStyle = UIModalPresentationPopover;
        [self presentViewController:self.exportMenuNavController animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [self.exportMenuNavController popoverPresentationController];
        presentationController.barButtonItem = self.countTotalButton;
        presentationController.sourceView = self.view;
        presentationController.delegate = self;
    }];
}


#pragma mark - DataDoc Delegate

- (void)dataDocumentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker forImport:(BOOL)isImport
{
    if (documentPicker) {
        documentPicker.delegate = self;
        documentPickerForImport = isImport;
        
        self.docPickerController = documentPicker;
        
        if (self.totalCountNavController != nil) {
            [self.totalCountNavController dismissViewControllerAnimated:YES completion:^{
                self.totalCountNavController = nil;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.24 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self.navigationController presentViewController:self.docPickerController animated:YES completion:nil];
                });
                
            }];
        }
        else if (self.exportMenuNavController != nil) {
            [self.exportMenuNavController dismissViewControllerAnimated:YES completion:^{
                self.exportMenuNavController = nil;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.24 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self.navigationController presentViewController:self.docPickerController animated:YES completion:nil];
                });
            }];
        }
        else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.24 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.navigationController presentViewController:self.docPickerController animated:YES completion:nil];
            });
        }
    }
    else {
        UIAlertController __weak *weakAlert = nil;   // new in iOS 8, replaces UIAlertView and sheet
        
        NSString *alertMessage = NSLocalizedString(@"ErrorOpenDocPickerMessage", @"Unable to open storage provider at this time. Please try again later.");
        NSString *alertTitle = NSLocalizedString(@"ErrorOpenDocPickerTitle", @"Try again later");
        
        UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:alertTitle
                                                                            message:alertMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        weakAlert = alertSheet;
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alertSheet addAction:defaultAction];
        [self presentViewController:alertSheet animated:YES completion:nil];
    }
    
}

- (void)dataDocOpenInWithURL:(NSURL *)exportedFileUrl
{
    UIDocumentInteractionController *docCtl = [UIDocumentInteractionController interactionControllerWithURL:exportedFileUrl];
    docCtl.delegate = self;
    
    if (docCtl.UTI == nil) {
        NSLog(@" setting UTI");
        NSString *lastPath = [exportedFileUrl lastPathComponent];
        if ([lastPath hasSuffix:@"dcz"]) {
            docCtl.UTI = @"com.dracotorre.dcount.dcz";
        }
        else if ([lastPath hasSuffix:@"csv"]) {
            docCtl.UTI = @"public.comma-separated-values-text";
        }
    }
    
    if (self.totalCountNavController != nil) {
        [self.totalCountNavController dismissViewControllerAnimated:YES completion:^{
            self.totalCountNavController = nil;
            [self performSelector:@selector(openInPresentation:) withObject:docCtl afterDelay:0.2f];
        }];
    }
    else if (self.exportMenuNavController != nil) {
        [self.exportMenuNavController dismissViewControllerAnimated:YES completion:^{
            self.exportMenuNavController = nil;
            [self performSelector:@selector(openInPresentation:) withObject:docCtl afterDelay:0.2f];
        }];
    }
    else {
        [self performSelector:@selector(openInPresentation:) withObject:docCtl afterDelay:0.2f];
    }
}

- (void)dataDocShareQRCodeImage:(UIImage *)qrImage atFileURL:(NSURL *)exportedFileUrl
{
    UIDocumentInteractionController *docCtl = [UIDocumentInteractionController interactionControllerWithURL:exportedFileUrl];
    docCtl.delegate = self;
    
    if (self.totalCountNavController != nil) {
        [self.totalCountNavController dismissViewControllerAnimated:YES completion:^{
            self.totalCountNavController = nil;
            [self performSelector:@selector(openInDocPreview:) withObject:docCtl afterDelay:0.2f];
        }];
    }
    else if (self.exportMenuNavController != nil) {
        [self.exportMenuNavController dismissViewControllerAnimated:YES completion:^{
            self.exportMenuNavController = nil;
            [self performSelector:@selector(openInDocPreview:) withObject:docCtl afterDelay:0.2f];
        }];
    }
    else {
        [self performSelector:@selector(openInDocPreview:) withObject:docCtl afterDelay:0.2f];
    }

}

- (void)openInDocPreview:(UIDocumentInteractionController *)docToOpenInController
{
    self.docToOpenInOtherController = docToOpenInController;
    
    BOOL isValidOpen = [self.docToOpenInOtherController presentPreviewAnimated:YES];
    if (!isValidOpen) {
        NSString *alertMessage = NSLocalizedString(@"NoAppMsg", @"There are no apps available to open in.");
        NSString *alertTitle = NSLocalizedString(@"NoAppTitle", @"No app: No app to open in");
        [self displayAlertWithTitle:alertTitle withMessage:alertMessage];
    }
}

- (void)openInPresentation:(UIDocumentInteractionController *)docToOpenInController
{
    self.docToOpenInOtherController = docToOpenInController;
    
    BOOL isValidOpen = [self.docToOpenInOtherController presentOpenInMenuFromBarButtonItem:self.actionButton animated:YES];
    if (!isValidOpen) {
        NSString *alertMessage = NSLocalizedString(@"NoAppMsg", @"There are no apps available to open in.");
        NSString *alertTitle = NSLocalizedString(@"NoAppTitle", @"No app: No app to open in");
        [self displayAlertWithTitle:alertTitle withMessage:alertMessage];
    }
}

- (void)dataDocSendMailWithFileURL:(NSURL *)exportedFileUrl forFileName:(NSString *)fileName
{
    // for safety, check mail even though we should have disabled mail selection
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    
    if (self.totalCountNavController != nil) {
        [self.totalCountNavController dismissViewControllerAnimated:YES completion:^{
            self.totalCountNavController = nil;
            if (mailClass) {
                if ([mailClass canSendMail]) {
                    [self displayComposerSheetWithContentsOfURL:exportedFileUrl forFileName:fileName];
                }
            }
        }];
    }
    else if (self.exportMenuNavController != nil) {
        [self.exportMenuNavController dismissViewControllerAnimated:YES completion:^{
            self.exportMenuNavController = nil;
            if (mailClass) {
                if ([mailClass canSendMail]) {
                    [self displayComposerSheetWithContentsOfURL:exportedFileUrl forFileName:fileName];
                }
            }
        }];
    }
    else {
        if (mailClass) {
            if ([mailClass canSendMail]) {
                [self displayComposerSheetWithContentsOfURL:exportedFileUrl forFileName:fileName];
            }
        }
    }
}

- (void)printRequestForOutputText:(NSString *)text
{
    if (self.totalCountNavController != nil) {
        [self.totalCountNavController dismissViewControllerAnimated:YES completion:^{
            self.totalCountNavController = nil;
            [self doPrintDocument:text fromBarButton:self.countTotalButton];
        }];
    }
    else if (self.exportMenuNavController != nil) {
        [self.exportMenuNavController dismissViewControllerAnimated:YES completion:^{
            self.exportMenuNavController = nil;
            [self doPrintDocument:text fromBarButton:self.actionButton];
        }];
    }
    else {
        [self doPrintDocument:text fromBarButton:self.actionButton];
    }
}

#pragma mark - UIDocument picker delegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    if (documentPickerForImport) {
        documentPickerForImport = NO;
        
        //NSLog(@"  url: %@", url);
        [[AppController sharedAppController] saveContext];
        
        // see NewBox Apple demo 2014 WWDC
        // notes on https://developer.apple.com/library/ios/documentation/FileManagement/Conceptual/DocumentPickerProgrammingGuide/AccessingDocuments/AccessingDocuments.html
        //   do not really need to call security scope because using UIDocument sublcass, but let's check anyway
        BOOL accessingSecurityScopeOK = [url startAccessingSecurityScopedResource];
        
        // don't call ubiquity URL here; call on secondary thread at start; needs to be called at least once
        
        
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
        NSError *error;
        [fileCoordinator coordinateReadingItemAtURL:url options:0 error:&error byAccessor:^(NSURL *newURL) {
            NSURL *importUrl = [[AppController sharedAppController] urlForTemporaryFileSavedWithFileName:@"tempImport" withFileExtension:@"dcz"];
            NSData *data = [NSData dataWithContentsOfURL:newURL];
            [data writeToURL:importUrl atomically:YES];
        }];
        
        
        NSURL *importUrl = [[AppController sharedAppController] urlForTemporaryFileSavedWithFileName:@"tempImport" withFileExtension:@"dcz"];
        
        [self.delegate importDataAtURL:importUrl];
        
        if (accessingSecurityScopeOK) {
           [url stopAccessingSecurityScopedResource];
        }
    }
    self.docPickerController = nil;
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    self.docPickerController = nil;
}

#pragma mark - UIDocumentInteraction delegate (Open In)

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController *)controller
{
    UIView *bView = (UIView *)[self.actionButton performSelector:@selector(view)];
    CGRect superFrame = bView.superview.frame;
    return superFrame;
}

/*
- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    NSLog(@"open-in begin send");
}
 */

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    NSString *filePath = [NSString stringWithUTF8String:[controller.URL fileSystemRepresentation]];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    NSError *error;
    [filemgr removeItemAtPath:filePath error:&error];
    self.docToOpenInOtherController = nil;
}
/*
- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    NSLog(@" doc open-in did dismiss");
    
}
 */

#pragma mark - Mail

// formerly in DetailViewController_iPad
- (void)displayComposerSheetWithContentsOfURL:(NSURL *)url forFileName:(NSString *)fileShortName
{
    NSData *countData = [self exportDczToNSDataFromURL:url];
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    [mailViewController setMailComposeDelegate:self];
    [mailViewController setSubject:@"Dee Count"];
    
    [mailViewController addAttachmentData:countData mimeType:@"application/dcount" fileName:fileShortName];
    [mailViewController setToRecipients:[NSArray array]];
    [mailViewController setMessageBody:@"" isHTML:NO];
    [mailViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.navigationController presentViewController:mailViewController animated:YES completion:nil];
    });
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    //message.hidden = NO;
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            //message.text = @"Result: canceled";
            break;
        case MFMailComposeResultSaved:
            //message.text = @"Result: saved";
            break;
        case MFMailComposeResultSent:
            //message.text = @"Result: sent";
            break;
        case MFMailComposeResultFailed:
            //message.text = @"Result: failed";
            break;
        default:
            //message.text = @"Result: not sent";
            break;
    }
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (NSData *)exportDczToNSDataFromURL:(NSURL *)url
{
    NSError *error;
    
    NSFileWrapper *dirWrapper = [[NSFileWrapper alloc] initWithURL:url options:0 error:&error];
    if (dirWrapper == nil) {
        NSLog(@"Error creating directory wrapper: %@", error.localizedDescription);
        return nil;
    }
    
    //NSData *dirData = [dirWrapper serializedRepresentation];
    NSData *dirData2 = [dirWrapper regularFileContents];
    return dirData2;
}

- (void)importUrl:(NSURL *)url
{
    if (url != nil) {
        [[AppController sharedAppController] saveContext];
        [self enableLayout:NO animated:YES forDuration:0.40f completion:^(BOOL fin) {
            [self.delegate importDataAtURL:url];
        }];
        
    }
}

#pragma mark - DeleteConfirm Delegate

- (void)deletionConfirmed:(BOOL)confirm forKey:(int)key
{
    if (self.deleteConfirmNavController != nil) {
        [self.deleteConfirmNavController dismissViewControllerAnimated:YES completion:^{
            self.deleteConfirmNavController = nil;
            if (confirm && key == 1) {
                [logItems removeAllItems];
                [self configureBarButtons:NO];
                [self.delegate deleteMyLocationAndGoToLocationLabel:nil];
            }
        }];
    }
}




#pragma mark - ItemCell Delegates

- (void)selectedItemCodeToIncrement:(NSString *)code
{
    NSInteger value = countBy;
    if (self.negateCountToggle.selected) {
        value = value * -1;
    }
    [self addCountForLabel:code withValue:value performLog:YES showSelectedItem:NO];
    [self selectItemByLabel:code showDetails:NO withScroll:UITableViewScrollPositionNone];
    [self addCountItem:nil];
    [self.itemCountAddField setText:@""];
}

- (void)selectedItemDetailsForLabel:(NSString *)label
{
    if (self.itemDetailNavController != nil) {
        [self.itemDetailNavController dismissViewControllerAnimated:YES completion:^{
            self.itemDetailNavController = nil;
        }];
        
    }
    else if (self.totalCountNavController != nil) {
        [self.totalCountNavController dismissViewControllerAnimated:YES completion:^{
            self.totalCountNavController = nil;
        }];
    }
    
    DTCountItem *itemSelected = nil;
    int selectedIndex = -1;
    for (int i = 0; i < (int)itemsAtLoc.count; ++i)
    {
        DTCountItem *itm = [itemsAtLoc objectAtIndex:i];
        if ([label compare:[itm valueForKey:@"label"] options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            itemSelected = itm;
            selectedIndex = i;
            break;
        }
    }
    if (itemSelected != nil) {
        ItemDetailViewController *itemDetailCtl = [[ItemDetailViewController alloc] init];
        
        [itemDetailCtl setItem:itemSelected];
        [itemDetailCtl setLocSelectDelegate:self];
        itemDetailCtl.dismissBlock = ^{
            [self itemDetailsClosedForSelectedIndex:selectedIndex];
            self.itemDetailNavController = nil;
        };
        itemDetailCtl.needsDoneButton = YES;
        
        UINavigationController *navCtl = [[UINavigationController alloc] initWithRootViewController:itemDetailCtl];
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            navCtl.modalPresentationStyle = UIModalPresentationPopover;
        }
        else {
            navCtl.modalPresentationStyle = UIModalPresentationFullScreen;
        }
        
        self.itemDetailNavController = navCtl;
        
        NSIndexPath *indexPath = [self.itemListTableView indexPathForSelectedRow];
        CGRect frame = [self.itemListTableView rectForRowAtIndexPath:indexPath];
        frame = CGRectOffset(frame, -self.itemListTableView.contentOffset.x - 11.0f, -self.itemListTableView.contentOffset.y + self.itemListTableView.frame.origin.y);
        
        [self presentViewController:self.itemDetailNavController animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [self.itemDetailNavController popoverPresentationController];
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
        presentationController.sourceRect = frame;
        presentationController.sourceView = self.view;
        presentationController.delegate = self;
    }
    
}

- (void)itemDetailsClosedForSelectedIndex:(int)index
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    if (index < 0 || index >= itemsAtLoc.count) {
        indexPath = [self.itemListTableView indexPathForSelectedRow];
    }
    if (indexPath.row < 0) {
        [self.itemListTableView reloadData];
    }
    else {
        [self.itemListTableView beginUpdates];
        [self.itemListTableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.itemListTableView endUpdates];
    }
}

#pragma mark - LocationSelectActionDelegate

- (void) selectedLocation:(DTCountLocation *)loc selectedItemLabel:(NSString *)label
{
    // sometimes this isn't on main thread - user didselect cell - why?
    //  is converted the DTCountLocation take just enough time to fall off main?
    if (self.itemDetailNavController != nil && self.itemDetailNavController.isViewLoaded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.itemDetailNavController dismissViewControllerAnimated:YES completion:^{
                self.itemDetailNavController = nil;
                [self selectLocation:loc withSelectedItem:label];
            }];
        });
        
    }
    else if (self.totalCountNavController != nil && self.totalCountNavController.isViewLoaded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.totalCountNavController dismissViewControllerAnimated:YES completion:^{
                self.totalCountNavController = nil;
                [self selectLocation:loc withSelectedItem:label];
            }];
        });
    }
    else {
        [self selectLocation:loc withSelectedItem:label];
    }
}

- (void)selectLocation:(DTCountLocation *)loc withSelectedItem:(NSString *)label
{
    DTCountLocation *detailLoc = (DTCountLocation *)self.detailItem;
    if (loc == detailLoc) {
        [self selectItemByLabel:label showDetails:NO withScroll:UITableViewScrollPositionMiddle];
    }
    else {
        [logItems removeAllItems];
        [self configureBarButtons:NO];
        [self enableLayout:NO animated:NO forDuration:0.40f completion:^(BOOL fin) {
            [self configureBarButtons:NO];
            [self.delegate selectLocation:loc withItemName:label];
        }];
        
    }
}

#pragma mark - Update Inventory Operation delegate

- (void)doneUpdatingInventoryForProcess:(InventoryUpdateOperation *)updateOp
{
    NSArray *resultAllItems = updateOp.itemsList;
    UpdateInventoryTask task = updateOp.clearTask;
    NSString *key = [self inventoryUpdateOpKeyForTask:task];
    
    [self.pendingCountUpdateOps.bgOpInProgress removeObjectForKey:key];
    
    if (isRestartingAll) {
        isRestartingAll = NO;
        [self.delegate deleteEverythingAndRestart];
    }
    else if (layoutMode == LoadingLayout) {
        layoutMode = NormalLayout;
        [self.activityIndicator stopAnimating];
        
        if (task == UpdateEmptyCategoryForItems || task == UpdateCategoryForItems) {
            [self enableLayout:YES animated:NO forDuration:0.40f completion:^(BOOL fin) {
                [self configureBarButtons:YES];
                
                [self.delegate busyUpdating:NO];
            }];
            
        }
        else {
            if (self.secretCountCompareLocationExists == NO) {
                self.secretCountCompareLocationExists = updateOp.secretCompareLocationExists;
                if (self.secretCountCompareLocationExists) {
                    [self.delegate createdSecretCompareLocation];
                    [NSThread sleepForTimeInterval:0.1];
                }
            }
            
            [self setTotalItems:resultAllItems];
            
            [self reloadLocationItems];
            [self enableLayout:YES animated:NO forDuration:0.0f completion:^(BOOL fin) {
                [self configureBarButtons:YES];
                
                [self.delegate busyUpdating:NO];
                [self.delegate reselectMyLocation];
            }];
        }
    }
}

- (void)updateClearingCountsProgress:(NSNumber *)progress
{
    if (layoutMode != NormalLayout) {
        [self.progressView setProgress:progress.floatValue];
    }
}

#pragma mark - EditPhoto delegate

- (void)removePhoto
{
    [self.editPhotoNavController dismissViewControllerAnimated:YES completion:^{
        self.editPhotoNavController = nil;
    }];
    DTCountLocation *loc = (DTCountLocation *)self.detailItem;
    
    NSString *oldKey = [loc valueForKey:@"picuuid"];
    if (oldKey) {
        [[ImageCache sharedImageCache] deleteImageForKey:oldKey];
        [loc setValue:nil forKey:@"picuuid"];
        [loc setPicture:nil];
    }
    hasUserImage = NO;
    [self setDefaultPhoto];
    
    [self.delegate detailLocationThumbnailChanged];
}

- (void)addPhoto
{
    if (self.editPhotoNavController != nil) {
        [self.editPhotoNavController dismissViewControllerAnimated:YES completion:^{
            self.editPhotoNavController = nil;
        }];
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        
        // image picker needs a delegate to respond to msgs
        [imagePicker setDelegate:self];
        
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [imagePicker setModalPresentationStyle:UIModalPresentationCustom];
        
        self.imageLocationPickerController = imagePicker;
        
        // must be full-screen presentation per Apple documentation
        self.imageLocationPickerController.modalPresentationStyle = UIModalPresentationPopover;
        
        [self presentViewController:self.imageLocationPickerController animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [self.imageLocationPickerController popoverPresentationController];
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        presentationController.sourceRect = self.locImageButton.frame;
        presentationController.sourceView = self.view;
        presentationController.delegate = self;
    }
}

#pragma mark - Scan Code Delegate

-(void)selectedBarCode:(NSString *)barcodeString
{
    if (barcodeString != nil && barcodeString.length > 0 && barcodeString.length < 32) {
        [self.scanCodeViewController showMatchedForCodeText:barcodeString forSeconds:0.76f];
        
        // TODO: play sound option?
        
        if (self.isEditing) {
            NSString *title = [[AppController sharedAppController] stripBadCharactersFromString:barcodeString];
            if (title.length > 0) {
                NSString *titleLower = [title lowercaseString];
                if ([titleLower hasPrefix:@"http://"]) {
                    title = [title substringFromIndex:7];
                }
                else if ([titleLower hasPrefix:@"https://"]) {
                    title = [title substringFromIndex:8];
                }
                [self locImageHidden:NO animated:YES];
                
                if (self.tipTextLabel != nil && self.tipTextLabel.alpha >= 0.85f) {
                    [self hideTipTextAnimated:YES];
                }
            }
            self.locationTitleTextField.text = title;
            [self updateTitle:title];
            [self.scanCodeViewController dismissViewControllerAnimated:YES completion:^{
                [self closeScanCodeController];
            }];
        }
        else {
            if (self.negateCountToggle.selected) {
                [self.scanCodeViewController dismissViewControllerAnimated:YES completion:^{
                    [self closeScanCodeController];
                }];
            }
            [self.itemCountAddField setText:barcodeString];
            [self addCountItem:nil];
            [self.itemCountAddField setText:@""];
        }
    }
}

- (void)closeScanCodeController
{
    self.scanItemCodeButton.enabled = YES;
    self.scanTitleCodeButton.enabled = YES;
    [[AppController sharedAppController] setScanCodeMetaControl:nil];
    self.scanCodeViewController = nil;
}

#pragma mark - ToolsAction Delegate

- (void)resetCounts
{
    [self.toolsMenuNavController dismissViewControllerAnimated:YES completion:^{
        self.toolsMenuNavController = nil;
        [logItems removeAllItems];
        [self configureBarButtons:YES];
        self.itemCountLogTextView.text = @"";
        [self updateInventoryForTask:ClearAllCountsKeepInventory];
        
    }];
}

- (void)clearAllItems
{
    [self.toolsMenuNavController dismissViewControllerAnimated:YES completion:^{
        self.toolsMenuNavController = nil;
        [logItems removeAllItems];
        [self configureBarButtons:YES];
        self.itemCountLogTextView.text = @"";
        [self updateInventoryForTask:ClearAllItems];
    }];
}

- (void)clearZeroCountItems
{
    
    [self.toolsMenuNavController dismissViewControllerAnimated:YES completion:^{
        self.toolsMenuNavController = nil;
        [self updateInventoryForTask:ClearZeroCountItems];
    }];

}

/**
 *   please close nav controllers before calling
 */
- (void)updateInventoryForTask:(UpdateInventoryTask)task
{
    NSString *busyMsg;
    BOOL disableView = YES;
    
    switch (task) {
        case ClearAllCountsKeepInventory:
            busyMsg = NSLocalizedString(@"ResettingCounts", @"resetting counts to zero...");
            [itemsAtLoc removeAllObjects];
            itemsAtLoc = nil;
            [itemsShortList removeAllObjects];
            itemsShortList = nil;
            break;
        case ClearAllCountsReplaceInventory:
            busyMsg = NSLocalizedString(@"ResettingCounts", @"resetting counts to zero...");
            [itemsAtLoc removeAllObjects];
            itemsAtLoc = nil;
            [itemsShortList removeAllObjects];
            itemsShortList = nil;
            break;
        case ClearAllItems:
            busyMsg = NSLocalizedString(@"ClearAllItems", @"deleting all items and inventories...");
            [itemsAtLoc removeAllObjects];
            itemsAtLoc = nil;
            [itemsShortList removeAllObjects];
            itemsShortList = nil;
            break;
        case ClearZeroCountItems:
            busyMsg = NSLocalizedString(@"ClearZeros", @"deleting all items with zero count...");
            break;
        case UpdateEmptyCategoryForItems:
            busyMsg = NSLocalizedString(@"UpdatingCategoryForNonCatItems", @"updating category for uncategorized items at this location");
            if (itemsAtLoc.count < 300) {
                disableView = NO;
            }
            break;
        default:
            break;
    }
    
    if (disableView) {
        self.activityIndicator.alpha = 1.0f;
        [self.activityIndicator startAnimating];
        [self enableLayout:NO animated:YES forDuration:0.20f completion:^(BOOL fin) {
            
            layoutMode = LoadingLayout;
            [self.importTextView setText:busyMsg];
            self.importTextView.alpha = 0.667f;
            [self.delegate busyUpdating:YES];
            
            
            [self beginItemUpdateForTask:task];
        }];
    }
    else {
        [self beginItemUpdateForTask:task];
    }
}

- (void)beginItemUpdateForTask:(UpdateInventoryTask)task
{
    
    if (self.pendingCountUpdateOps == nil) {
        self.pendingCountUpdateOps = [[DTCBGOperationsWorker alloc] init];
    }
    
    if (task == UpdateEmptyCategoryForItems || task == UpdateCategoryForItems) {
        NSString *key = [self inventoryUpdateOpKeyForTask:task];
        if (![self.pendingCountUpdateOps.bgOpInProgress.allKeys containsObject:key]) {
            DTCountLocation *loc = (DTCountLocation *)self.detailItem;
            NSString *catLable = [loc valueForKey:@"defCatLabel"];
            InventoryUpdateOperation *iuo = [[InventoryUpdateOperation alloc] initForEmptyCategoryUpdateWithItems:itemsAtLoc forCategoryLabel:catLable withDelegate:self];
            
            [self.pendingCountUpdateOps.bgOpInProgress setObject:iuo forKey:key];
            [self.pendingCountUpdateOps.bgOpQueue addOperation:iuo];
        }
    }
    else  {
        NSString *key = [self inventoryUpdateOpKeyForTask:task];
        
        if (![self.pendingCountUpdateOps.bgOpInProgress.allKeys containsObject:key]) {
            InventoryUpdateOperation *cco = [[InventoryUpdateOperation alloc] initWithTotalItems:[itemsTotalList copy] forClearTask:task withDelegate:self];
            [itemsTotalList removeAllObjects];
            itemsTotalList = nil;
            
            [self.pendingCountUpdateOps.bgOpInProgress setObject:cco forKey:key];
            [self.pendingCountUpdateOps.bgOpQueue addOperation:cco];
        }
    }
}

- (void)restartAll
{
    [self.toolsMenuNavController dismissViewControllerAnimated:YES completion:^{
        self.toolsMenuNavController = nil;
        [self enableLayout:NO animated:NO forDuration:0.0f completion:nil];
        
        /*
        [itemsAtLoc removeAllObjects];
        [itemsShortList removeAllObjects];
        [itemsTotalList removeAllObjects];
        itemsAtLoc = nil;
        itemsShortList = nil;
        itemsTotalList = nil;
        [logItems removeAllItems];
        [self configureBarButtons:NO];
        
        //[self.delegate deleteEverythingAndRestart];
        */
        isRestartingAll = YES;
        [logItems removeAllItems];
        [self configureBarButtons:YES];
        self.itemCountLogTextView.text = @"";
        [self updateInventoryForTask:ClearAllItems];
    }];
}

- (void)showCompareCountHelp
{
    [self.toolsMenuNavController dismissViewControllerAnimated:YES completion:^{
        self.toolsMenuNavController = nil;
        
        DTCountAidManageViewController *compareCountHelpManController = [[DTCountAidManageViewController alloc] initForCompareCountsExists:self.secretCountCompareLocationExists];
        compareCountHelpManController.countAidDelegate = self;
        compareCountHelpManController.dismissBlock = ^{
            self.compareHelpNavController = nil;
        };
        self.compareHelpNavController = [[UINavigationController alloc] initWithRootViewController:compareCountHelpManController];
        self.compareHelpNavController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentViewController:self.compareHelpNavController animated:YES completion:nil];
        UIPopoverPresentationController *presentationController = [self.compareHelpNavController popoverPresentationController];
        //presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        presentationController.sourceView = self.view;
        presentationController.delegate = self;
        
    }];
}

#pragma mark - public methods

- (BOOL)closedScannerEnableScanning:(BOOL)enabled
{
    BOOL result = NO;
    if (!enabled && self.scanCodeViewController) {
        result = YES;
        [self.scanCodeViewController dismissViewControllerAnimated:YES completion:^{
            [[AppController sharedAppController] setScanCodeMetaControl:nil];
            self.scanCodeViewController = nil;
        }];
    }
    else {
        self.scanItemCodeButton.enabled = enabled;
        self.scanTitleCodeButton.enabled = enabled;
    }
    return result;
}

- (void)negateToggleChangedTo:(BOOL)toggleOn
{
    if (layoutMode == NormalLayout && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        CGFloat alpha = 0.0f;
        if (toggleOn) {
            alpha = 1.0f;
        }
        if (self.negateCountToggle.alpha == alpha) {
            return;
        }
        [UIView animateWithDuration:0.30f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.negateCountToggle.alpha = alpha;
                             
                         }
                         completion:nil];
    }
}

- (BOOL)safeToDeleteItem:(DTCountItem *)itm
{
    if (itm == nil) {
        return NO;
    }
    NSArray *inventories = [itm valueForKey:@"inventories"];
    if (inventories) {
        for (DTCountInventory *inv in inventories) {
            if ([[inv valueForKey:@"count"] intValue] > 0) {
                return NO;
            }
        }
    }
    NSString *desc = [itm valueForKey:@"desc"];
    if (desc.length > 0) {
        return NO;
    }
    
    return YES;
}

- (void)showLocationNameExistsReminderForLabel:(NSString *)locLabel
{
    [self.itemCountAddField setText:@""];
    [self.view endEditing:YES];
    
    if (itemsAtLoc.count == 0) {
        [self performSelector:@selector(showLocationNameExistsForEmptyLocationWithLabel:) withObject:locLabel afterDelay:0.24f];
    }
    else {
        [self performSelector:@selector(showlocationNameExistsForFullLocationWithLabel:) withObject:locLabel afterDelay:0.24f];
    }
}

- (void)showlocationNameExistsForFullLocationWithLabel:(NSString *)locLabel
{
    UIAlertController __weak *weakAlert = nil;   // new in iOS 8, replaces UIAlertView and sheet
    
    NSString *alertMesage = [NSString stringWithFormat:@"'%@' %@", locLabel, NSLocalizedString(@"SameOldLocationNameMessage", @"location already exists. You may keep this name, or rename this location.")];
    
    NSString *alertTitle = NSLocalizedString(@"Location Name Exists", @"Location Name Exists");
    
    UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:alertTitle message:alertMesage preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [weakAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alertSheet addAction:defaultAction];
    
    [self presentViewController:alertSheet animated:YES completion:nil];
}

- (void)showLocationNameExistsForEmptyLocationWithLabel:(NSString *)locLabel
{
    UIAlertController __weak *weakAlert = nil;   // new in iOS 8, replaces UIAlertView and sheet
    
    NSString *alertMesage = [NSString stringWithFormat:@"'%@' %@", locLabel, NSLocalizedString(@"SameNewLocationNameMessage", @"location already exists. Would you like to delete this duplicated location and go there now? Cancel to keep.")];
    
    NSString *alertTitle = NSLocalizedString(@"Location Name Exists", @"Location Name Exists");
    
    UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:alertTitle message:alertMesage preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Delete") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakAlert dismissViewControllerAnimated:YES completion:nil];
        [self enableLayout:NO animated:YES forDuration:0.42f completion:^(BOOL fin) {
            [logItems removeAllItems];
            [self configureBarButtons:NO];
            [self.delegate deleteMyLocationAndGoToLocationLabel:locLabel];
        }];
        
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [weakAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alertSheet addAction:defaultAction];
    [alertSheet addAction:cancelAction];
    [self presentViewController:alertSheet animated:YES completion:nil];
}


// expected call from AppDelegate on button press delegate
- (void)splitViewModeChangedTo:(UISplitViewControllerDisplayMode)mode
{
    if (mode == UISplitViewControllerDisplayModeAllVisible) {
        
        self.mySize = CGSizeMake(self.splitViewController.view.frame.size.width - 296.0f, self.view.frame.size.height);
    }
    else {
        self.mySize = CGSizeMake(self.splitViewController.view.frame.size.width, self.view.frame.size.height);
    }
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
        self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        
        if (mode == UISplitViewControllerDisplayModeAllVisible) {
            if (!layoutIsNarrow) {
                
                [self narrowLayoutAnimated:YES];
                //[self compactLayoutAnimated:YES forTraitCollection:self.traitCollection];
                
                //[self configureBarButtons:YES];
            }
        }
        else if (layoutIsNarrow) {
            [self wideLayoutAnimated:YES];
            //[self compactLayoutAnimated:YES forTraitCollection:self.traitCollection];
            
            //[self configureBarButtons:YES];
        }
    }
    
}

- (void)selectItemByLabel:(NSString *)label showDetails:(BOOL)showDetailLayout withScroll:(UITableViewScrollPosition)scrollPosition
{
    selectedDetailLabel = nil;
    if (itemsAtLoc != nil && [self.navigationController isViewLoaded] && self.navigationController.view.window) {
        
        if (layoutMode == NormalLayout) {
            NSIndexPath *ip = [self indexPathForItemWithLabel:label];
            
            
            if (showDetailLayout) {
                [self.view endEditing:YES];
                [self.itemListTableView selectRowAtIndexPath:ip animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                
                [self performSelector:@selector(selectedItemDetailsForLabel:) withObject:label afterDelay:0.5f];
                //[self selectedItemDetailsForLabel:label];
            }
            else {
                [self.itemListTableView selectRowAtIndexPath:ip animated:YES scrollPosition:scrollPosition];
            }
        }
        else if (layoutMode != ImportLayout && layoutMode != LoadingLayout) {
            selectedDetailLabel = label;
            [self enableLayout:YES animated:YES forDuration:0.333f completion:nil];
        }
        
    }
    else if (showDetailLayout) {
        selectedDetailLabel = label;
    }
    
    
}

- (void)setProgress:(double)progress
{
    [self.progressView setProgress:progress];
    if (self.activityIndicator.isAnimating == NO) {
        [self.activityIndicator startAnimating];
    }
}

#pragma mark - other private methods

- (void)assetsLibraryCheck
{
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
        AVAuthorizationStatus camAuth = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (camAuth == AVAuthorizationStatusAuthorized || camAuth == AVAuthorizationStatusNotDetermined) {
            self.isScanCodeAvailable = YES;
            self.isCameraAvailable = YES;
        }
        else {
            self.isCameraAvailable = NO;
            self.isScanCodeAvailable = NO;
        }
    }
    ALAuthorizationStatus photoAuth = [ALAssetsLibrary authorizationStatus];
    if (photoAuth == ALAuthorizationStatusAuthorized || photoAuth == ALAuthorizationStatusNotDetermined) {
        self.isPhotoLibAvailable = YES;
    }
    else self.isPhotoLibAvailable = NO;
}

- (void)handleStartupError
{
    if (self.importStartupError > 0) {
        [self handleImportError:self.importStartupError];
    }
    else if (self.importStartupError == -100) {
        [self handleUpgradeResultMessage];
    }
    self.importStartupError = 0;
}

- (void)handleImportError:(int)importHasError
{
    if (importHasError > 0) {
        UIAlertController __weak *weakAlert = nil;   // new in iOS 8, replaces UIAlertView and sheet
        
        NSString *alertMessage = NSLocalizedString(@"ImportErrMsg", @"Import file format problem.");
        NSString *alertTitle = NSLocalizedString(@"ImportErrorTitle", @"Import Error");
        if (importHasError > 1) {
            alertMessage = NSLocalizedString(@"ImportFileErrMsg", @"Import file has a problem.");
        }
        UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:alertTitle
                                                                            message:alertMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        weakAlert = alertSheet;
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alertSheet addAction:defaultAction];
        [self presentViewController:alertSheet animated:YES completion:nil];
        
    }
}

- (void)handleUpgradeResultMessage
{
    UIAlertController __weak *weakAlert = nil;   // new in iOS 8, replaces UIAlertView and sheet
    
    NSString *alertMessage = NSLocalizedString(@"UpgradeMessage", @"Your data has been upgraded. You may categorize your items, or store additional information.");
    NSString *alertTitle = NSLocalizedString(@"Data Upgraded", @"Data Upgraded");
    
    UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:alertTitle
                                                                        message:alertMessage
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    weakAlert = alertSheet;
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    [alertSheet addAction:defaultAction];
    [self presentViewController:alertSheet animated:YES completion:nil];
}

- (CGFloat)imageYPositionForTraitCollection:(UITraitCollection *)traitCollection forNarrowLayout:(BOOL)narrow
{
    CGFloat y = 78.0f;
    
    // order matter since we may not have all the information in trait class
    if (!narrow && traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact)
    {
        y = self.navigationController.navigationBar.frame.size.height + 10.0f;
    }
    else if (narrow && traitCollection.verticalSizeClass != UIUserInterfaceSizeClassCompact) {
        y = 108.0f;
    }
    return y;
}

- (NSString *)inventoryUpdateOpKeyForTask:(UpdateInventoryTask)task
{
    if (task == ClearAllCountsReplaceInventory || task == ClearAllCountsKeepInventory) {
        return @"ResetCountsKey";
    }
    if (task == ClearAllItems) {
        return @"ClearAllItemsKey";
    }
    if (task == ClearZeroCountItems) {
        return  @"ClearItemZerosKey";
    }
    else if (task == UpdateEmptyCategoryForItems || task == UpdateCategoryForItems) {
        return @"UpdateCatsForItems";
    }
    return @"ClearItKey";
}

/**
 *    Help prevent two load/unload views happening at same time.
 *    Normally tap-outside closes a popover, but sometimes doesn't.
 */
- (BOOL)checkPopoversToDismiss
{
    if (self.tipTextLabel != nil) {
        [self hideTipTextAnimated:YES];
    }
    if ([self imageIsBig]) {
        [self animateImageZoom];
    }
    BOOL didDismiss = NO;
    
    if (self.toolsMenuNavController != nil && self.toolsMenuNavController.isViewLoaded) {
        didDismiss = YES;
        [self.toolsMenuNavController dismissViewControllerAnimated:YES completion:^{
            self.toolsMenuNavController = nil;
        }];
    }
    else if (self.itemDetailNavController != nil && self.itemDetailNavController.isViewLoaded) {
        didDismiss = YES;
        [self.itemDetailNavController dismissViewControllerAnimated:YES completion:^{
            self.itemDetailNavController = nil;
        }];
    }
    else if (self.totalCountNavController != nil && self.totalCountNavController.isViewLoaded) {
        didDismiss = YES;
        [self.totalCountNavController dismissViewControllerAnimated:YES completion:^{
            self.totalCountNavController = nil;
        }];
    }
    else if (self.exportMenuNavController != nil && self.exportMenuNavController.isViewLoaded) {
        didDismiss = YES;
        [self.exportMenuNavController dismissViewControllerAnimated:YES completion:^{
            self.exportMenuNavController = nil;
        }];
    }
    else if (self.categoryPickNavController != nil && self.categoryPickNavController.isViewLoaded) {
        didDismiss = YES;
        [self.categoryPickNavController dismissViewControllerAnimated:YES completion:^{
            self.categoryPickNavController = nil;
        }];
    }
    else if (self.compareHelpNavController != nil && self.compareHelpNavController.isViewLoaded) {
        didDismiss = YES;
        [self.compareHelpNavController dismissViewControllerAnimated:YES completion:^{
            self.compareHelpNavController = nil;
        }];
    }
    else if (self.categoryPickNavController != nil && self.categoryPickNavController.isViewLoaded) {
        didDismiss = YES;
        [self.categoryPickNavController dismissViewControllerAnimated:YES completion:^{
            self.categoryPickNavController = nil;
        }];
    }
    else if (self.editPhotoNavController != nil && self.editPhotoNavController.isViewLoaded) {
        didDismiss = YES;
        [self.editPhotoNavController dismissViewControllerAnimated:YES completion:^{
            self.editPhotoNavController = nil;
        }];
    }
    else if (self.imageLocationPickerController != nil && self.imageLocationPickerController.isViewLoaded) {
        didDismiss = YES;
        [self.imageLocationPickerController dismissViewControllerAnimated:YES completion:^{
            self.imageLocationPickerController = nil;
        }];
    }
    else if (self.deleteConfirmNavController != nil) {
        didDismiss = YES;
        [self.deleteConfirmNavController dismissViewControllerAnimated:YES completion:^{
            self.deleteConfirmNavController = nil;
        }];
    }
    else if (self.countPadController != nil) {
        [self.countPadController dismissViewControllerAnimated:YES completion:^{
            self.countPadController = nil;
        }];
    }
    // skipped scanner
    
    
    return didDismiss;
}

- (void)displayAlertWithTitle:(NSString *)title withMessage:(NSString *)msg
{
    UIAlertController __weak *weakAlert = nil;   // new in iOS 8, replaces UIAlertView and sheet
    
    UIAlertController *alertSheet = [UIAlertController alertControllerWithTitle:title
                                                                        message:msg
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    weakAlert = alertSheet;
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    [alertSheet addAction:defaultAction];
    [self presentViewController:alertSheet animated:YES completion:nil];
}

- (void)displayCountCompareAid
{
    
}


- (void)deleteItemAtLocation:(int)index peformLog:(BOOL)logIt
{
    //if (countTotalNavController != nil)
    //{
    //   [self clearTotalCountsController];
    //}
    DTCountItem *itm = [itemsAtLoc objectAtIndex:index];
    DTCountInventory *inventory = [self inventoryForItemAtLocation:itm];
    NSNumber *num = [NSNumber numberWithInt:0];
    int oldNum = [[inventory valueForKey:@"count"] intValue];
    NSString *txt = [itm valueForKey:@"label"];
    locationTotalItemCount -= oldNum;
    [inventory setValue:num forKey:@"count"];
    [itemsAtLoc removeObjectAtIndex:index];
    
    if (logIt) {
        // update log
        DTCountLogEntry *logEntry = [[DTCountLogEntry alloc] initWithLabel:txt withValue:oldNum * -1];
        [logItems addLogEntry:logEntry];
    }
    [self.itemCountLogTextView setText:logItems.log];
    if (logItems.count <= 1) {
        [self configureBarButtons:YES];
    }
    
    if (self.itemCountLogTextView.alpha == 0 && !layoutIsNarrow) {
        [self animateLogFadeVisible:YES];
    }
    
    BOOL keepItem = NO;
    
    //[locTotalCntTextField setText:[NSString stringWithFormat:@"%lu", (unsigned long)itmsTotalCnt]];
    [self updateCountsValuesForTotalItemsCount:locationTotalItemCount fromOldValue:locationTotalItemCount + oldNum withBlink:YES];
    
    if (itemsTotalList != nil && [self itemHasCount:itm] == NO)
    {
        // item has no count > 0 anywhere, delete its inventories
        
        NSString *itmName = [itm valueForKey:@"label"];
        
        for (int i = 0; i < [itemsShortList count]; ++i)
        {
            NSString *shortListItemName = [[itemsShortList objectAtIndex:i] valueForKey:@"label"];
            if ([itmName isEqualToString:shortListItemName]) {
                [itemsShortList removeObjectAtIndex:i];
                break;
            }
        }
        AppController *ac = [AppController sharedAppController];
        NSManagedObjectContext *moc = [ac managedObjectContext];
        
        for (int i = 0; i < (int)itemsTotalList.count; ++i)
        {
            NSString *longListItemName = [[itemsTotalList objectAtIndex:i] valueForKey:@"label"];
            if ([itmName isEqualToString:longListItemName]) {
                
                DTCountItem *itm = [itemsTotalList objectAtIndex:i];
                NSArray *inventories = [[itm valueForKey:@"inventories"] allObjects];
                NSString *description = [itm valueForKey:@"desc"];
                if (description.length > 0) keepItem = YES;
                else if (inventories)
                {
                    for (int invIndex = (int)inventories.count - 1; invIndex >= 0; --invIndex)
                    {
                        DTCountInventory *mi = (DTCountInventory *)[inventories objectAtIndex:invIndex];
                        DTCountLocation *miLoc = [mi valueForKey:@"location"];
                        NSString *miLocName = [miLoc valueForKey:@"label"];
                        
                        if ([miLocName isEqualToString:[ac totalCountsSecretLocationName]]) {
                            
                            if ([[mi valueForKey:@"count"] intValue] > 0) {
                                keepItem = YES;
                            }
                            else
                            {
                                [[miLoc mutableSetValueForKey:@"inventories"] removeObject:mi];
                                [[itm mutableSetValueForKey:@"inventories"] removeObject:mi];
                                [moc deleteObject:mi];
                                mi = nil;
                            }
                        }
                        else
                        {
                            [[miLoc mutableSetValueForKey:@"inventories"] removeObject:mi];
                            [[itm mutableSetValueForKey:@"inventories"] removeObject:mi];
                            if (mi) [moc deleteObject:mi];
                            mi = nil;
                        }
                    }
                }
                
                if (!keepItem)
                {
                    itm = [[DTCountCategoryStore sharedStore] removeCategoryFromItem:itm];
                    [moc deleteObject:itm];
                    [itemsTotalList removeObjectAtIndex:i];
                    itm = nil;
                    
                    if (itemsTotalList.count == 0) {
                        [self configureBarButtons:YES];
                    }
                }
                
                break;
            }
        }
    }
}

- (void)doPrintDocument:(NSString *)outputText fromBarButton:(UIBarButtonItem *)button
{
    // print
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    pic.delegate = self;
    
    //UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    //printInfo.outputType = UIPrintInfoOutputGeneral;
    //printInfo.jobName = self.documentName;
    //printInfo
    //pic.printInfo = printInfo;
    
    UIMarkupTextPrintFormatter *printFormatter = [[UIMarkupTextPrintFormatter alloc]
                                                  initWithMarkupText:outputText];
    [printFormatter setStartPage:0];
    [printFormatter setContentInsets:UIEdgeInsetsMake(72.0, 72.0, 72.0, 72.0)];  // 1 inch margin
    [printFormatter setMaximumContentWidth:6 * 72.0];
    
    [pic setPrintFormatter:printFormatter];
    [pic setShowsPageRange:YES];
    
    
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if (!completed && error) {
            NSLog(@"Printing could not complete because of error: %@", error);
        }
    };
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [pic presentFromBarButtonItem:button animated:YES completionHandler:completionHandler];
    }
    else {
        [pic presentAnimated:YES completionHandler:completionHandler];
    }
    
}

- (NSIndexPath *)indexPathForItemWithLabel:(NSString *)label
{
    for (int i = 0; i < itemsAtLoc.count; ++i)
    {
        DTCountItem *itm = [itemsAtLoc objectAtIndex:i];
        if ([label compare:[itm valueForKey:@"label"] options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            return [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    return nil;
}

- (DTCountInventory *)inventoryForItemAtLocation:(NSManagedObject *)item
{
    DTCountLocation *loc = (DTCountLocation *)self.detailItem;
    NSArray *inventoriesForLocation = [[loc valueForKey:@"inventories"] allObjects];
    for (DTCountInventory *mi in inventoriesForLocation) {
        if ([mi valueForKey:@"item"] == item) {
            return mi;
        }
    }
    return nil;
}

/*
 * any count for anywhere, but not including the secret location
 */
- (BOOL)itemHasCount:(DTCountItem *)item
{
    int cnt = 0;
    AppController *ac = [AppController sharedAppController];
    NSArray *inventoriesForItem = [[item valueForKey:@"inventories"] allObjects];
    for (DTCountInventory *mi in inventoriesForItem) {
        DTCountLocation *miLoc = [mi valueForKey:@"location"];
        NSString *miLocName = [miLoc valueForKey:@"label"];
        if ([miLocName isEqualToString:[ac totalCountsSecretLocationName]] == NO) {
            cnt += [[mi valueForKey:@"count"] intValue];
        }
    }
    if (cnt > 0) return YES;
    return NO;
}



- (DTCountItem *)itemInTotalsWithLabel:(NSString *)label
{
    if (itemsTotalList == nil) {
        NSArray *items = [[AppController sharedAppController] itemsInTotalListForLabel:label];
        if (items.count > 0) {
            return (DTCountItem *)[items objectAtIndex:0];
        }
    }
    else {
        for (int i = 0; i < itemsTotalList.count; ++i) {
            DTCountItem *itm = [itemsTotalList objectAtIndex:i];
            NSString *itemLabel = [itm valueForKey:@"label"];
            if ([itemLabel isEqualToString:label]) {
                return itm;
            }
        }
    }
    
    return nil;
}

- (CGSize)locationImageSizeLimitForEnlarged:(BOOL)enlarged
{
    CGFloat heightLimit = 168.0f;
    CGFloat widthLimit = 270.0f;
    
    if (enlarged) {
        
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
            heightLimit = 512.0f;
            widthLimit = 512.0f;
        }
        else if (self.mySize.width > displayNarrowWidthLimit) {
            heightLimit = 262.0f;
            widthLimit = 392.0f;
        }
        else {
            heightLimit = 240.0f;
            widthLimit = 312.0f;
            
        }
    }
    else if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        heightLimit = 152.0f;
    }
    return CGSizeMake(widthLimit, heightLimit);
}

- (void)reloadLocationItems
{
    DTCountLocation *loc = (DTCountLocation *)self.detailItem;
    
    itemsAtLoc = [[NSMutableArray alloc] init];
    NSUInteger itmsTotalCnt = 0;
    NSArray *inventoriesForLocation = [[loc valueForKey:@"inventories"] allObjects];
    for (DTCountInventory *mi in inventoriesForLocation) {
        if ([[mi valueForKey:@"count"] intValue] > 0) {
            itmsTotalCnt += [[mi valueForKey:@"count"] intValue];
            DTCountItem *itm = [mi valueForKey:@"item"];
            
            [itemsAtLoc addObject:itm];
        }
    }
    [self resortItems];
    [self.itemListTableView reloadData];
    locationTotalItemCount = itmsTotalCnt;
    NSString *totalCountString = [[AppController sharedAppController] formatNumber:itmsTotalCnt];
    self.locTotalCntTextField.text = totalCountString;
    [logItems removeAllItems];
    [self configureBarButtons:YES];
    self.itemCountLogTextView.text = @"";
    if (itemsAtLoc.count == 0) {
        self.itemCountLogTextView.text = @"";
    }
}

- (void)reloadAllItems
{
    // fetch items list
    AppController *ac = [AppController sharedAppController];
    NSArray *list = [ac loadAllItems];
    itemsTotalList = [list mutableCopy];
    
    NSLog(@"*** *** Detail ReloadItems-loaded total items: %lu ***", (unsigned long)itemsTotalList.count);
    
    if (itemsTotalList == nil) {
        itemsTotalList = [[NSMutableArray alloc] init];
    }
    
    itemsShortList = [[NSMutableArray alloc] init];
    for (int i = 0; i < itemsTotalList.count; ++i)
    {
        DTCountItem *itm = [itemsTotalList objectAtIndex:i];
        if ([self itemHasCount:itm]) [itemsShortList addObject:itm];
    }
}

- (void)resortItems
{
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"label" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sds = [NSArray arrayWithObject:sd];
    [itemsTotalList sortUsingDescriptors:sds];
    [itemsShortList sortUsingDescriptors:sds];
    [itemsAtLoc sortUsingDescriptors:sds];
    
    //[self.itemListTableView reloadData];
}

- (CGRect)tipViewFrameForTextLenght:(NSInteger)len withYOffest:(CGFloat)yOffset
{
    CGFloat ht = 66.0f;
    if (len < 92) {
        ht = 48.0f;
    }
    else if (len > 112) {
        ht = 76.0f;
    }
    return CGRectMake(self.itemListTableView.frame.origin.x,
                      self.locTotalCntTextField.frame.origin.y - 9.0f + yOffset,
                      self.itemListTableView.frame.size.width + 1,
                      ht);
}

- (void)updateCountsValuesForTotalItemsCount:(NSUInteger)totalItems fromOldValue:(NSUInteger)oldValue withBlink:(BOOL)blinkIt
{
    NSString *totalCountString = [[AppController sharedAppController] formatNumber:totalItems];
    if ([self.locTotalCntTextField.text isEqualToString:totalCountString] == NO) {
        UIColor *colorBlink = [UIColor greenColor];
        if (oldValue > totalItems) {
            colorBlink = [UIColor redColor];
        }
        else if (oldValue == totalItems) {
            colorBlink = [UIColor grayColor];
        }
        
        if (blinkIt) {
            [self animateTotalCountTextFieldToValue:totalCountString withBlinkColor:colorBlink];
        }
        else {
            [self.locTotalCntTextField setText:totalCountString];
        }
        
        
    }
    
}



@end
