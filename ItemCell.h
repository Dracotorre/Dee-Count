//
//  ItemCell.h
//  DCount
//
//  Created by David Shrock on 10/24/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//
// updated for ARC and dual-purpose with category, 2014

#import <UIKit/UIKit.h>
#import "DTCountItem.h"
#import "DTCountCategory.h"
/*
@protocol ItemCutDelegate
-(void) itemCutID:(NSString *)idstr;
@end
*/

@protocol ItemCellActionDelegate
- (void) selectedItemCodeToIncrement:(NSString *)code;
- (void) selectedItemDetailsForLabel:(NSString *)label;
@end

@interface ItemCell : UITableViewCell {
	
	
}
//@property (nonatomic, assign) id itemCutDelegate;
@property (nonatomic, weak) id <ItemCellActionDelegate> cellActionDelegate;
@property (nonatomic) BOOL isTotalType;

/**
 * generic cell, negative totalCnt to not display. See setItem and setCategoryItem for helpers
 */
- (void)setUniversalLabel:(NSString *)label withCount:(NSInteger)count withTotalCount:(NSInteger)totalCnt withDescription:(NSString *)desc isChecked:(BOOL)checked;
- (void)setItem:(DTCountItem *)item setCount:(NSInteger)count setTotalCount:(NSInteger)totalCnt;
- (void)setCategoryItem:(DTCountCategory *)category isChecked:(BOOL)checked;
- (NSString *)countText;
- (void)showCopyMenuWithNegate:(BOOL)withNegateIncrement;
@end
