//
//  DTCountTotalsPack.h
//  Dee Count
//
//  Created by David G Shrock on 10/3/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DTCountTotalsPack : NSObject

@property (nonatomic, strong) NSArray *itemList;
@property (nonatomic) NSUInteger totalCount;
@property (nonatomic) NSUInteger totalInventory;
@property (nonatomic) CGFloat totalValue;

@end
