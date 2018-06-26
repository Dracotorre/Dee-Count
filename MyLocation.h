//
//  MyLocation.h
//  DCount
//
//  Created by David Shrock on 10/20/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class MyInventory;

@interface MyLocation :  NSManagedObject  
{
	UIImage *pthumbnail;
	
}
@property (readonly) UIImage *thumbnail;
@property (strong, nonatomic) NSString *oldName;

@property (nonatomic, copy) NSString * label;
@property (nonatomic, copy) NSData * picture;
@property (nonatomic, strong) NSSet* inventories;
@property (nonatomic, copy) NSString * picuuid;


- (void)setDataFromImage:(UIImage *)image;

@end


@interface MyLocation (CoreDataGeneratedAccessors)
- (void)addInventoriesObject:(MyInventory *)value;
- (void)removeInventoriesObject:(MyInventory *)value;
- (void)addInventories:(NSSet *)value;
- (void)removeInventories:(NSSet *)value;

@end

