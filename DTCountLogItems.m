//
//  DTCountLogItems.m
//  Dee Count
//
//  Created by David G Shrock on 9/16/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DTCountLogItems.h"

@interface DTCountLogItems () {
    NSMutableArray *pItemsArray;
}

@end

@implementation DTCountLogItems

- (instancetype)init
{
    self = [super init];
    if (self ) {
        pItemsArray = [[NSMutableArray alloc] initWithCapacity:20];
        self.maxEntries = 49;
    }
    return self;
}

- (NSUInteger)count
{
    return pItemsArray.count;
}

- (NSInteger)addLogEntry:(DTCountLogEntry *)logEntry
{
    [pItemsArray addObject:logEntry];
    if (pItemsArray.count > self.maxEntries) {
        [pItemsArray removeObjectAtIndex:0];
    }
    return pItemsArray.count;
}

- (NSString *)log
{
    // return newest first at the back
    if (pItemsArray.count > 0) {
        NSMutableString *logString = [[NSMutableString alloc] initWithString:@""];
        for (NSInteger i = pItemsArray.count - 1; i >= 0; --i) {
            DTCountLogEntry *logEntry = (DTCountLogEntry *)[pItemsArray objectAtIndex:i];
            [logString appendString:[NSString stringWithFormat:@"%@\n", logEntry.description]];
        }
        
        return [logString copy];
    }
    return @"";
}

- (DTCountLogEntry *)removeLastItem
{
    if (pItemsArray.count > 0) {
        DTCountLogEntry *entry = [pItemsArray objectAtIndex:pItemsArray.count - 1];
        [pItemsArray removeObjectAtIndex:pItemsArray.count - 1];

        return entry;
    }
    return nil;
}

- (void)removeAllItems
{
    [pItemsArray removeAllObjects];
}

@end
