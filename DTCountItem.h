//
//  DTCountItem.h
//  Dee Count
//
//  Created by David G Shrock on 9/9/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DTCountCategory, DTCountInventory;

@interface DTCountItem : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * picuuid;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSData * picture;
@property (nonatomic, retain) NSNumber * value;
@property (nonatomic, retain) NSSet *inventories;
@property (nonatomic, retain) DTCountCategory *category;
@end

@interface DTCountItem (CoreDataGeneratedAccessors)

- (void)addInventoriesObject:(DTCountInventory *)value;
- (void)removeInventoriesObject:(DTCountInventory *)value;
- (void)addInventories:(NSSet *)values;
- (void)removeInventories:(NSSet *)values;

@end
