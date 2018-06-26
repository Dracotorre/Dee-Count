//
//  DCountOldStore.m
//  Dee Count
//
//  Created by David G Shrock on 9/9/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DCountOldStore.h"

@import CoreData;

@interface DCountOldStore () {
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}


@end

@implementation DCountOldStore


+ (instancetype)sharedStore
{
    static DCountOldStore *sharedSt = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSt = [[self alloc] initPrivate];
    });
    return sharedSt;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[DCountOldStore sharedStore]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (NSArray *)loadAllItems
{
    return [self allInstancesOf:@"Item" orderedBy:@"label"];
}

- (NSArray *)loadAllLocations
{
    return [self allInstancesOf:@"Location" orderedBy:@"label"];
}

- (NSArray *)allInstancesOf:(NSString *)entityName orderedBy:(NSString *)attName
{
    //get managed context
    NSManagedObjectContext *moc = [self managedObjectContext];
    
    // creat efetch request fetches from entityname
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:moc];
    
    [fetch setEntity:entity];
    
    // if attname then sort
    if (attName) {
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:attName ascending:YES];
        
        NSArray *sortDescriptors = [NSArray arrayWithObject:sd];
        
        [fetch setSortDescriptors:sortDescriptors];
    }
    
    // attempt fetch
    NSError *error;
    NSArray *result = [moc executeFetchRequest:fetch error:&error];
    
    if (!result) {
        // TODO: move this??
        /*
         UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FetchFailed", @"Fetch Failed")
         message:[error localizedDescription]
         delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
         otherButtonTitles:nil];
         [alertView show];
         */
        return nil;
    }
    return result;
}

- (NSString *)applicationMainDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark - core data; copied from old AppController_Shared

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
        
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"DCount" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel_;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationMainDirectory] stringByAppendingPathComponent: @"DCount.sqlite"]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *mainDir = [self applicationMainDirectory];
    NSError *errCreate = nil;
    
    if (![fileManager fileExistsAtPath:mainDir])
    {
        [fileManager createDirectoryAtPath:mainDir withIntermediateDirectories:NO attributes:nil error:&errCreate];
    }
    
    //[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    
    NSError *error = nil;
    
    // for data migration
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES };
    
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
        [managedObjectContext_ rollback];
    }
    
    return persistentStoreCoordinator_;
}


@end
