//
//  ItemDetailViewController_iPad.h
//  DCount
//
//  Created by David Shrock on 12/21/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTCountItem.h"
#import "DTCountInventory.h"
#import "LocationSelectActionDelegate.h"

@protocol ItemDetailsUpdatedDelegate;

@interface ItemDetailViewController : UIViewController <UITableViewDelegate> {

}

@property (nonatomic, strong) DTCountItem *item;
//@property (nonatomic, retain) NSString *totalCntString;
@property (nonatomic, weak) id <ItemDetailsUpdatedDelegate> updateDelegate;
@property (nonatomic, weak) id <LocationselectActionDelegate> locSelectDelegate;
@property (nonatomic) BOOL needsDoneButton;

// completion block for caller
@property (nonatomic, copy) void (^dismissBlock)(void);

- (IBAction)updateDescription;

- (DTCountInventory *)inventoryForLocationOfItem:(NSManagedObject *)loc;

@end

@protocol ItemDetailsUpdatedDelegate <NSObject>

//- (void)descriptionUpdated;
- (void)itemDetailValueUpdated;

@end