//
//  DTCountCategoryStore.m
//  Dee Count
//
//  Created by David G Shrock on 9/10/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DTCountCategoryStore.h"
#import "AppController.h"

@interface DTCountCategoryStore () {
    NSMutableArray *pCategories;
}

@end

@implementation DTCountCategoryStore

+ (instancetype)sharedStore
{
    static DTCountCategoryStore *sharedCatStore = nil;
    
    // thread-safe
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCatStore = [[self alloc] initPrivate];
    });
    
    return sharedCatStore;
}

- (instancetype)init
{
    // remind programmer
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[DTCountCategoryStore sharedStore]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        [self refreshAllCategories];
    }
    return self;
}

- (void)refreshAllCategories
{
    NSArray *allCats = [[AppController sharedAppController] loadAllCategories];
    
    pCategories = [[NSMutableArray alloc] initWithArray:allCats];
    
    if (pCategories.count == 0) {
        [self generateDefaultCategories];
    }
}

- (NSInteger)maximumCategories
{
    return 100;
}

- (NSArray *)allCategories
{
    ///return [pCategories copy];  rigid, but let's assume caller treats by flag
    return pCategories;
}

- (void)generateDefaultCategories
{
    // set some default categories
    [self categoryWithLabel:NSLocalizedString(@"Shoes", @"Shoes")];
    [self categoryWithLabel:NSLocalizedString(@"Apparel", @"Apparel")];
    [self categoryWithLabel:NSLocalizedString(@"Jewelry", @"Jewelry")];
    [self categoryWithLabel:NSLocalizedString(@"Books", @"Books")];
    [self categoryWithLabel:NSLocalizedString(@"Electronics", @"Electronics")];
}

- (DTCountItem *)createNewItemWithLabel:(NSString *)itemLabel withCategoryByLabel:(NSString *)catLabel
{
    // no checking for existing item label in cat since we assume this truly is a new item
    
    DTCountItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:[[AppController sharedAppController] managedObjectContext]];
    [newItem setValue:itemLabel forKey:@"label"];
    
    if (catLabel != nil && catLabel.length > 0) {
        DTCountCategory *cat = [self categoryWithLabel:catLabel];
        newItem = [self itemSetCategory:cat forItem:newItem];
    }
    return newItem;
}

- (DTCountItem *)itemSetCategory:(DTCountCategory *)cat forItem:(DTCountItem *)item
{
    if (cat != nil) {
        DTCountCategory *curCat = [item valueForKey:@"category"];
        if (curCat != nil) {
            [self removeCategoryFromItem:item];
        }
        [item setValue:cat forKey:@"category"];
        
        [cat addItemsObject:item];
    }
    return item;
}

- (DTCountCategory *)categoryWithLabel:(NSString *)catLabel
{
    if (!catLabel || catLabel.length == 0) {
        return nil;
    }
    for (int i = 0; i < pCategories.count; ++i) {
        DTCountCategory *cat = (DTCountCategory *)[pCategories objectAtIndex:i];
        NSString *label = [cat valueForKey:@"label"];
        if (([label compare:catLabel options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
            return cat;
        }
    }
    if (pCategories.count < self.maximumCategories) {
        DTCountCategory *newCat = [NSEntityDescription insertNewObjectForEntityForName:@"DTCountCategory" inManagedObjectContext:[[AppController sharedAppController] managedObjectContext]];
        [newCat setValue:catLabel forKey:@"label"];
        
        [pCategories addObject:newCat];
        
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"label" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        [pCategories sortUsingDescriptors:@[sd]];
        
        return newCat;
    }
    return nil;
}

- (void)resetAllCategories
{
    [pCategories removeAllObjects];
    
    [self refreshAllCategories];
}

- (BOOL)deleteCategoryWithLabel:(NSString *)label
{
    NSManagedObjectContext *moc = [[AppController sharedAppController] managedObjectContext];
    
    for (int i = 0; i < pCategories.count; ++i) {
        DTCountCategory *cat = (DTCountCategory *)[pCategories objectAtIndex:i];
        NSString *catLab = [cat valueForKey:@"label"];
        if ([catLab isEqualToString:label]) {
            NSArray *itemsWithCat = [[cat valueForKey:@"items"] allObjects];
            for (DTCountItem *itm in itemsWithCat) {
                [itm setValue:nil forKey:@"category"];
            }
            [pCategories removeObjectAtIndex:i];
            [moc deleteObject:cat];
            if (pCategories.count == 0) {
                [self categoryWithLabel:@"42"];
            }
            return YES;
        }
    }
    return NO;
}

- (BOOL)deleteCategory:(DTCountCategory *)cat
{
    return [self deleteCategoryWithLabel:[cat valueForKey:@"label"]];
}

- (DTCountItem *)removeCategoryFromItem:(DTCountItem *)item
{
    DTCountCategory *itemcat = [item valueForKey:@"category"];
    if (itemcat != nil) {
        [[itemcat mutableSetValueForKey:@"items"] removeObject:item];
        [item setValue:nil forKey:@"category"];
    }
    return item;
}

@end
