//
//  DTCountLogEntry.m
//  Dee Count
//
//  Created by David G Shrock on 9/16/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DTCountLogEntry.h"

@interface DTCountLogEntry () {
    NSString *pLabel;
    NSInteger pValue;
}

@end

@implementation DTCountLogEntry

@synthesize label = pLabel;
@synthesize value = pValue;

- (instancetype)initWithLabel:(NSString *)labelStr withValue:(NSInteger)val
{
    self = [super init];
    if (self) {
        pLabel = labelStr;
        pValue = val;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithLabel:@"none" withValue:0];
}

- (NSString *)description
{
    if (pValue > 0) {
        return [NSString stringWithFormat:@"%@ %@%ld", pLabel, NSLocalizedString(@"addOperator", @"+"), (long)pValue];
    }
    return [NSString stringWithFormat:@"%@ %ld", pLabel, (long)pValue];
}
@end
