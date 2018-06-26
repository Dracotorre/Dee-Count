//
//  LocationSections.m
//  Dee Count
//
//  Created by David G Shrock on 8/9/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//
//  updated from 2010 version 1 for ARC and style

#import "LocationSections.h"
#import "DTCountLocation.h"

@interface LocationSections () {
    NSMutableArray *sectionTitles;
    NSMutableArray *sectionCounts;
    NSMutableArray *displaySecTitles;
}
@property (nonatomic, strong, readonly) NSString *allowedHeaders;
@property (nonatomic, strong, readonly) NSString *specialLessThanAllowedHeader;
@property (nonatomic, strong, readonly) NSString *specialHigherThanAllowedHeader;

@end

@implementation LocationSections

- (NSString *)allowedHeaders
{
    return @"0987654321QWERTYUIOPASDFGHJKLZXCVBNM ";
}

- (NSString *)specialLessThanAllowedHeader
{
    return @".";
}

- (NSString *)specialHigherThanAllowedHeader
{
    return @"#";
}

- (instancetype)initWithLocationsArray:(NSArray *)sortedLocations ignore:(BOOL)ignoreLast
{
    self = [super init];
    if (self) {
        sectionTitles = [[NSMutableArray alloc] initWithCapacity:10];
        sectionCounts = [[NSMutableArray alloc] initWithCapacity:10];
        if (sortedLocations == nil) return self;
        
        NSCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:self.allowedHeaders];
        
        int idxLim = (int)sortedLocations.count;
        if (ignoreLast) idxLim--;
        NSString *lastChar = nil;
        //int curIdx = 0;
        int curCharCount = 0;
        
        for (int i = 0; i < idxLim; ++i)
        {
            DTCountLocation *loc = (DTCountLocation *)[sortedLocations objectAtIndex:i];
            NSString *locName = [loc valueForKey:@"label"];
            NSString *curChar = [self sectionHeaderForName:locName withAllowedChars:allowedSet];

            if (i == 0) {
                lastChar = curChar;
                curCharCount = 1;
            }
            else if ([lastChar isEqualToString:curChar]) curCharCount++;
            else {
                [sectionCounts addObject:[NSNumber numberWithInt:curCharCount]];
                [sectionTitles addObject:lastChar];
                curCharCount = 1;
                lastChar = curChar;
            }
        }
        if (lastChar != nil) {
            [sectionCounts addObject:[NSNumber numberWithInt:curCharCount]];
            [sectionTitles addObject:lastChar];
        }
        displaySecTitles = [sectionTitles mutableCopy];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithLocationsArray:nil ignore:YES];
}

- (NSString *)sectionHeaderForName:(NSString *)name withAllowedChars:(NSCharacterSet *)allowedSet
{
    NSString *sectionChar = [[name substringToIndex:1] uppercaseString];
    
    if ([sectionChar rangeOfCharacterFromSet:allowedSet].length <= 0) {
        NSComparisonResult compRes = [name localizedCaseInsensitiveCompare:@"0"];

        if (compRes == NSOrderedAscending) {
            return  self.specialLessThanAllowedHeader;
        }
        compRes = [name localizedCaseInsensitiveCompare:@"Z"];
        if (compRes == NSOrderedDescending) {
            return self.specialHigherThanAllowedHeader;
        }
        else {
            NSLog(@" need special header???");
        }
        
    }
    
    return sectionChar;
}

- (NSInteger)convertIndexPathToArrayIndex:(NSIndexPath *)path
{
    NSInteger result = 0;
    if ([path section] >= sectionTitles.count) return result;
    
    for (int i = 0; i <= [path section]; ++i)
    {
        if (i == [path section]) {
            result += [path row];
            break;
        }
        else {
            int cnt = [(NSNumber *)[sectionCounts objectAtIndex:i] intValue];
            result += cnt;
        }
    }
    return result;
}
- (NSIndexPath *)getIndexPathFromArrayIndex:(NSInteger)index
{
    int totalCnt = 0;
    int section = 0;
    for (int i = 0; i < sectionTitles.count; ++i)
    {
        int cnt = [(NSNumber *)[sectionCounts objectAtIndex:i] intValue];
        if (cnt + totalCnt > index)
        {
            section = i;
            break;
        }
        else totalCnt += cnt;
    }
    return [NSIndexPath indexPathForRow:index - totalCnt inSection:section];
}

- (NSInteger)numberOfSections
{
    return sectionTitles.count;
}
- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    NSNumber *num = (NSNumber *)[sectionCounts objectAtIndex:section];
    
    return [num intValue];
}
- (NSString *)sectionTitle:(NSInteger)section
{
    //if (section >= sectionTitles.count) {
    //    return [sectionTitles lastObject];
    //}
    return (NSString *)[sectionTitles objectAtIndex:section];
}

- (NSArray *)allSectionTitles
{
    return [sectionTitles copy];
}

/**
 *  nil if none inserted
 */
- (NSIndexSet *)insertFromLocationTitle:(NSString *)title
{
    NSCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:self.allowedHeaders];
    
    NSString *sectionHeader = [self sectionHeaderForName:title withAllowedChars:allowedSet];
    
    BOOL found = NO;
    int idx = -1;
    NSIndexSet *result = nil;
    
    for (int i = 0; i < sectionTitles.count; ++i)
    {
        NSComparisonResult compRes = [sectionHeader localizedCaseInsensitiveCompare:(NSString *)[sectionTitles objectAtIndex:i]];
        
        if (compRes == NSOrderedSame)
        {
            int count = [(NSNumber *)[sectionCounts objectAtIndex:i] intValue] + 1;
            [sectionCounts removeObjectAtIndex:i];
            [sectionCounts insertObject:[NSNumber numberWithInt:count] atIndex:i];
            
            found = YES;
            break;
        }
        else if (![sectionHeader isEqualToString:self.specialHigherThanAllowedHeader] && compRes == NSOrderedAscending)
        {
            idx = i;
            break;
        }
        
    }
    if (!found) {
        if (idx >= 0) {
            [sectionTitles insertObject:sectionHeader atIndex:idx];
            [sectionCounts insertObject:[NSNumber numberWithInt:1] atIndex:idx];
            result = [NSIndexSet indexSetWithIndex:idx];
        }
        else {
            [sectionCounts addObject:[NSNumber numberWithInt:1]];
            [sectionTitles addObject:sectionHeader];
            result = [NSIndexSet indexSetWithIndex:[sectionCounts count] - 1];
        }
        
        
    }
    return result;
}

- (void)updateDisplayTitles
{
    [displaySecTitles removeAllObjects];
    for (int i = (int)sectionTitles.count - 1; i >= 0; --i)
    {
        int count = [(NSNumber *)[sectionCounts objectAtIndex:i] intValue];
        if (count > 0) {
            [displaySecTitles addObject:[NSString stringWithFormat:@"%@", [sectionTitles objectAtIndex:i]]];
        }
    }
}

/**
 *  does not clear title if count reaches zero.
 *  call clearZeroCounts or re-init later
 */
- (NSIndexSet *)removeFromLocationTitle:(NSString *)title
{
    NSCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:self.allowedHeaders];
    NSString *sectionHeader = [self sectionHeaderForName:title withAllowedChars:allowedSet];
    
    NSIndexSet *result = nil;
    for (int i = 0; i < sectionTitles.count; ++i)
    {
        if ([sectionHeader isEqualToString:(NSString *)[sectionTitles objectAtIndex:i]])
        {
            int count = [(NSNumber *)[sectionCounts objectAtIndex:i] intValue] - 1;
            [sectionCounts removeObjectAtIndex:i];
            
            if (count <= 0) {
                [sectionTitles removeObjectAtIndex:i];
                result = [NSIndexSet indexSetWithIndex:i];
            }
            else {
                [sectionCounts insertObject:[NSNumber numberWithInt:count] atIndex:i];
            }
             
            //[sectionCounts insertObject:[NSNumber numberWithInt:count] atIndex:i];
            break;
        }
    }
    //[self updateDisplayTitles];
    return result;
}

@end
