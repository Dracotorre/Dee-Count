//
//  DTCountCategoryStore.h
//  Dee Count
//
//  Created by David G Shrock on 9/10/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTCountCategory.h"
#import "DTCountItem.h"

@interface DTCountCategoryStore : NSObject

@property (nonatomic, readonly) NSArray *allCategories;
@property (nonatomic, readonly) NSInteger maximumCategories;

+ (instancetype)sharedStore;

/**
 *  assumed (check first) new item in MOC with category attached
 */
- (DTCountItem *)createNewItemWithLabel:(NSString *)itemLabel withCategoryByLabel:(NSString *)catLabel;

- (DTCountCategory *)categoryWithLabel:(NSString *)catLabel;

- (void)resetAllCategories;

/**
 *  ignores if items in category
 */
- (BOOL)deleteCategoryWithLabel:(NSString *)label;
/**
 *  ignores if items in category
 */
- (BOOL)deleteCategory:(DTCountCategory *)cat;
- (DTCountItem *)removeCategoryFromItem:(DTCountItem *)item;
- (DTCountItem *)itemSetCategory:(DTCountCategory *)cat forItem:(DTCountItem *)item;

@end
