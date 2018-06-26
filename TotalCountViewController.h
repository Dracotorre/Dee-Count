//
//  TotalCountViewController_iPad.h
//  DCount
//
//  Created by David Shrock on 1/9/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//
// renamed from v1 and updated for ARC

#import <UIKit/UIKit.h>
#import "LocationSelectActionDelegate.h"
#import "DataDocViewController.h"
#import "ItemDetailViewController.h"


@interface TotalCountViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, LocationselectActionDelegate, DataDocDelegate, ItemDetailsUpdatedDelegate> {

}
/**
 * all items including with zero count
 */
@property (nonatomic, copy) NSArray *itemsLongList;
/**
 * items without zero count
 */
@property (nonatomic, copy) NSArray *itemsShortList;
@property (nonatomic) int curSrchIdx;
@property (nonatomic) BOOL emailExportSupported;
// completion block for caller
@property (nonatomic, copy) void (^dismissBlock)(void);
@property (nonatomic, weak) id <LocationselectActionDelegate>locSelectDelegate;
@property (nonatomic, weak) id <DataDocDelegate>dataDocDelegate;


- (void)reloadData;
- (void)searchForText:(NSString *)txt;

@end
