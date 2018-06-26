//
//  DTCountInventory.h
//  Dee Count
//
//  Created by David G Shrock on 9/9/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DTCountItem, DTCountLocation;

@interface DTCountInventory : NSManagedObject

@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) DTCountItem *item;
@property (nonatomic, retain) DTCountLocation *location;

@end
