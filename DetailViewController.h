//
//  DetailViewController.h
//  Dee Count
//
//  Created by David G Shrock on 8/7/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
//  updated from 2010 version 1, DetailViewController_iPad
//  - ARC and style and iOS 8 layout
//  - delegate improvements
//  - moved locals and IBOutlets to implementation file

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "InventoryUpdateOperation.h"

@class DTCountItem;
@class DTCountLocation;

typedef enum DisplayLayoutMode : int {
    NormalLayout, EditingLayout, ImportLayout, LoadingLayout, UpdateDataLayout
}DisplayLayoutMode;

@protocol DCountDetailLocationUpdatedDelegate;

@interface DetailViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UIPopoverPresentationControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPrinterPickerControllerDelegate, UIPrintInteractionControllerDelegate, UIDocumentPickerDelegate, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate>

/**
 *  please call setLayoutMode first if needed
 */
@property (strong, nonatomic) id detailItem;
@property (nonatomic, weak) id<DCountDetailLocationUpdatedDelegate> delegate;
/**
 * call before setDetailItem
 */
@property (nonatomic) DisplayLayoutMode layoutMode;
@property (nonatomic) BOOL isScanCodeAvailable;
@property (nonatomic) BOOL isCameraAvailable;
@property (nonatomic) BOOL isPhotoLibAvailable;
@property (nonatomic) BOOL isFirstLocation;
@property (nonatomic) BOOL secretCountCompareLocationExists;
@property (nonatomic) int importStartupError;

/**
 *  if making new detail, copy existing totals from here
 *  to new using setTotalItemsAll - limits reloads
 */
@property (nonatomic, copy, readonly) NSArray *myTotalItems;
@property (nonatomic, copy, readonly) NSArray *myTempTotalItems;
@property (nonatomic, copy) NSArray *myShortItems;

/**
 * returns true if closed scanner
 */
- (BOOL)closedScannerEnableScanning:(BOOL)enabled;
- (BOOL)safeToDeleteItem:(DTCountItem *)itm;
- (void)selectItemByLabel:(NSString *)label showDetails:(BOOL)showDetailLayout withScroll:(UITableViewScrollPosition)scrollPosition;
- (void)setProgress:(double)progress;
//- (void)loadDone:(int)importError;
- (void)splitViewModeChangedTo:(UISplitViewControllerDisplayMode)mode;
- (void)negateToggleChangedTo:(BOOL)toggleOn;
//- (void)handleImportError:(int)importHasError;
//- (void)handleUpgradeResultMessage;

- (void)showLocationNameExistsReminderForLabel:(NSString *)locLabel;

/**
 *  set totals here after first time by copying old items arrays - called by Master
 */
- (void)setTotalItemsAll:(NSArray *)totals shortItems:(NSArray *)shortItems tempItems:(NSArray *)tmps;
/**
 *  set total items here on startup, delete location, or after import - assumed called by Master
 */
- (void)setTotalItems:(NSArray *)itms;


@end

@protocol DCountDetailLocationUpdatedDelegate <NSObject>

- (void)createdSecretCompareLocation;
- (void)detailLocationSaved;
- (void)detailLocationTitleChanged;
- (void)detailLocationThumbnailChanged;
//- (void)selectLocationByLabel:(NSString *)label withItemName:(NSString *)itemLabel;
- (void)selectLocation:(DTCountLocation *)loc withItemName:(NSString *)itemLabel;
- (void)importDataAtURL:(NSURL *)url;
- (void)cancelImport;
- (void)deleteMyLocationAndGoToLocationLabel:(NSString *)label;
- (void)deleteEverythingAndRestart;
- (void)reselectMyLocation;
- (void)resetSecretLocationCounts;
/**
 *  lengthy update op, recommending disable location changes until NO
 */
- (void)busyUpdating:(BOOL)isBusy;
//- (void)deleteLocation;
- (void)cameraStatusUpdated;
@end

