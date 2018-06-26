//
//  MyInventory.h
//  DCount
//
//  Created by David Shrock on 10/20/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class MyItem;
@class MyLocation;

@interface MyInventory :  NSManagedObject  
{
}

@property (nonatomic, strong) NSNumber * count;
@property (nonatomic, strong) MyLocation * location;
@property (nonatomic, strong) MyItem * item;

@end



