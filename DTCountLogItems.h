//
//  DTCountLogItems.h
//  Dee Count
//
//  Created by David G Shrock on 9/16/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTCountLogEntry.h"

@interface DTCountLogItems : NSObject

/**
 * reverse-order list of lines, one line per entry
 */
@property (nonatomic, copy) NSString *log;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic) NSUInteger maxEntries;

/**
 * use positive or negative for values
 */
- (NSInteger)addLogEntry:(DTCountLogEntry *)logEntry;

/**
 *  remove most recent entry added
 */
- (DTCountLogEntry *)removeLastItem;

- (void)removeAllItems;

@end
