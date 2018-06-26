//
//  StartupOperation.m
//  Dee Count
//
//  Created by David G Shrock on 8/8/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "StartupOperation.h"
#import "AppController.h"
#import "MyInventory.h"
#import "MyItem.h"
#import "MyLocation.h"
#import "DTCountInventory.h"
#import "DTCountItem.h"
#import "DTCountLocation.h"
#import "DCountOldStore.h"
#import "DTCountCategoryStore.h"
#import "ImageCache.h"

@interface StartupOperation () {
    NSString *importContent;
    NSURL *pImportUrl;
    NSString *pImportFile;
    BOOL pIsImporting;
    NSMutableArray *items;
    BOOL pIsImportAborted;
}

@end

@implementation StartupOperation

const int maxBytesInput = 320000;

@synthesize isImporting = pIsImporting;
@synthesize importFile = pImportFile;
@synthesize importURL = pImportUrl;
@synthesize resultItems = items;
@synthesize key;

- (instancetype)initWithDelegate:(id<StartupOperationDelegate>)delegate
{
    return [self initWithURL:nil withFile:nil withDelegate:delegate];
}

- (instancetype)initWithURL:(NSURL *)url withDelegate:(id<StartupOperationDelegate>)delegate
{
    return [self initWithURL:url withFile:nil withDelegate:delegate];
}

- (instancetype)initWithFile:(NSString *)file withDelegate:(id<StartupOperationDelegate>)delegate
{
    return [self initWithURL:nil withFile:file withDelegate:delegate];
}

- (instancetype)initWithURL:(NSURL *)url withFile:(NSString *)file withDelegate:(id<StartupOperationDelegate>)delegate
{
    self = [super init];
    if (self) {
        pImportFile = file;
        self.delegate = delegate;
        pImportUrl = url;
        if (pImportUrl != nil || pImportFile != nil) {
            pIsImporting = YES;
        }
    }
    return self;
}

- (void)cancelImport
{
    pIsImporting = NO;
}

- (void)main
{
    BOOL importOK = NO;
    
    if (self.updatingFromOldStore) {
        
        // normally, these should be empty - but just in case
        NSMutableArray *newLocations = [[NSMutableArray alloc] initWithArray:[self loadLocations]];
        NSMutableArray *newItems = [[NSMutableArray alloc] initWithArray:[[AppController sharedAppController] loadAllItems]];
        
        
        NSArray *oldLocations = [[DCountOldStore sharedStore] loadAllLocations];
        NSArray *oldItems = [[DCountOldStore sharedStore] loadAllItems];

        
        NSMutableArray *updatedLocations = [[NSMutableArray alloc] init];
        NSMutableArray *updatedItems = [[NSMutableArray alloc] init];
        
        // first, get all locations ignoring inventories
        
        for (int i = 0; i < oldLocations.count; ++i) {
            BOOL locExists = NO;
            MyLocation *oldLoc = (MyLocation *)[oldLocations objectAtIndex:i];
            NSString *oldLocLabel = [oldLoc valueForKey:@"label"];
            for (int nIdx = 0; nIdx < newLocations.count; ++nIdx) {
                DTCountLocation *loc = (DTCountLocation *)[newLocations objectAtIndex:nIdx];
                NSString *locLabel = [loc valueForKey:@"label"];
                if ([oldLocLabel isEqualToString:locLabel]) {
                    locExists = YES;
                    [updatedLocations addObject:loc];
                    [newLocations removeObjectAtIndex:nIdx];
                }
            }
            if (locExists == NO) {
                DTCountLocation *newLoc = [self newUpgradedLocation:oldLoc];
                [updatedLocations addObject:newLoc];
            }
        }
        for (DTCountLocation *loc in newLocations) {
            [updatedLocations addObject:loc];
        }
        
        
        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(startupLoadedLocations:) withObject:updatedLocations waitUntilDone:NO];
        
        // upgrade all items
        for (int i = 0; i < oldItems.count; ++i) {
            
            if (i % 12 == 0 || i == oldItems.count - 1) {
                CGFloat fl = (CGFloat)i / (CGFloat)oldItems.count;
                NSNumber *num = [NSNumber numberWithFloat:fl];
                [(NSObject *)self.delegate performSelectorOnMainThread:@selector(updateImportProgress:) withObject:num waitUntilDone:NO];
            }
            
            BOOL itemExists = NO;
            MyItem *oldItem = (MyItem *)[oldItems objectAtIndex:i];
            NSString *oldItemLabel = [oldItem valueForKey:@"label"];
            for (int nIdx = 0; nIdx < newItems.count; ++nIdx) {
                DTCountItem *itm = (DTCountItem *)[newItems objectAtIndex:nIdx];
                if ([oldItemLabel isEqualToString:[itm valueForKey:@"label"]]) {
                    itemExists = YES;
                    DTCountItem *updatedIt = [self upgradedItem:itm withItem:oldItem forLocations:updatedLocations];
                    [updatedItems addObject:updatedIt];
                    [newItems removeObjectAtIndex:nIdx];
                }
            }
            if (itemExists == NO) {
                DTCountItem *newItem = [self newUpgradedItem:oldItem forLocations:updatedLocations];
                [updatedItems addObject:newItem];
            }
        }
        for (DTCountItem *itm in newItems) {
            [updatedItems addObject:itm];
        }
        
        items = [updatedItems mutableCopy];
        
        [[AppController sharedAppController] saveContext];
        
        // delete old images
        
        [[AppController sharedAppController] cleanCacheDirectory];
        
        // delete old file

        NSURL *storeURL = [NSURL fileURLWithPath: [[[AppController sharedAppController] applicationMainDirectory] stringByAppendingPathComponent: [AppController sharedAppController].oldStoreFileName]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *err;
        
        BOOL success = [fileManager removeItemAtURL:storeURL error:&err];
        if (!success) {
            NSLog(@" - failed to delete file. Error: %@", err.description);
        }
        
    }
    else if (self.isImporting) {

        NSData *newData = nil;

        if (self.importURL != nil) {
            newData = [NSData dataWithContentsOfURL:self.importURL];
        }
        else if (self.importFile != nil) {
            newData = [NSData dataWithContentsOfFile:self.importFile];
        }
        if (newData != nil && newData.length < maxBytesInput) {
            NSString *content = [[NSString alloc] initWithBytes:newData.bytes
                                                         length:newData.length
                                                       encoding:NSUTF8StringEncoding];
            if (content == nil) {
                content = [[NSString alloc] initWithBytes:newData.bytes
                                                   length:newData.length
                                                 encoding:NSWindowsCP1252StringEncoding];
            }
            if (content == nil) {
                [(NSObject *)self.delegate performSelectorOnMainThread:@selector(importDidFinishWithFileError) withObject:nil waitUntilDone:NO];
            }
            else {
                importOK = [self handleImportOfContent:content];
                
                if (!importOK) {
                    content = [[NSString alloc] initWithBytes:newData.bytes
                                                       length:newData.length
                                                     encoding:NSUnicodeStringEncoding];
                    importOK = [self handleImportOfContent:content];
                    if (!importOK) {

                        content = [[NSString alloc] initWithBytes:newData.bytes
                                                           length:newData.length
                                                         encoding:NSISOLatin1StringEncoding];
                        importOK = [self handleImportOfContent:content];
                    }
                }
            }
            
            if (!importOK) {
                [(NSObject *)self.delegate performSelectorOnMainThread:@selector(importDidFinishWithError) withObject:nil waitUntilDone:NO];
                
                NSArray *list = [[AppController sharedAppController] loadAllItems];
                
                items = [list mutableCopy];
            }
        }
        else {
            NSArray *locations = [self loadLocations];
            [(NSObject *)self.delegate performSelectorOnMainThread:@selector(startupLoadedLocations:) withObject:locations waitUntilDone:NO];
            
            NSArray *list = [[AppController sharedAppController] loadAllItems];
            
            items = [list mutableCopy];
        }
    }
    else {
        NSArray *locations = [self loadLocations];
        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(startupLoadedLocations:) withObject:locations waitUntilDone:NO];

        NSArray *list = [[AppController sharedAppController] loadAllItems];
        
        items = [list mutableCopy];
    }
    
    // let cycle through all items to finish loading before going to main thread
    [self checkItemsForErrors];
    
    /*
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [(NSObject *)self.delegate performSelectorOnMainThread:@selector(startupDidFinishLoadingForProcess:) withObject:self waitUntilDone:NO];
            
            
    });
    */
    
    /*
     * only necessary to expose our app container
    NSURL *ubuiquityURl = [[AppController sharedAppController] ubiquityCloudContainerForApp];
    if (ubuiquityURl == nil) {
        ubuiquityURl = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    }
     */
     
    [(NSObject *)self.delegate performSelectorOnMainThread:@selector(startupDidFinishLoadingForProcess:) withObject:self waitUntilDone:NO];
}

- (void)checkItemsForErrors
{
    //NSLog(@" $$ Startup testing items");
    for (DTCountItem *itm in items) {
        NSArray *inventoriesForItem = [[itm valueForKey:@"inventories"] allObjects];
        for (DTCountInventory *itminv in inventoriesForItem) {
            DTCountLocation *loc = [itminv valueForKey:@"Location"];
            if (loc) {
                NSString *locName = [loc valueForKey:@"label"];
                if ([locName isEqualToString:[AppController sharedAppController].totalCountsSecretLocationName] == NO) {
                    NSNumber *num = [itminv valueForKey:@"count"];
                    if ([num integerValue] <= 0) {
                        //NSLog(@"~item inventory zero for %@ at %@", [itm valueForKey:@"label"], locName);
                    }
                    NSArray *inventoriesForLoc = [loc valueForKey:@"inventories"];
                    BOOL foundItem = NO;
                    for (DTCountInventory *locInv in inventoriesForLoc) {
                        DTCountItem *tItm = [locInv valueForKey:@"Item"];
                        if (tItm == itm) {
                            foundItem = YES;
                        }
                    }
                    if (!foundItem) {
                        NSLog(@"~item, %@, inventory did not have matching inventory at location, %@", [itm valueForKey:@"label"], locName);
                        [[itm mutableSetValueForKey:@"inventories"] removeObject:itminv];
                        [[[AppController sharedAppController] managedObjectContext] deleteObject:itminv];
                    }
                }
            }
            else {
                NSLog(@"removing null loc inventory for item %@", [itm valueForKey:@"label"]);
                [[itm mutableSetValueForKey:@"inventories"] removeObject:itminv];
                if (itminv) {
                   [[[AppController sharedAppController] managedObjectContext] deleteObject:itminv];
                }
            }
        }
    }
}

- (BOOL)handleImportOfContent:(NSString *)content
{
    BOOL result = NO;
    BOOL foundSecret = NO;
    DTCountLocation *loc = nil;
    
    NSMutableArray *locations = [[NSMutableArray alloc] initWithArray:[self loadLocations]];
    
    for (int i = 0; i < locations.count; ++i) {
        loc = (DTCountLocation *)[locations objectAtIndex:i];
        NSString *locName = [loc valueForKey:@"label"];
        if ([locName isEqualToString:[[AppController sharedAppController] totalCountsSecretLocationName]]) {
            foundSecret = YES;
            break;
        }
    }
    if (!foundSecret) {
        NSManagedObjectContext *moc = [[AppController sharedAppController] managedObjectContext];
        loc = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:moc];
        [loc setValue:[[AppController sharedAppController] totalCountsSecretLocationName] forKey:@"label"];
        [locations addObject:loc];
    }
    
    [(NSObject *)self.delegate performSelectorOnMainThread:@selector(startupLoadedLocations:) withObject:[locations mutableCopy] waitUntilDone:NO];
    
    if (content) {
        content = [[AppController sharedAppController] trimHeaderFromURLContent:content];
        result = [self importItemDetails:content atLocation:loc];
    }
    else {
        NSLog(@"   ~ startup content is nil!");
    }
    
    return result;
}

/* * *
 * a line-
 * expected min input: UPC \t description \t count
 *     optional input: UPC \t description \t count \t inventory-count
 *       v1 DCZ input: UPC \t description \t count \t inventory-count \t locations-
 *       v2 DCZ input: UPC \t description \t count \t inventory-count \t locations- \t category \t value
 */
- (BOOL)importItemDetails:(NSString *)itemsFromText atLocation:(DTCountLocation *)loc
{
    BOOL result = YES;
    pIsImportAborted = NO;
    
    AppController *ac = [AppController sharedAppController];
    
    if ([self isImportDataMYOB10:itemsFromText]) {
        //NSLog(@" MYOB10 - replacing new-line-tabs with tabs");
        itemsFromText = [itemsFromText stringByReplacingOccurrencesOfString:@"\r\n\r\t" withString:@"\t"];
    }
    
    NSArray *list = [ac loadAllItems];
    NSMutableArray *itemsList = [list mutableCopy];
    int startItemCount = (int)itemsList.count;
    int itemUpdatedCount = 0;
    BOOL ignoreExtendedColumns = NO;
    
    NSArray *lines = [itemsFromText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    if (lines.count < 60) {
        // give our transitions a chance before finishing
        [NSThread sleepForTimeInterval:0.333];
    }
    
    for (int lidx = 0; lidx < lines.count; ++lidx) {
        if (pIsImporting) {
            
            NSString *categoryColumnStr = nil;
            CGFloat valueColumnValue = 0.0f;
            
            NSArray *tabs = [[lines objectAtIndex:lidx] componentsSeparatedByString:@"\t"];
            if (tabs.count >= 3) {
                if ((lidx % 20) == 0) {
                    // update progress
                    float fl = ((float)lidx / (float)[lines count]);
                    NSNumber *num = [NSNumber numberWithFloat:fl];
                    [(NSObject *)self.delegate performSelectorOnMainThread:@selector(updateImportProgress:) withObject:num waitUntilDone:NO];
                }
                
                NSString *upc = [tabs objectAtIndex:0];
                if (upc != nil) {
                    if (upc.length > [ac maxTitleLength]) {
                        upc = [upc substringToIndex:[ac maxTitleLength]];
                    }
                    if (upc.length > 0) upc = [ac stripBadCharactersFromString:upc];
                    upc = [upc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                }
                
                NSString *desc = [tabs objectAtIndex:1];
                if (desc != nil) {
                    if (desc.length > [ac maxDescLength]) {
                        desc = [desc substringToIndex:[ac maxDescLength]];
                    }
                    if (desc.length > 0) desc = [ac stripBadCharactersFromString:desc];
                    desc = [desc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ([self stringStartsAndEndsWithQuotes:desc]) {
                        desc = [desc substringFromIndex:1];
                        desc = [desc substringToIndex:desc.length - 1];
                    }
                }
                
                // even if both count and inventory columns exist, use the non-zero value prefering second
                
                NSInteger cnt = 0;
                NSString *cntVal = [tabs objectAtIndex:2];
                NSScanner *cntScanner = [NSScanner scannerWithString:cntVal];
                [cntScanner setLocale:[NSLocale currentLocale]];
                
                if ([cntScanner scanInteger:&cnt]) {
                    // double-check: cnt might be zero if not a number
                    if (cnt == 0) {
                        NSString *numStr = [tabs objectAtIndex:2];
                        if (![numStr isEqualToString:@"0"])
                            cnt = -1;
                    }
                }
                else {
                    cnt = -1;
                    //NSLog(@" * * *scanner failed to find an integer in count column: %@", cntVal);
                }
                
                if (tabs.count >= 4)
                {
                    // if it's an integer than use this for the count
                    NSInteger testCnt = 0;
                    cntScanner = [NSScanner scannerWithString:[tabs objectAtIndex:3]];
                    if ([cntScanner scanInteger:&testCnt]) {
                        if (testCnt > 0) cnt = testCnt;
                        // else default to first column
                    }
                }
                if (upc.length > 1 && cnt >= 0) {
                    // No count, skip line -- first few rows might be a header
                    
                    if (!ignoreExtendedColumns && tabs.count >= 7) {
                        categoryColumnStr = [tabs objectAtIndex:5];
                        NSString *valueColumnStr = [tabs objectAtIndex:6];
                        
                        // test
                        if (categoryColumnStr.length > 0 && categoryColumnStr.length < ac.maxTitleLength) {
                            if ([ac stringContainsBadCharactersInString:categoryColumnStr]) {
                                    //NSLog(@"skiping cat for bad chars on %@", categoryColumnStr);
                                categoryColumnStr = nil;
                            }
                        }
                        else if (categoryColumnStr.length >= ac.maxTitleLength) {
                            //ignoreExtendedColumns = YES;
                            categoryColumnStr = nil;
                        }
                        if (valueColumnStr.length > 0) {
                            NSScanner *scanner = [NSScanner scannerWithString:valueColumnStr];
                            [scanner setLocale:[NSLocale currentLocale]];
                            
                            float testFloat = -1.0f;
                            if ([scanner scanFloat:&testFloat]) {
                                valueColumnValue = testFloat;
                            }
                            else {
                                
                                //ignoreExtendedColumns = YES;
                                //NSLog(@"ignore extended columns on float: %f - %@", testFloat, valueColumnStr);
                            }
                        }
                    }
                    
                    BOOL found = NO;
                    
                    if (itemsList != nil && upc != nil && upc.length > 0 && cnt >= 0) {
                        // set inventory for item
                        
                        DTCountInventory *inventory = nil;
                        
                        for (int i = 0; i < itemsList.count; ++i) {
                            DTCountItem *itm = [itemsList objectAtIndex:i];
                            NSString *val = [itm valueForKey:@"label"];
                            
                            if ([val compare:upc options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                                
                                NSArray *inventoriesForItem = [[itm valueForKey:@"inventories"] allObjects];
                                for (DTCountInventory *mi in inventoriesForItem) {
                                    if ([mi valueForKey:@"location"] == loc) {
                                        inventory = mi;
                                    }
                                }
                                
                                found = YES;
                                itemUpdatedCount++;
                                
                                [itm setValue:desc forKey:@"desc"];
                                if (!ignoreExtendedColumns) {
                                    itm = [self itemSetItem:itm categoryWithLabel:categoryColumnStr setValue:valueColumnValue];
                                }
                                
                                if (!inventory) {
                                    NSManagedObjectContext *moc = [ac managedObjectContext];
                                    inventory = [NSEntityDescription insertNewObjectForEntityForName:@"Inventory" inManagedObjectContext:moc];
                                    [[itm mutableSetValueForKey:@"inventories"] addObject:inventory];
                                    [[loc mutableSetValueForKey:@"inventories"] addObject:inventory];
                                }
                                break;
                            }
                        }
                        
                        if (!found) {
                            NSManagedObjectContext *moc = [ac managedObjectContext];
                            DTCountItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:moc];
                            [newItem setValue:upc forKey:@"label"];
                            [newItem setValue:desc forKey:@"desc"];
                            
                            if (!ignoreExtendedColumns) {
                                [self itemSetItem:newItem categoryWithLabel:categoryColumnStr setValue:valueColumnValue];
                            }
                            
                            NSArray *inventoriesForItem = [[newItem valueForKey:@"inventories"] allObjects];
                            
                            for (DTCountInventory *mi in inventoriesForItem) {
                                if ([mi valueForKey:@"location"] == loc) {
                                    inventory = mi;
                                }
                            }
                            if (!inventory) {
                                inventory = [NSEntityDescription insertNewObjectForEntityForName:@"Inventory" inManagedObjectContext:moc];
                                [[newItem mutableSetValueForKey:@"inventories"] addObject:inventory];
                                [[loc mutableSetValueForKey:@"inventories"] addObject:inventory];
                            }
                            [itemsList addObject:newItem];
                            itemUpdatedCount++;
                        }
                        NSNumber *num = [NSNumber numberWithInteger:cnt];
                        [inventory setValue:num forKey:@"count"];
                    }
                }
                
            }
            if (lidx > 50 && itemUpdatedCount == 0)
            {
                // must not be a valid file - get out
                pIsImportAborted = YES;
                pIsImporting = NO;
                result = NO;
                lidx = (int)lines.count + 100;
            }
        }
        else {
            lidx = (int)lines.count + 10;
        }
    }
    
    if (self.isImporting) {
        
        if (self.isImporting) {
            if (itemsList.count < startItemCount || itemUpdatedCount == 0) {
                result = NO;
                [ac rollbackContext];
                
                list = [ac loadAllItems];
                items = [list mutableCopy];
            }
            else {
                items = [itemsList mutableCopy];
                [ac saveContext];
                NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"label" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                NSArray *sds = [NSArray arrayWithObject:sd];
                [items sortUsingDescriptors:sds];
            }
        }
    }
    else {
        [ac rollbackContext];
        [itemsList removeAllObjects];
        
        list = [ac loadAllItems];
        items = [list mutableCopy];
    }
    itemsList = nil;
    
    if (self.importURL != nil) {
        NSError *err= nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (self.importFile != nil && self.importFile.length > 0) {
            if ([fileManager fileExistsAtPath:self.importFile]) {
                [fileManager removeItemAtPath:self.importFile error:&err];
            }
        }
        else
        {
            [fileManager removeItemAtURL:self.importURL error:&err];
        }
    }
    return result;
}

- (BOOL)isImportDataMYOB10:(NSString *)importData
{
    BOOL result = NO;
    int checkCnt = 0;
    NSArray *lines = [importData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if ([lines count] > 10)
    {
        for (int i = 0; i < 10; ++i)
        {
            if ([[lines objectAtIndex:i] hasPrefix:@"Items List [Summary]"]) {
                if (i < 4) checkCnt++;
            }
            if ([[lines objectAtIndex:i] hasPrefix:@"Item\t\tUnits On Hand"]) {
                checkCnt++;
            }
        }
        if (checkCnt == 2) result = YES;
    }
    return result;
}

- (NSArray *)loadLocations
{
    NSArray *locations = nil;
    
    if (locations == nil) {
        NSArray *list = [[AppController sharedAppController] loadAllLocations];
        locations = [list mutableCopy];
    }
    
    return locations;
}

- (BOOL)stringStartsAndEndsWithQuotes:(NSString *)str
{
    if (str.length > 2) {
        if ([str hasPrefix:@"\""] && [str hasSuffix:@"\""]) {
            return YES;
        }
        if ([str hasPrefix:@"“"] && [str hasSuffix:@"”"]) {
            return YES;
        }
    }
    return NO;
}

#pragma  mark - data conversions

/**
 *  no inventories set here; see newUpgradedItem or upgradedItem:withItem
 */
- (DTCountLocation *)newUpgradedLocation:(MyLocation *)oldLoc
{
    AppController *ac = [AppController sharedAppController];
    NSManagedObjectContext *moc = [ac managedObjectContext];
    DTCountLocation *newLoc = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:moc];
    [newLoc setValue:[NSString stringWithString:[oldLoc valueForKey:@"label"]] forKey:@"label"];
    
    // move picture to new location
    NSString *picID = [oldLoc valueForKey:@"picuuid"];
    if (picID != nil && picID.length > 0) {
        [newLoc setValue:[NSString stringWithString:picID] forKey:@"picuuid"];
        [newLoc setValue:[[oldLoc valueForKey:@"picture"] copy] forKey:@"picture"];
        
        UIImage *image = [[ImageCache sharedImageCache] imageOldForKey:picID];
        [[ImageCache sharedImageCache] setImage:image forKey:picID];
        [[ImageCache sharedImageCache] deleteImageOldForKey:picID];
    }
    
    return newLoc;
}

/**
 *  with all v2 locations so we can set the inventories for upgraded item
 */
- (DTCountItem *)newUpgradedItem:(MyItem *)oldItem forLocations:(NSMutableArray *)locations
{
    DTCountItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:[[AppController sharedAppController] managedObjectContext]];
    [newItem setValue:[oldItem valueForKey:@"label"] forKey:@"label"];
    return [self upgradedItem:newItem withItem:oldItem forLocations:locations];
}

- (DTCountItem *)upgradedItem:(DTCountItem *)dcItem withItem:(MyItem *)oldItem forLocations:(NSMutableArray *)locations
{
    NSManagedObjectContext *moc = [AppController sharedAppController].managedObjectContext;
    NSString *oldItemLabel = [oldItem valueForKey:@"label"];
    
    if ([oldItemLabel isEqualToString:[dcItem valueForKey:@"label"]]) {
        NSString *oldDesc = [oldItem valueForKey:@"desc"];
        if (oldDesc != nil) {
            [dcItem setValue:[NSString stringWithString:oldDesc] forKey:@"desc"];
        }
        NSArray *inventoriesForItem = [[oldItem valueForKey:@"inventories"] allObjects];
        for (MyInventory *mi in inventoriesForItem) {
            MyLocation *miLoc = [mi valueForKey:@"location"];
            NSString *miLocName = [miLoc valueForKey:@"label"];
            BOOL foundInventory = NO;
            NSArray *inventoriesForNewItem = [[dcItem valueForKey:@"inventories"] allObjects];
            if (inventoriesForNewItem != nil) {
                for (DTCountInventory *dci in inventoriesForNewItem) {
                    DTCountLocation *dciLoc = [dci valueForKey:@"location"];
                    NSString *dciLocLabel = [dciLoc valueForKey:@"label"];
                    if ([dciLocLabel isEqualToString:miLocName]) {
                        foundInventory = YES;
                        // keep existing value
                    }
                }
            }
            if (foundInventory == NO) {
                DTCountInventory *newInventory = [NSEntityDescription insertNewObjectForEntityForName:@"Inventory" inManagedObjectContext:moc];
                int cnt = [[mi valueForKey:@"count"] intValue];
                [newInventory setValue:[NSNumber numberWithInt:cnt] forKey:@"count"];
                for (int locIdx = 0; locIdx < locations.count; ++locIdx) {
                    DTCountLocation *loc = (DTCountLocation *)[locations objectAtIndex:locIdx];
                    NSString *locLabel = [loc valueForKey:@"label"];
                    if ([locLabel isEqualToString:miLocName]) {
                        [[dcItem mutableSetValueForKey:@"inventories"] addObject:newInventory];
                        [[loc mutableSetValueForKey:@"inventories"] addObject:newInventory];
                        break;
                    }
                }
            }
        }
        
    }
    else {
        NSLog(@" ~ ! upgrade error, items don't match! %@ - %@", [oldItem valueForKey:@"label"], [dcItem valueForKey:@"label"]);
    }
    return dcItem;
}

- (DTCountItem *)itemSetItem:(DTCountItem *)item categoryWithLabel:(NSString *)catLabel setValue:(CGFloat)val
{
    DTCountCategory *cat = [item valueForKey:@"category"];
    if (cat == nil) {
        if (catLabel.length > 0) {
            cat = [[DTCountCategoryStore sharedStore] categoryWithLabel:catLabel];
            item = [[DTCountCategoryStore sharedStore] itemSetCategory:cat forItem:item];
        }
    }
    if ([[item valueForKey:@"value"] floatValue] == 0.0f && val > 0.0f) {
        NSNumber *num = [NSNumber numberWithFloat:val];
        [item setValue:num forKey:@"value"];
    }
 
    return item;
}

@end
