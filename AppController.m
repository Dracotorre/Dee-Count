//
//  AppController.m
//  Dee Count
//
//  Created by David G Shrock on 8/7/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "AppController.h"

@interface AppController () {
    int importStatus;
    
    BOOL pShowNegatPref;
    BOOL pShowQRLocSearchPref;
    BOOL pNoTapScanPref;
    BOOL pShowZeroCountsPref;
    BOOL pAutoSelectIDEntryPref;
    BOOL pUserHasSeenTotalsTips;
    BOOL pUserHasSeenStartupTip;
    
    NSOperationQueue *queue;
    
}

@property (nonatomic, strong) DTScanCodeMetaControl *pScanCodeMtaCtl;

@end

@implementation AppController

@synthesize showQRFinder = pShowQRLocSearchPref;
@synthesize showNegateToggle = pShowNegatPref;
@synthesize showZeroCounts = pShowZeroCountsPref;
@synthesize noTapScanning = pNoTapScanPref;
@synthesize userHasSeenStartupTip  = pUserHasSeenStartupTip;
@synthesize userHasSeenTotalsTip = pUserHasSeenTotalsTips;
@synthesize autoSetItemInputOnLocPick = pAutoSelectIDEntryPref;

+ (instancetype)sharedAppController
{
    // this has been updated for thread-safe init
    
    static AppController *sharedController = nil;
    
    // set thread-safe
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] initPrivateOnly];
    });
    return sharedController;
}

// remind me to use static share
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Please use +[AppController sharedController]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivateOnly
{
    self = [super init];
    if (self) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSString *mainDir = [self applicationMainDirectory];
        NSError *err= nil;
        
        if (![fileManager fileExistsAtPath:mainDir])
        {
            [fileManager createDirectoryAtPath:mainDir withIntermediateDirectories:NO attributes:nil error:&err];
        }
        importStatus = 0;
    }
    return self;
}

- (BOOL)oldStoreDataExists
{
    NSURL *oldStoreUrl = [NSURL fileURLWithPath: [[self applicationMainDirectory] stringByAppendingPathComponent: [self oldStoreFileName]]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[oldStoreUrl path]]) {
        return YES;
    }
    return NO;
}

- (NSString *)oldStoreFileName
{
    return @"DCount.sqlite";
}

- (NSString *)storeFileName
{
    return @"DCountV2.sqlite";
}

- (NSURL *)urlForStoreFile
{
    return [NSURL fileURLWithPath: [[self applicationMainDirectory] stringByAppendingPathComponent: self.storeFileName]];
}

- (void)setScanCodeMetaControl:(DTScanCodeMetaControl *)scanCodeMetaControl
{
    self.pScanCodeMtaCtl = scanCodeMetaControl;
}

- (void)applicationEnteredBackground
{
    if (self.pScanCodeMtaCtl) {
        [self.pScanCodeMtaCtl applicaiontEnteredBackground];
    }
}

- (void)applicationEnteredForeground
{
    if (self.pScanCodeMtaCtl) {
        [self.pScanCodeMtaCtl applicationEnteringForeground];
    }
}

- (void)updateDefaults:(NSUserDefaults *)defaults
{
    if ([defaults objectForKey:@"show_negate_toggle_preference"]  != nil) {
        pShowNegatPref = [defaults boolForKey:@"show_negate_toggle_preference"];
    }
    else {
        pShowNegatPref = YES;
    }
    if ([defaults objectForKey:@"show_zero_counts_preference"] != nil) {
        pShowZeroCountsPref = [defaults boolForKey:@"show_zero_counts_preference"];
    }
    if ([defaults objectForKey:@"autoSetItemInput_preference"] != nil) {
        pAutoSelectIDEntryPref = [defaults boolForKey:@"autoSetItemInput_preference"];
    }
    if ([defaults objectForKey:@"has_seen_TotalsTip"] != nil) {
        pUserHasSeenTotalsTips = [defaults boolForKey:@"has_seen_TotalsTip"];
    }
    if ([defaults objectForKey:@"has_seen_StartupTip"] != nil) {
        pUserHasSeenStartupTip = [defaults boolForKey:@"has_seen_StartupTip"];
    }
    if ([defaults objectForKey:@"show_QR_searchButton_preference"] != nil) {
        pShowQRLocSearchPref = [defaults boolForKey:@"show_QR_searchButton_preference"];
    }
    if ([defaults objectForKey:@"no_tap_scan_preference"] != nil) {
        pNoTapScanPref = [defaults boolForKey:@"no_tap_scan_preference"];
    }
}

- (void)updateShowNegateToggle:(BOOL)enabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:@"show_negate_toggle_preference"];
}

- (void)updateShowQRFinder:(BOOL)enabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:@"show_QR_searchButton_preference"];
}

- (void)updateAutoSetItemInputOnLocPick:(BOOL)enabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:@"autoSetItemInput_preference"];
}

- (void)updateNoTapScanning:(BOOL)enabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:@"no_tap_scan_preference"];
}

- (void)updateShowZeroToUserDefaultsForEnabled:(BOOL)enabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:@"show_zero_counts_preference"];
}

- (void)updateHasSeenTotalsExportTip:(BOOL)seen
{
    pUserHasSeenTotalsTips = seen;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:seen forKey:@"has_seen_TotalsTip"];
}

- (void)updateHAsSeenStartupTips:(BOOL)seen
{
    pUserHasSeenStartupTip = seen;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:seen forKey:@"has_seen_StartupTip"];
}


- (NSArray *)loadAllCategories
{
    return [self allInstancesOf:@"DTCountCategory" orderedBy:@"label"];
}

- (NSArray *)loadAllItems
{
    return [self allInstancesOf:@"Item" orderedBy:@"label"];
}

- (NSArray *)loadAllLocations
{
    return [self allInstancesOf:@"Location" orderedBy:@"label"];
}

- (NSArray *)allInstancesOf:(NSString *)entityName orderedBy:(NSString *)attName
{
    //get managed context
    NSManagedObjectContext *moc = [self managedObjectContext];
    
    // creat efetch request fetches from entityname
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:moc];
    
    [fetch setEntity:entity];
    
    // if attname then sort
    if (attName) {
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:attName ascending:YES];
        
        NSArray *sortDescriptors = [NSArray arrayWithObject:sd];
        
        [fetch setSortDescriptors:sortDescriptors];
    }
    
    // attempt fetch
    NSError *error;
    NSArray *result = [moc executeFetchRequest:fetch error:&error];
    
    if (!result) {
        // TODO: move this??
        /*
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FetchFailed", @"Fetch Failed")
                                                            message:[error localizedDescription]
                                                           delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                                  otherButtonTitles:nil];
        [alertView show];
         */
        return nil;
    }
    return result;
}

#pragma mark -
#pragma mark Application lifecycle

- (void)saveContext {
    NSError *error = nil;
    if (managedObjectContext_ != nil) {

        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error]) {
            // should never happen
            NSLog(@" ERROR saving context  -- rollback -- err: %@", error);
            [managedObjectContext_ rollback];
        }
    }
}

- (void)rollbackContext
{
    NSLog(@"rolling back content");
    if (managedObjectContext_ != nil) {
        [managedObjectContext_ rollback];
    }
}

/**
 * forgets objects - discard references first
 */
- (void)resetContext
{
    NSLog(@"resetting context");
    if (managedObjectContext_ != nil) {
        [managedObjectContext_ reset];
    }
}

/**
 * Does NOT work! -- erase the store and start over
 */
/*
- (void)deleteStoreFile
{
    NSLog(@"delete store file");
    
    [self.managedObjectContext reset];  //drop pending changes
        
    NSError * error;
        // retrieve the store URL
    NSURL * storeURL = [[self.managedObjectContext persistentStoreCoordinator] URLForPersistentStore:[[[self.managedObjectContext persistentStoreCoordinator] persistentStores] lastObject]];
        
    //delete the store from the current managedObjectContext
    if ([[self.managedObjectContext persistentStoreCoordinator] removePersistentStore:[[[self.managedObjectContext persistentStoreCoordinator] persistentStores] lastObject] error:&error])
    {
        // remove the file
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
    }

    managedObjectContext_ = nil;
    managedObjectModel_ = nil;
    persistentStoreCoordinator_ = nil;
}
 */

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
        
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    
    // read in DC2Model.xcdatamodeld
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"DC2Model" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel_;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    NSURL *storeURL = [self urlForStoreFile];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *mainDir = [self applicationMainDirectory];
    NSError *errCreate = nil;
    
    if (![fileManager fileExistsAtPath:mainDir])
    {
        [fileManager createDirectoryAtPath:mainDir withIntermediateDirectories:NO attributes:nil error:&errCreate];
    }
    
    //[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    
    NSError *error = nil;
    
    // for data migration
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES };
    
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
        [managedObjectContext_ rollback];
    }
    
    return persistentStoreCoordinator_;
}

# pragma mark -
# pragma mark special shared functions


- (UIColor *)barColor
{
    return [UIColor colorWithRed:0.3134f green:0.224f blue:0.373f alpha:1.0f];
}
- (UIColor *)barLightColor
{
    return [UIColor colorWithRed:0.960f green:0.924f blue:0.982f alpha:0.80f];
}

- (UIColor *)barButtonColor
{
    // 150, 98, 182
    return [UIColor colorWithRed:0.584f green:0.384f blue:0.714f alpha:1.0f];
}

- (NSString *)fileCsvName {
    return @"dcount.csv";
}
- (NSString *)fileTsvName {
    return @"dcount.dcz";
}
- (NSString *)fileDczName {
    return @"dcount.dcz";
}

- (CIImage *)createQRCodeCIImageForString:(NSString *)qrString
{
    
    // Need to convert the string to ISO (or UTF-8) encoding
    // see https://developer.apple.com/library/ios/documentation/graphicsimaging/reference/CoreImageFilterReference/Reference/reference.html
    NSData *stringData = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // Set the message content and error-correction level
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    // Send the image back
    return qrFilter.outputImage;
    
}

/**
 * static - best to always use this shared number formatter
 */
- (NSString *)formatNSNumber:(NSNumber *)number
{
    static NSNumberFormatter *numFormatter;
    if (!numFormatter) {
        numFormatter = [[NSNumberFormatter alloc] init];
        numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    }
    [numFormatter setLocale:[NSLocale currentLocale]];
    return [numFormatter stringFromNumber:number];
}


- (NSString *)formatNumber:(NSUInteger)num
{
    NSNumber *number = [NSNumber numberWithInteger:num];
    return [self formatNSNumber:number];
}

- (NSArray *)itemsInTotalListForLabel:(NSString *)label
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label = %@", label];
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:entity];
    [fetch setPredicate:predicate];
    NSError *error;
    
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetch error:&error];
    return fetchedObjects;
}

- (NSArray *)locationsForLabel:(NSString *)label
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label = %@", label];
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:entity];
    [fetch setPredicate:predicate];
    NSError *error;
    
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetch error:&error];
    return fetchedObjects;
}

- (NSInteger)getCustomCountValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"custom_countBy_preference"] != nil) {
        NSInteger result = [defaults integerForKey:@"custom_countBy_preference"];
        if (result >= 2 && result < 1000) {
            return result;
        }
    }
    
    return 12;
}

// old - for upgrade only - use getCustomValue
- (NSInteger)loadCustomCountValueDeprecated
{
    NSString *customCountPath = [[self applicationMainDirectory] stringByAppendingPathComponent:[self customCountFileName]];
    NSError *err;
    
    NSString *customCountStr = [NSString stringWithContentsOfFile:customCountPath
                                                         encoding:NSUTF8StringEncoding
                                                            error:&err];
    if (customCountStr) {
        NSInteger result = [customCountStr integerValue];
        if (result > 0 && result < 9999) {
            return result;
        }
    }
    
    return 12;
}

- (NSInteger)loadLastSelectedLocationIndex
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"last_Location_storage"] != nil) {
        NSInteger result = [defaults integerForKey:@"last_Location_storage"];
        if (result >= 0) {
            return result;
        }
    }
    return -1;
    
}

- (BOOL)saveCustomCountValue:(NSInteger)customCount
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:customCount forKey:@"custom_countBy_preference"];
    
    return YES;
}

- (int)maxDescLength {
    return 48;
}

- (int)maxTitleLength {
    return 24;
}

- (BOOL)saveLastSelectedLocationIndex:(NSUInteger)index
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:index forKey:@"last_Location_storage"];
    
    return YES;
}

- (NSString *)customCountFileName
{
    return @"DCustomCount.txt";
}

- (BOOL)stringContainsBadCharactersInString:(NSString *)str
{
    NSString *strippedStr = [self stripBadCharactersFromString:str];
    if (strippedStr.length == str.length) {
        return NO;
    }
    
    return YES;
}

- (NSCharacterSet *)badCharacters
{
    NSString *badCharString = @"%@\\\v\"";
    NSCharacterSet *badChars = [NSCharacterSet characterSetWithCharactersInString:badCharString];
    return badChars;
}

- (NSString *)stripBadCharactersFromString:(NSString *)str
{
    NSString *tmp2 = [str stringByReplacingOccurrencesOfString:@"%" withString:@" "];
    tmp2 = [tmp2 stringByReplacingOccurrencesOfString:@"\\" withString:@" "];
    tmp2 = [tmp2 stringByReplacingOccurrencesOfString:@"@" withString:@" "];
    tmp2 = [tmp2 stringByReplacingOccurrencesOfString:@"'" withString:@"’"];
    tmp2 = [tmp2 stringByReplacingOccurrencesOfString:@"\v" withString:@" "];
    tmp2 = [tmp2 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    return [tmp2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)totalCountsSecretLocationName {
    return [NSString stringWithFormat:@"zzStoreTotalsL0c"];
}

- (NSString *)trimHeaderFromURLContent:(NSString *)content
{
    if (content != nil) {
        NSRange range1 = [content rangeOfString:@"--Apple-Mail-"];
        if (range1.length > 0 && [content length] > (range1.length + range1.location + range1.length)) {
            NSRange rangeFrom = NSMakeRange (range1.location + range1.length, [content length] - range1.location - range1.length);
            NSRange range2 = [content rangeOfString:@"--Apple-Mail-" options:NSCaseInsensitiveSearch range:rangeFrom];
            if (range2.length > 0 && [content length] > (range2.length + range2.location + range2.length)) {
                rangeFrom = NSMakeRange(range2.location + range2.length, [content length] - range2.location - range2.length);
                NSRange range3 = [content rangeOfString:@"Content-Transfer-Encoding:" options:NSCaseInsensitiveSearch range:rangeFrom];
                if(range3.length > 0) {
                    return [content substringFromIndex:range3.location];
                }
                return [content substringFromIndex:range2.location];
            }
        }
    }
    return content;
}

- (NSURL *)urlForTemporaryFileSavedWithFileName:(NSString *)filename withFileExtension:(NSString *)extension
{
    filename = [filename stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *fullFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", filename, extension]];
    return [NSURL fileURLWithPath:fullFileName];
}

#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSString *)applicationMainDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
}


- (void)cleanTempDirectory
{
    NSString *tmpDir = NSTemporaryDirectory();
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSArray *filelist = [filemgr contentsOfDirectoryAtPath:tmpDir error:NULL];
    int count = (int)[filelist count];
    NSError *err;
    for (int i = 0; i < count; i++)
    {
        NSString *file = [filelist objectAtIndex:i];
        if ([file hasSuffix:@".dcz"] || [file hasSuffix:@".csv"])
        {
            //NSLog(@" ~ I'm Clearing temp %@", file);
            [filemgr removeItemAtPath:[tmpDir stringByAppendingPathComponent:[filelist objectAtIndex: i]] error:&err];
        }
        else if ([file isEqualToString:@"DocumentPickerIncoming"]) {
            NSString *pickDir = [tmpDir stringByAppendingPathComponent:@"DocumentPickerIncoming"];
            NSArray *pickList = [filemgr contentsOfDirectoryAtPath:pickDir error:NULL];
            if (pickList) {

                for (NSString *pickerFile in pickList) {
                    //NSLog(@"removing docPickerIn file: %@", pickerFile);
                    NSString *longFileName = [pickDir stringByAppendingPathComponent:pickerFile];
                    [filemgr removeItemAtPath:longFileName error:&err];
                }
            }
        }
        else if ([file hasPrefix:@"QRCode"]) {
            [filemgr removeItemAtPath:[tmpDir stringByAppendingPathComponent:[filelist objectAtIndex: i]] error:&err];
        }
        else {
            NSLog(@" ~ not cleaning temp file %@", file);
        }
    }
    
}

- (void)cleanAllFilesInDocumentsDirectory
{
    NSString *docDir = [self applicationDocumentsDirectory];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSArray *filelist = [filemgr contentsOfDirectoryAtPath:docDir error:NULL];
    int count = (int)[filelist count];
    NSError *err;
    //NSString *noDeleteFile = [self exportFileDefaultFileName];
    for (int i = 0; i < count; i++)
    {
        NSString *file = [filelist objectAtIndex:i];
        
        if ([file isEqualToString:@"Inbox"] == NO) {
            //NSLog(@"clearing %@", file);
            if ([filemgr removeItemAtPath:[docDir stringByAppendingPathComponent:file] error:&err] == NO) {
                NSLog(@"failed to delete: %@", file);
            }
        }
    }
}

- (void)cleanCacheDirectory
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDir = [documentDirectories objectAtIndex:0];
    
    NSFileManager *fileMan = [NSFileManager defaultManager];
    NSArray *filelist = [fileMan contentsOfDirectoryAtPath:cacheDir error:NULL];
    int count = (int)filelist.count;
    NSError *err;
    for (int i = 0; i < count; i++)
    {
        NSString *file = [filelist objectAtIndex:i];

        if ([file isEqualToString:@"Snapshots"] == NO) {
            //NSLog(@" ~ I'm Clearing cache file: %@", file);
            [fileMan removeItemAtPath:[cacheDir stringByAppendingPathComponent:file] error:&err];
        }
    }
}

- (void)cleanDocumentsDirectory {
    NSString *docDir = [self applicationDocumentsDirectory];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSArray *filelist = [filemgr contentsOfDirectoryAtPath:docDir error:NULL];
    int count = (int)[filelist count];
    NSError *err;
    //NSString *noDeleteFile = [self exportFileDefaultFileName];
    for (int i = 0; i < count; i++)
    {
        NSString *file = [filelist objectAtIndex:i];
        
        if ([file isEqualToString:@"Inbox"] == NO && [file hasSuffix:@".jpg"] == NO && [file isEqualToString:@"images"] == NO) {
            //NSLog(@"clearing %@", file);
            [filemgr removeItemAtPath:[docDir stringByAppendingPathComponent:file] error:&err];
        }
    }
}







@end
