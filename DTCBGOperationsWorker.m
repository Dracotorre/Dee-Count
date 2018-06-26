//
//  StartupOperationsWorker.m
//  Dee Count
//
//  Created by David G Shrock on 8/10/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DTCBGOperationsWorker.h"

@implementation DTCBGOperationsWorker

@synthesize bgOpInProgress = _bgOpInProgress;
@synthesize bgOpQueue = _bgOpQueue;

// override default getters to init only when used

- (NSMutableDictionary *)bgOpInProgress
{
    if (!_bgOpInProgress) {
        _bgOpInProgress = [[NSMutableDictionary alloc] init];
    }
    return _bgOpInProgress;
}

- (NSOperationQueue *)bgOpQueue
{
    if (!_bgOpQueue) {
        _bgOpQueue = [[NSOperationQueue alloc] init];
        // name to help debugging
        _bgOpQueue.name = @"DTC BG OP Queue";
        _bgOpQueue.maxConcurrentOperationCount = 2;
    }
    return _bgOpQueue;
}

- (void)cancelAll
{
    [self.bgOpQueue cancelAllOperations];
}

@end
