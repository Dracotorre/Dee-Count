//
//  SaveOutputFilesOperation.m
//  DCount
//
//  Created by David Shrock on 3/30/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//

#import "SaveOutputFilesOperation.h"
#import "AppController.h"
#import "DTCountItem.h"
#import "DTCountLocation.h"
#import "DTCountInventory.h"
#import "DTCountCategory.h"

@interface SaveOutputFilesOperation () {
    BOOL pLimitCompareCount;
    int saveWhichFile;
    NSArray *pItemsList;
    SaveOpFileStyle pFileStyle;
    NSURL *pFileURL;
    NSString *pFileName;
    NSString *pFullFileName;
    NSString *pLimitToLocLabel;
}

@end

@implementation SaveOutputFilesOperation
@synthesize limitCompareCount = pLimitCompareCount;
@synthesize itemsList = pItemsList;
@synthesize savedFileStyle = pFileStyle;
@synthesize shortFileName = pFileName;
@synthesize fullFileNameWithDirectory = pFullFileName;
@synthesize limitedToLocationLabel = pLimitToLocLabel;


- (id)initWithCompareCountLimit:(BOOL)limitCompareCnt
                       forItems:(NSArray *)itemsLst
                forLocationLabel:(NSString *)locLabel
                  withFileStyle:(SaveOpFileStyle)fileStyle
                          withFileName:(NSString *)shortFileName
                   withDelegate:(id<SaveOutputFilesOperationDelegate>)del
{
    self = [super init];
    if (self) {
        self.delegate = del;
        pItemsList = itemsLst;
        pLimitToLocLabel = locLabel;
        pLimitCompareCount = limitCompareCnt;
        pFileStyle = fileStyle;
        pFileName = shortFileName;
        pFullFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:pFileName];
    }
    return self;
}

/* * *
 *       v1 DCZ: UPC \t description \t count \t inventory-count \t locations-
 *       v2 DCZ: UPC \t description \t count \t inventory-count \t locations- \t category \t value
 
 */

- (void)main
{
    NSString *header = NSLocalizedString(@"HeaderTsv", @"UPC/ID\tDescription\tCount\tInventory\tLocations\tCategory\tValue ");
    if (pFileStyle == SaveOpCSVStyle) {
        header = NSLocalizedString(@"HeaderCSV", @"UPC,Description,Count,Inventory,Locations,Category,Value");
    }
    NSUInteger totalCount = 0;
    NSUInteger totalCompare = 0;
    CGFloat totalValue = 0.0f;
    BOOL outputLine = YES;		 
    NSMutableString *outputText = [NSMutableString stringWithCapacity:1000];
    NSMutableString *locationNamesText = [NSMutableString stringWithCapacity:10];
    AppController *ac = [AppController sharedAppController];
    
    if (pLimitToLocLabel.length > 0) {
        [outputText appendString:[NSString stringWithFormat:@"%@\r\n", pLimitToLocLabel]];
    }
    
    [outputText appendString:[NSString stringWithFormat:@"%@\r\n", header]];
    
    for (int i = 0; i < pItemsList.count; ++i)
    {
        DTCountItem *itm = [pItemsList objectAtIndex:i];
        NSString *desc = [NSString stringWithFormat:@""];
        if ([itm valueForKey:@"desc"] != nil) {
            desc = [itm valueForKey:@"desc"];
        }
        int officialCount = 0;
        NSString *itmID = [NSString stringWithFormat:@"%@", [itm valueForKey:@"label"]];
        int cnt = 0;
        NSArray *inventoriesForItem = [[itm valueForKey:@"inventories"] allObjects];
        
        for (DTCountInventory *mi in inventoriesForItem)
        {
            DTCountLocation *miLoc = [mi valueForKey:@"location"];
            NSString *miLocName = [miLoc valueForKey:@"label"];
            if ([miLocName isEqualToString:[ac totalCountsSecretLocationName]])
            {
                officialCount = [[mi valueForKey:@"count"] intValue];
                //totalCompare += officialCount;
            }
            else {
                if (pLimitToLocLabel == nil || [pLimitToLocLabel isEqualToString:miLocName]) {
                    cnt += [[mi valueForKey:@"count"] intValue];
                    //totalCount += cnt;
                }
                if ([locationNamesText length] == 0) [locationNamesText appendString:[miLoc valueForKey:@"label"]];
                else [locationNamesText appendString:[NSString stringWithFormat:@" - %@", [miLoc valueForKey:@"label"]]];
            }	
            
        }
        if (self.limitCompareCount)
        {
            if (cnt == officialCount) {
                outputLine = NO;
            }
            else {
                outputLine = YES;
            }
        }
        else {
            if (cnt > 0 || officialCount > 0) {
                outputLine = YES;
            }
            else outputLine = NO;
        }
        
        
        if (outputLine) {
            totalCompare += officialCount;
            totalCount += cnt;
            
            NSString *line;
            NSString *catString = @"";
            NSString *valString = @" - ";

            DTCountCategory *cat = [itm valueForKey:@"category"];
            if (cat != nil) {
                catString = [cat valueForKey:@"label"];
            }
            NSNumber *itmVal = [itm valueForKey:@"value"];
            if (itmVal > 0) {
                CGFloat flval = [itmVal floatValue];
                totalValue += flval * cnt;
                //valString = [NSString stringWithFormat:@"%.02f", flval];
                valString = [ac formatNSNumber:[NSNumber numberWithFloat:flval]];  // uses locale
            }

            if (pFileStyle == SaveOpDCZStyle) {
                line = [NSString stringWithFormat:@"%@\t%@\t%d\t%d\t%@\t%@\t%@\r\n", itmID, desc, cnt, officialCount, locationNamesText, catString, valString];
            }
            else {
                line = [NSString stringWithFormat:@"'%@','%@',%d,%d,'%@','%@',\"%@\"\r\n", [itmID stringByReplacingOccurrencesOfString:@"," withString:@"_"], [desc stringByReplacingOccurrencesOfString:@"," withString:@"_"], cnt, officialCount, [locationNamesText stringByReplacingOccurrencesOfString:@"," withString:@"_"], [catString stringByReplacingOccurrencesOfString:@"," withString:@"_"], valString];
            }
            [outputText appendString:line];
        }
        
        locationNamesText = [NSMutableString stringWithCapacity:10];	
    }
    NSString *bottomResults = nil;
    NSString *totalLabel = NSLocalizedString(@"Total:", @"Total:");
    
    NSString *totalValString = [ac formatNSNumber:[NSNumber numberWithFloat:totalValue]];
    
    if (pFileStyle == SaveOpDCZStyle) {
        bottomResults = [NSString stringWithFormat:@"\n\t%@\t%lu\t%lu\t\t\t%@\r\n", totalLabel, (unsigned long)totalCount, (unsigned long)totalCompare, totalValString];
    }
    else {
        bottomResults = [NSString stringWithFormat:@"\n,%@,%lu,%lu,,,\"%@\"\r\n", totalLabel, (unsigned long)totalCount, (unsigned long)totalCompare, totalValString];
    }
    [outputText appendString:bottomResults];
    
    NSError *err;

    
    BOOL check = [outputText writeToFile:pFullFileName
                              atomically:YES
                                encoding:NSUTF8StringEncoding
                                   error:&err];
        
    if (!check) {
        NSLog(@"Error writing file: %@", [err localizedDescription]);
    }

    [(NSObject *)self.delegate performSelectorOnMainThread:@selector(doneSavingOutputDocsForProccess:) withObject:self waitUntilDone:YES];
    
}

@end
