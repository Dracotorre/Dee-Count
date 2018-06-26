//
//  DCountOldStore.h
//  Dee Count
//
//  Created by David G Shrock on 9/9/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DCountOldStore : NSObject

+ (instancetype)sharedStore;

- (NSArray *)loadAllItems;

- (NSArray *)loadAllLocations;

- (NSArray *)allInstancesOf:(NSString *)entityName orderedBy:(NSString *)attName;

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext;
@end
