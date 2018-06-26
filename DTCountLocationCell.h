//
//  DTCountLocationCell.h
//  Dee Count
//
//  Created by David G Shrock on 8/9/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
//  updated from 2010 version 1 for ARC and style

#import <UIKit/UIKit.h>

@class DTCountLocation;

@interface DTCountLocationCell : UITableViewCell

@property (nonatomic, strong) UILabel *nameLabel;

- (void)setLocation:(DTCountLocation *)loc;
@end
