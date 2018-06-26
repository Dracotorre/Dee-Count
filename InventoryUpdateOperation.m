//
//  ClearCountsOperation_iPad.m
//  DCount
//
//  Created by David Shrock on 6/25/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//
// updated 8/19/2014 for combined files and ARC

#import "InventoryUpdateOperation.h"
#import "AppController.h"
#import "DTCountInventory.h"
#import "DTCountItem.h"
#import "DTCountLocation.h"
#import "DTCountCategory.h"
#import "DTCountCategoryStore.h"

@interface InventoryUpdateOperation () {
    NSMutableArray *pItemsList;
    UpdateInventoryTask pUpdateTask;
    NSString *pCategoryLabel;
    BOOL pSecretLocExists;
}

@end

@implementation InventoryUpdateOperation
@synthesize itemsList = pItemsList;
@synthesize clearTask = pUpdateTask;
@synthesize secretCompareLocationExists = pSecretLocExists;

- (instancetype)initWithTotalItems:(NSArray *)itemsLst forClearTask:(UpdateInventoryTask)clrTask withDelegate:(id<UpdateInventoryOperationDelegate>)del;
{
    self = [super init];
    if (self) {
        pItemsList = [[NSMutableArray alloc] initWithArray:itemsLst];
        pUpdateTask = clrTask;
        pSecretLocExists = NO;
        self.delegate = del;
    }
    
    return self;
}

- (instancetype)initForEmptyCategoryUpdateWithItems:(NSArray *)itemsLst forCategoryLabel:(NSString *)catLabel withDelegate:(id<UpdateInventoryOperationDelegate>)del
{
    self = [super init];
    if (self) {
        pItemsList = [[NSMutableArray alloc] initWithArray:itemsLst];
        pUpdateTask = UpdateEmptyCategoryForItems;
        pCategoryLabel = catLabel;
        pSecretLocExists = NO;
        self.delegate = del;
    }
    return self;
}

- (instancetype)init
{
    // programmer reminder
    @throw [NSException exceptionWithName:@"Wrong init"
                                   reason:@"Please use dedicated init"
                                 userInfo:nil];
    return nil;
}

- (void)main
{
    AppController *ac = [AppController sharedAppController];
    
    if (pUpdateTask == ClearAllCountsReplaceInventory || pUpdateTask == ClearAllCountsKeepInventory) {
        
        // move counts to secret compare-count location if none exists
        
        NSManagedObjectContext *moc = [ac managedObjectContext];
        
        DTCountLocation *secretLocation = nil;
        NSArray *locs = [ac locationsForLabel:[ac totalCountsSecretLocationName]];
        if (locs.count == 1) {
            secretLocation = (DTCountLocation *)[locs objectAtIndex:0];
        }
        if (secretLocation == nil && pItemsList.count > 0) {
            secretLocation = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:moc];
            [secretLocation setValue:[ac totalCountsSecretLocationName] forKey:@"label"];
        }
        
        // for double-checking
        NSArray *secretInvs = [[secretLocation valueForKey:@"inventories"] allObjects];
        
        for (int i = 0; i < pItemsList.count; ++i)
        {
            if ((i % 24) == 0) {
                [self updateProgressForIndex:i forTotal:pItemsList.count];
            }
            
            DTCountItem *itm = (DTCountItem *)[pItemsList objectAtIndex:i];
            NSInteger itmTotalCount = 0;
            DTCountInventory *totalCountInventory = nil;
            
            NSArray *inventories = [[itm valueForKey:@"inventories"] allObjects];
            for (int invCnt = (int)inventories.count - 1; invCnt >= 0; --invCnt) {
                DTCountInventory *mi = (DTCountInventory *)[inventories objectAtIndex:invCnt];
                DTCountLocation *miLoc = [mi valueForKey:@"location"];
                NSString *miLocName = [miLoc valueForKey:@"label"];
                
                if ([miLocName isEqualToString:[ac totalCountsSecretLocationName]] == NO) {
                    
                    itmTotalCount += [[mi valueForKey:@"count"] integerValue];
                    [[miLoc mutableSetValueForKey:@"inventories"] removeObject:mi];
                    [[itm mutableSetValueForKey:@"inventories"] removeObject:mi];
                    [moc deleteObject:mi];
                    mi = nil;
                    
                    //NSNumber *num = [NSNumber numberWithInt:0];
                    //[mi setValue:num forKey:@"count"];
                }
                else {
                    // set the secret compare inventory
                    totalCountInventory = mi;
                }
            }
            
            if (totalCountInventory == nil) {
                //[[ac managedObjectContext] processPendingChanges];
                
                // do we already have in secret?
                BOOL foundInSecret = NO;
                
                for (DTCountInventory *secMi in secretInvs) {
                    DTCountItem *sItm = [secMi valueForKey:@"Item"];
                    if (sItm == itm) {
                        NSLog(@" secret inventory already exists for itm %@!! updating", [itm valueForKey:@"label"]);
                        foundInSecret = YES;
                        [secMi setValue:[NSNumber numberWithInteger:itmTotalCount] forKey:@"count"];
                        [[itm mutableSetValueForKey:@"inventories"] addObject:secMi];
                        break;
                    }
                }
                if (foundInSecret == NO) {
                    
                    DTCountInventory *newInv = [NSEntityDescription insertNewObjectForEntityForName:@"Inventory" inManagedObjectContext:moc];
                    
                    [[secretLocation mutableSetValueForKey:@"inventories"] addObject:newInv];
                    [[itm mutableSetValueForKey:@"inventories"] addObject:newInv];
                    
                    [newInv setValue:[NSNumber numberWithInteger:itmTotalCount] forKey:@"count"];
                }
            }
            else {
                NSInteger totalComp = [[totalCountInventory valueForKey:@"count"] integerValue];
                if (totalComp == 0 ||(itmTotalCount > 0 && pUpdateTask == ClearAllCountsReplaceInventory)) { 
                    [totalCountInventory setValue:[NSNumber numberWithInteger:itmTotalCount] forKey:@"count"];
                }
            }
        }
        if (secretLocation) {
            pSecretLocExists = YES;
        }
        [ac saveContext];
    }
    else if (pUpdateTask == ClearAllItems) {
        // from old RemoveInventoryOperation_iPad.m
        
        NSManagedObjectContext *moc = [ac managedObjectContext];
        for (int i = 0; i < pItemsList.count; ++i)
        {
            if ((i % 24) == 0) {
                [self updateProgressForIndex:i forTotal:pItemsList.count];
            }
            DTCountItem *itm = [pItemsList objectAtIndex:i];
            NSArray *inventories = [[itm valueForKey:@"inventories"] allObjects];
            for (int invCnt = 0; invCnt < (int)inventories.count; ++invCnt) {
                DTCountInventory *mi = (DTCountInventory *)[inventories objectAtIndex:invCnt];
                DTCountLocation *miLoc = [mi valueForKey:@"location"];
                [[miLoc mutableSetValueForKey:@"inventories"] removeObject:mi];
                [[itm mutableSetValueForKey:@"inventories"] removeObject:mi];
                [moc deleteObject:mi];
                mi = nil;
            }
            itm = [[DTCountCategoryStore sharedStore] removeCategoryFromItem:itm];
            [moc deleteObject:itm];
            itm = nil;
        }
        [pItemsList removeAllObjects];
    }
    else if (pUpdateTask == ClearZeroCountItems) {
        
        NSManagedObjectContext *moc = [ac managedObjectContext];
        for (int i = (int)pItemsList.count - 1; i >= 0; --i)
        {
            if ((i % 24) == 0) {
                [self updateProgressForIndex:i forTotal:pItemsList.count];
            }
            DTCountItem *itm = [pItemsList objectAtIndex:i];
            NSArray *inventories = [[itm valueForKey:@"inventories"] allObjects];
            int miCount = 0;
            DTCountInventory *secretInventory = nil;
            for (int invCnt = 0; invCnt < (int)inventories.count; ++invCnt) {
                DTCountInventory *mi = (DTCountInventory *)[inventories objectAtIndex:invCnt];
                DTCountLocation *miLoc = [mi valueForKey:@"location"];
                NSString *miLocName = [miLoc valueForKey:@"label"];
                if ([miLocName isEqualToString:[ac totalCountsSecretLocationName]]) {
                    miCount++;
                    secretInventory = mi;
                    pSecretLocExists = YES;
                }
                else if ([[mi valueForKey:@"count"] intValue] == 0) {
                    miCount++;
                    [[miLoc mutableSetValueForKey:@"inventories"] removeObject:mi];
                    [[itm mutableSetValueForKey:@"inventories"] removeObject:mi];
                    [moc deleteObject:mi];
                    mi = nil;
                }
                
            }
            if (miCount == inventories.count) {
                if (secretInventory) {
                    DTCountLocation *secretLoc = [secretInventory valueForKey:@"location"];
                    if (secretLoc) {
                        [[secretLoc mutableSetValueForKey:@"inventories"] removeObject:secretInventory];
                    }
                    else {
                        NSLog(@" -- missing secretLoc side of inventory");
                    }
                    [[itm mutableSetValueForKey:@"inventories"] removeObject:secretInventory];
                    [moc deleteObject:secretInventory];
                    secretInventory = nil;
                }
                itm = [[DTCountCategoryStore sharedStore] removeCategoryFromItem:itm];
                [moc deleteObject:itm];
                [pItemsList removeObjectAtIndex:i];
                itm = nil;
            }
        }
        [ac saveContext];
    }
    else if (pUpdateTask == UpdateEmptyCategoryForItems && pCategoryLabel) {
        
        DTCountCategory *defCat = [[DTCountCategoryStore sharedStore] categoryWithLabel:pCategoryLabel];
        
        for (int i = 0; i < pItemsList.count; ++i) {
            DTCountItem *item = (DTCountItem *)[pItemsList objectAtIndex:i];
            DTCountCategory *cat = [item valueForKey:@"category"];
            if (cat == nil) {
                [[DTCountCategoryStore sharedStore] itemSetCategory:defCat forItem:item];
            }
        }
    }
    [NSThread sleepForTimeInterval:0.25];
    
    [(NSObject *)self.delegate performSelectorOnMainThread:@selector(doneUpdatingInventoryForProcess:) withObject:self waitUntilDone:YES];
    
}

- (void)updateProgressForIndex:(int)index forTotal:(NSUInteger)total
{
    float fl = ((float)index / (float)total);
    NSNumber *num = [NSNumber numberWithFloat:fl];
    [(NSObject *)self.delegate performSelectorOnMainThread:@selector(updateClearingCountsProgress:) withObject:num waitUntilDone:NO];
}
@end
