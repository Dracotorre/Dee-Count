// 
//  MyItem.m
//  DCount
//
//  Created by David Shrock on 10/20/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//

#import "MyItem.h"

#import "MyInventory.h"

@implementation MyItem 

//@synthesize label;
@dynamic label;
@dynamic picture;
@dynamic desc;
@dynamic inventories;
@dynamic picuuid;

- (id)init 
{
	self = [super init];
	if (!self) return nil;
	
	return self;
}

/*
- (BOOL)isEqual:(id)object
{
	if (object == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToItem:object];	
}

- (BOOL)isEqualToItem:(MyItem *)itm
{
	if (self == itm) return YES;
	if (![(id)[self label] isEqual:[itm label]]) return NO;
	return YES;
}*/


@end
