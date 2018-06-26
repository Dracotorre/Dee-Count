//
//  StartupOperation.h
//  Dee Count
//
//  Created by David G Shrock on 8/8/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyLocation.h"

@protocol StartupOperationDelegate;

/**
 *  uses AppController to access Managed Objects for import and initial load
 */
@interface StartupOperation : NSOperation {
   
}

@property (nonatomic, weak) id <StartupOperationDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *importURL;
@property (nonatomic, copy, readonly) NSString *importFile;
@property (nonatomic, readonly) BOOL isImporting;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy, readonly) NSArray *resultItems;
@property (nonatomic) BOOL updatingFromOldStore;

- (id)initWithDelegate:(id<StartupOperationDelegate>)delegate;
- (id)initWithURL:(NSURL*)url withDelegate:(id<StartupOperationDelegate>)delegate;
- (id)initWithFile:(NSString *)file withDelegate:(id<StartupOperationDelegate>)delegate;

- (void)cancelImport;

@end

// changed since 2010 version 1
//  - using delegate to inform when stages completed
//
@protocol StartupOperationDelegate <NSObject>

- (void)importDidFinishWithError;
- (void)importDidFinishWithFileError;

/**
 *  locations loaded, still waiting on total items
 */
- (void)startupLoadedLocations:(NSArray *)locations;
- (void)startupDidFinishLoadingForProcess:(StartupOperation *)startOp;
- (void)updateImportProgress:(NSNumber *)progress;

@end
