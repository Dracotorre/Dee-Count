//
//  LocationSections.h
//  Dee Count
//
//  Created by David G Shrock on 8/9/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
//  updated from 2010 version 1 for ARC and style

#import <Foundation/Foundation.h>

@interface LocationSections : NSObject


- (instancetype)initWithLocationsArray:(NSArray *)sortedLocations ignore:(BOOL)ignoreLast;
- (NSInteger)convertIndexPathToArrayIndex:(NSIndexPath *)path;
- (NSIndexPath *)getIndexPathFromArrayIndex:(NSInteger)index;
- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (NSString *)sectionTitle:(NSInteger)section;
- (NSArray *)allSectionTitles;
- (NSIndexSet *)insertFromLocationTitle:(NSString *)title;
- (NSIndexSet *)removeFromLocationTitle:(NSString *)title;

@end
