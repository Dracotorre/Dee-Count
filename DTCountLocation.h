//
//  DTCountLocation.h
//  Dee Count
//
//  Created by David G Shrock on 9/10/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class DTCountInventory;

@interface DTCountLocation : NSManagedObject {
    UIImage *pthumbnail;
}

@property (readonly) UIImage *thumbnail;
@property (strong, nonatomic) NSString *oldName;

@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSData * picture;
@property (nonatomic, retain) NSString * picuuid;
@property (nonatomic, retain) NSString * defCatLabel;
@property (nonatomic, retain) NSSet *inventories;

- (void)setDataFromImage:(UIImage *)image;

@end

@interface DTCountLocation (CoreDataGeneratedAccessors)

- (void)addInventoriesObject:(DTCountInventory *)value;
- (void)removeInventoriesObject:(DTCountInventory *)value;
- (void)addInventories:(NSSet *)values;
- (void)removeInventories:(NSSet *)values;

@end
