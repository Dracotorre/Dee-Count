//
//  ClearCountsOperation_iPad.h
//  DCount
//
//  Created by David Shrock on 6/25/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//
//  updated (8/19/2014) to include other files from v1:
//     RemoveInventoryOperation
//  with enum to select which kind of removal
//  and for ARC

#import <Foundation/Foundation.h>

/**
 * kind of clear
 */
typedef enum ClearCountTask : int {
    /**
     * reset counts to zero
     */
    ClearAllCountsKeepInventory,
    
    ClearAllCountsReplaceInventory,
    
    /**
     * delete all items
     */
    ClearAllItems,
    
    /**
     * delete only items with zero count
     */
    ClearZeroCountItems,
    
    UpdateEmptyCategoryForItems,
    
    UpdateCategoryForItems
    
}UpdateInventoryTask;

@protocol UpdateInventoryOperationDelegate;

@interface InventoryUpdateOperation : NSOperation {
    
}
@property (nonatomic, copy) NSArray *itemsList;
/**
 * only guaranteed on clear counts, else assume invalid
 */
@property (nonatomic, readonly) BOOL secretCompareLocationExists;
@property (nonatomic, readonly) UpdateInventoryTask clearTask;
@property (nonatomic, weak) id <UpdateInventoryOperationDelegate> delegate;

- (instancetype)initWithTotalItems:(NSArray *)itemsLst forClearTask:(UpdateInventoryTask)clrTask withDelegate:(id<UpdateInventoryOperationDelegate>)del;
- (instancetype)initForEmptyCategoryUpdateWithItems:(NSArray *)itemsLst forCategoryLabel:(NSString *)catLabel withDelegate:(id<UpdateInventoryOperationDelegate>)del;

@end

@protocol UpdateInventoryOperationDelegate <NSObject>

- (void)doneUpdatingInventoryForProcess:(InventoryUpdateOperation *)updateOp;
- (void)updateClearingCountsProgress:(NSNumber *)progress;

@end