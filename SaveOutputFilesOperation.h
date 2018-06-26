//
//  SaveOutputFilesOperation.h
//  DCount
//
//  Created by David Shrock on 3/30/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//
//  2014 - updated for ARC and changes for iOS 8

#import <Foundation/Foundation.h>

typedef enum SaveOpFileStyle : int {
    SaveOpDCZStyle, SaveOpCSVStyle
}SaveOpFileStyle;

@protocol SaveOutputFilesOperationDelegate;

@interface SaveOutputFilesOperation : NSOperation {
    
}
@property(nonatomic, copy) NSArray *itemsList;
@property(nonatomic, weak) id <SaveOutputFilesOperationDelegate> delegate;
@property(nonatomic, readonly) BOOL limitCompareCount;
@property(nonatomic, readonly) SaveOpFileStyle savedFileStyle;
@property (nonatomic, strong, readonly) NSString *fullFileNameWithDirectory;
@property(nonatomic, strong, readonly) NSString *shortFileName;
@property (nonatomic, strong, readonly) NSString *limitedToLocationLabel;

/**
 * use the short file name including extenstion; see full name in property;
 */
- (id)initWithCompareCountLimit:(BOOL)limitCompareCnt forItems:(NSArray *)itemsLst forLocationLabel:(NSString *)locLabel withFileStyle:(SaveOpFileStyle)fileStyle withFileName:(NSString *)shortFileName withDelegate:(id<SaveOutputFilesOperationDelegate>)del;

@end

@protocol SaveOutputFilesOperationDelegate <NSObject>

- (void)doneSavingOutputDocsForProccess:(SaveOutputFilesOperation *)process;

@end