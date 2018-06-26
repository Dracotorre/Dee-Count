//
//  DTCountLogEntry.h
//  Dee Count
//
//  Created by David G Shrock on 9/16/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTCountLogEntry : NSObject

@property (nonatomic, copy) NSString *label;
@property (nonatomic, readonly) NSInteger value;

- (instancetype)initWithLabel:(NSString *)label withValue:(NSInteger)value;

@end
