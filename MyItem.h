//
//  MyItem.h
//  DCount
//
//  Created by David Shrock on 10/20/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class MyInventory;

@interface MyItem :  NSManagedObject  
{
	
}

@property (nonatomic, copy) NSString * label;
@property (nonatomic, copy) NSData * picture;
@property (nonatomic, copy) NSString * desc;
@property (nonatomic, strong) NSSet* inventories;
@property (nonatomic, copy) NSString * picuuid;

@end


@interface MyItem (CoreDataGeneratedAccessors)
- (void)addInventoriesObject:(MyInventory *)value;
- (void)removeInventoriesObject:(MyInventory *)value;
- (void)addInventories:(NSSet *)value;
- (void)removeInventories:(NSSet *)value;

@end

