//
//  StartupOperationsWorker.h
//  Dee Count
//
//  Created by David G Shrock on 8/10/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
// not in original 2010 v1

#import <Foundation/Foundation.h>

/**
 * could by any file import or initial data loading
 */
@interface DTCBGOperationsWorker : NSObject

@property (nonatomic, copy ) NSMutableDictionary *bgOpInProgress;
@property (nonatomic, strong) NSOperationQueue *bgOpQueue;

- (void)cancelAll;

@end
