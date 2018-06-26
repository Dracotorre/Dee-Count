//
//  DTCountCategory.h
//  Dee Count
//
//  Created by David G Shrock on 9/9/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DTCountItem;

@interface DTCountCategory : NSManagedObject

@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSSet *items;
@end

@interface DTCountCategory (CoreDataGeneratedAccessors)

- (void)addItemsObject:(DTCountItem *)value;
- (void)removeItemsObject:(DTCountItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
