//
//  AppController.h
//  Dee Count
//
//  Created by David G Shrock on 8/7/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
/*
    Updated from 2010 version
    - ARC
    - combined 2 shared controllers
    - split out Scanner Controller share into updated Library
*/

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DTCountItem.h"
#import "DTCountCategory.h"
#import "DTScanCode/DTScanCodeMetaControl.h"

@interface AppController : NSObject {
   
@private
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

+ (instancetype)sharedAppController;

// Core Data

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSArray *)loadAllCategories;
- (NSArray *)loadAllItems;
- (NSArray *)loadAllLocations;


// definitions and routine functions
@property (nonatomic, strong) NSURL *ubiquityCloudContainerForApp;
@property (nonatomic, readonly) int maxTitleLength;
@property (nonatomic, readonly) int maxDescLength;
@property (nonatomic, readonly) UIColor *barColor;
@property (nonatomic, readonly) UIColor *barLightColor;
@property (nonatomic, readonly) UIColor *barButtonColor;
@property (nonatomic, readonly) BOOL showNegateToggle;
@property (nonatomic, readonly) BOOL showZeroCounts;
@property (nonatomic, readonly) BOOL showQRFinder;
@property (nonatomic, readonly) BOOL noTapScanning;
@property (nonatomic, readonly) BOOL autoSetItemInputOnLocPick;
@property (nonatomic, readonly) BOOL userHasSeenTotalsTip;
@property (nonatomic, readonly) BOOL userHasSeenStartupTip;

- (CIImage *)createQRCodeCIImageForString:(NSString *)qrString;
- (BOOL)oldStoreDataExists;
- (NSString *)oldStoreFileName;

-(void)setScanCodeMetaControl:(DTScanCodeMetaControl *)scanCodeMetaControl;
-(void)applicationEnteredForeground;
-(void)applicationEnteredBackground;

- (NSString *)applicationDocumentsDirectory;
- (NSString *)applicationMainDirectory;
//- (void)defaultsChanged:(NSNotification *)notification;
- (void)updateDefaults:(NSUserDefaults *)defaults;
- (void)updateHasSeenTotalsExportTip:(BOOL)seen;
- (void)updateShowNegateToggle:(BOOL)enabled;
- (void)updateShowQRFinder:(BOOL)enabled;
- (void)updateAutoSetItemInputOnLocPick:(BOOL)enabled;
- (void)updateNoTapScanning:(BOOL)enabled;
- (void)updateShowZeroToUserDefaultsForEnabled:(BOOL)enabled;
- (void)cleanCacheDirectory;
- (void)cleanAllFilesInDocumentsDirectory;
- (void)cleanTempDirectory;
- (void)cleanDocumentsDirectory;
- (NSString *)totalCountsSecretLocationName;
- (NSString *)fileCsvName;
- (NSString *)fileTsvName;
- (NSString *)fileDczName;
- (void)saveContext;
- (void)rollbackContext;
/**
 * forgets objects
 */
- (void)resetContext;

// not working
//- (void)deleteStoreFile;

- (NSCharacterSet *)badCharacters;
- (NSString *)trimHeaderFromURLContent:(NSString *)content;
- (BOOL)stringContainsBadCharactersInString:(NSString *)str;
- (NSString *)stripBadCharactersFromString:(NSString *)str;
- (NSInteger)getCustomCountValue;

/**
 *  for upgrades only, use getCustomCountValue
 */
- (NSInteger)loadCustomCountValueDeprecated;
- (NSInteger)loadLastSelectedLocationIndex;

/**
 *  returns nil if not found else the item
 */
- (NSArray *)itemsInTotalListForLabel:(NSString *)label;
- (NSArray *)locationsForLabel:(NSString *)label;
- (BOOL)saveCustomCountValue:(NSInteger)customCount;
- (BOOL)saveLastSelectedLocationIndex:(NSUInteger)index;
- (NSString *)formatNSNumber:(NSNumber *)number;
- (NSString *)formatNumber:(NSUInteger)num;
- (void)updateHAsSeenStartupTips:(BOOL)seen;
- (NSURL *)urlForTemporaryFileSavedWithFileName:(NSString *)filename withFileExtension:(NSString *)extension;


@end
