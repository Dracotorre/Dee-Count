//
//  PreparePrintOutputOperation_iPad.h
//  DCount
//
//  Created by David Shrock on 4/10/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//
// updated for ARC and delegate process 8/30/2014

#import <Foundation/Foundation.h>

@protocol PreparePrintOutputDelegate;

@interface PreparePrintOutputOperation :NSOperation {

}
@property(nonatomic, copy) NSArray *itemsList;
@property(nonatomic, weak) id <PreparePrintOutputDelegate>delegate;
@property(nonatomic, copy) NSString *resultOutputText;
@property(assign) BOOL limitCompareCount;
@property(nonatomic, strong) NSString *key;

- (instancetype)initWithCompareLimit:(BOOL)limitCompareCnt withItems:(NSArray *)itemsLst forLocationLabel:(NSString *)locLabel withDelegate:(id<PreparePrintOutputDelegate>)del;
- (instancetype)initWithCategoryPrintLabel:(NSString *)catLabel withItems:(NSArray *)itemsLst withDelegate:(id<PreparePrintOutputDelegate>)del;

@end

@protocol PreparePrintOutputDelegate <NSObject>

- (void)donePreparePrintForProccess:(PreparePrintOutputOperation *)process;

@end