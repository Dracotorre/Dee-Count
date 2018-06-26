//
//  PreparePrintOutputOperation_iPad.m
//  DCount
//
//  Created by David Shrock on 4/10/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//
// update for ARC and delegate process 8/30/2014

#import "PreparePrintOutputOperation.h"
#import "AppController.h"
#import "DTCountLocation.h"
#import "DTCountItem.h"
#import "DTCountInventory.h"
#import "DTCountCategory.h"

@interface PreparePrintOutputOperation () {
    NSString *pOutputText;
    NSArray *pItemsList;
    NSString *limitedToLocLabel;
    NSString *pCategoryPrintLabel;
}

@end


@implementation PreparePrintOutputOperation

@synthesize limitCompareCount;
@synthesize resultOutputText = pOutputText;
@synthesize itemsList = pItemsList;

- (instancetype)initWithCompareLimit:(BOOL)limitCompareCnt withItems:(NSArray *)itemsLst forLocationLabel:(NSString *)locLabel withDelegate:(id<PreparePrintOutputDelegate>)del
{
    self = [super init];
    if (self) {
        pItemsList = itemsLst;
        limitCompareCount = limitCompareCnt;
        self.delegate = del;
        limitedToLocLabel = locLabel;
    }

    return self;
}

- (instancetype)initWithCategoryPrintLabel:(NSString *)catLabel withItems:(NSArray *)itemsLst withDelegate:(id<PreparePrintOutputDelegate>)del
{
    self = [super init];
    if (self) {
        pItemsList = itemsLst;
        pCategoryPrintLabel = catLabel;
        self.delegate = del;
        limitedToLocLabel = nil;
    }
    
    return self;
}

- (void)main
{
    NSString *spaces = [NSString stringWithFormat:@".................................."];
	NSString *header = [NSString stringWithFormat:@"<html><body>\n<table width='100%%' columns='6' border='0'><tr><td width='24'>%@</td><td width='25'>%@</td><td width='8'>%@</td><td width='8'>%@</td><td width='19'>%@</td><td width='6'>%@</td></tr>\n", NSLocalizedString(@"ID/UPC", @"ID/UPC"), NSLocalizedString(@"name / description", @"name / description"), NSLocalizedString(@"count", @"count"), NSLocalizedString(@"inv", @"inv"), NSLocalizedString(@"Category", @"Category"), NSLocalizedString(@"Value", @"Value")];
    if (limitedToLocLabel.length > 0) {
       header = [NSString stringWithFormat:@"<html><body>\n<table width='100%%' columns='6' border='0'><tr><td width='24'>%@</td><td width='25'>%@</td><td width='9'>%@</td><td width='17'>%@</td><td width='6'>%@</td></tr>\n", NSLocalizedString(@"ID/UPC", @"ID/UPC"), NSLocalizedString(@"name / description", @"name / description"), NSLocalizedString(@"count", @"count"), NSLocalizedString(@"Category", @"Category"), NSLocalizedString(@"Value", @"Value")];
    }
    else if (pCategoryPrintLabel.length > 0) {
        header = [NSString stringWithFormat:@"<html><body>\n<table width='100%%' columns='6' border='0'><tr><td width='24'>%@</td><td width='25'>%@</td><td width='8'>%@</td><td width='8'>%@</td><td width='6'>%@</td></tr>\n", NSLocalizedString(@"ID/UPC", @"ID/UPC"), NSLocalizedString(@"name / description", @"name / description"), NSLocalizedString(@"count", @"count"), NSLocalizedString(@"inv", @"inv"), NSLocalizedString(@"Value", @"Value")];
    }
	NSInteger totalCount = 0;
	NSInteger totalCompare = 0;
    CGFloat totalValue = 0.0f;
	int spaceSkipCnt = 0;
	int spaceSkip = 5;
	BOOL outputLine = YES;
    
	NSMutableString *outputText = [NSMutableString stringWithCapacity:1000];

	AppController *ac = [AppController sharedAppController];
    
    if (limitedToLocLabel.length > 0) {
        [outputText appendString:[NSString stringWithFormat:@"%@\n  \n\n", limitedToLocLabel]];
    }
    else if (pCategoryPrintLabel.length > 0) {
        [outputText appendString:[NSString stringWithFormat:@"%@\n \n\n", pCategoryPrintLabel]];
    }
	[outputText appendString:header];
	
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
			else if (limitedToLocLabel == nil || [limitedToLocLabel isEqualToString:miLocName]) {
				cnt += [[mi valueForKey:@"count"] intValue];
				//totalCount += cnt;
				//if ([locationNamesText length] == 0) [locationNamesText appendString:[miLoc valueForKey:@"label"]];
				//else [locationNamesText appendString:[NSString stringWithFormat:@" - %@", [miLoc valueForKey:@"label"]]];
			}	
			
		}
		if ([self limitCompareCount])
		{
			if (cnt == officialCount) outputLine = NO;
			else outputLine = YES;
		}
		else outputLine = YES;
		
		if (outputLine) {
            totalCount += cnt;
            totalCompare += officialCount;
            
			spaceSkipCnt++;
            NSString *catString = @"none";
            NSString *valString = @" - ";
			NSString *itmIDOut = itmID;
			NSString *descOut;
            if (pCategoryPrintLabel == nil || pCategoryPrintLabel.length == 0) {
                DTCountCategory *cat = [itm valueForKey:@"category"];
                if (cat != nil) {
                    catString = [cat valueForKey:@"label"];
                    if (catString.length > 13) {
                        catString = [NSString stringWithFormat:@"%@...", [catString substringToIndex:13]];
                    }
                }
            }
            
            CGFloat itemVal = [[itm valueForKey:@"value"] floatValue];
            if (itemVal > 0.0f) {
                itemVal = itemVal * cnt;
                totalValue += itemVal;
                valString = [ac formatNSNumber:[NSNumber numberWithFloat:itemVal]];
            }
			//NSString *locsOut;
			if ([itmID length] > 24) itmIDOut = [itmID substringToIndex:24];
			//else itmIDOut = [NSString stringWithFormat:@"%@%@", itmID, [spaces substringToIndex:(24 - [itmID length])]];
			if ([desc length] > 21) descOut = [NSString stringWithFormat:@"%@...", [desc substringToIndex:21]];
			else descOut = [NSString stringWithFormat:@"%@%@", desc, [spaces substringToIndex:(23 - [desc length])]];
			
            if (limitedToLocLabel.length > 0) {
                NSString *tsvline = [NSString stringWithFormat:@"<tr><td>%@</td><td>%@</td><td>%d</td><td>%@</td><td>%@</td></tr>\n", itmIDOut, descOut, cnt, catString, valString];
                [outputText appendString:tsvline];
            }
            else if (pCategoryPrintLabel.length > 0) {
                NSString *tsvline = [NSString stringWithFormat:@"<tr><td>%@</td><td>%@</td><td>%d</td><td>%d</td><td>%@</td></tr>\n", itmIDOut, descOut, cnt, officialCount, valString];
                [outputText appendString:tsvline];
            }
            else {
                NSString *tsvline = [NSString stringWithFormat:@"<tr><td>%@</td><td>%@</td><td>%d</td><td>%d</td><td>%@</td><td>%@</td></tr>\n", itmIDOut, descOut, cnt, officialCount, catString, valString];
                [outputText appendString:tsvline];
            }
			
		}
		if (spaceSkipCnt > spaceSkip)
		{
			spaceSkipCnt = 0;
			[outputText appendString:@"<tr><td><br /></td></tr>\n"];
		}
		//locationNamesText = [NSMutableString stringWithCapacity:10];	
	}
    
    NSString *totalCntStr = [ac formatNumber:totalCount];
    NSString *totalCompStr = [ac formatNumber:totalCompare];
    NSString *totalValueStr = @"";
    if (totalValue > 0.0f) {
        totalValueStr = [ac formatNSNumber:[NSNumber numberWithFloat:totalValue]];
    }
    
    NSString *bottomResults = [NSString stringWithFormat:@"<tr><td> \n</td></tr><tr><td></td><td></td><td>_____</td><td>_____</td></tr>\n<tr><td></td><td>Total:</td><td>%@</td><td>%@</td><td></td><td>%@</td></tr>\n</table>\n</body></html>", totalCntStr, totalCompStr, totalValueStr];
    
    if (limitedToLocLabel.length > 0) {
        bottomResults = [NSString stringWithFormat:@"<tr><td> \n</td></tr><tr><td></td><td></td><td>_____</td></tr>\n<tr><td></td><td>Total:</td><td>%@</td><td></td><td>%@</td></tr>\n</table>\n</body></html>", totalCntStr, totalValueStr];
    }
    else if (pCategoryPrintLabel.length > 0) {
        bottomResults = [NSString stringWithFormat:@"<tr><td> \n</td></tr><tr><td></td><td></td><td>_____</td><td>_____</td></tr>\n<tr><td></td><td>Total:</td><td>%@</td><td>%@</td><td>%@</td></tr>\n</table>\n</body></html>", totalCntStr, totalCompStr, totalValueStr];
    }
    
	[outputText appendString:bottomResults];
	
    pOutputText = [outputText copy];
    
    [(NSObject *)self.delegate performSelectorOnMainThread:@selector(donePreparePrintForProccess:) withObject:self waitUntilDone:YES];
    
}
@end
