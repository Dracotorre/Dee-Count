//
//  DTCountTotalsPack.m
//  Dee Count
//
//  Created by David G Shrock on 10/3/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DTCountTotalsPack.h"

@implementation DTCountTotalsPack

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.totalCount = 0;
        self.totalInventory = 0;
        self.totalValue = 0.0f;
    }
    return self;
}
@end
