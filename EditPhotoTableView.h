//
//  EditPhotoTableView_Shared.h
//  DCount
//
//  Created by David Shrock on 3/20/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditPhotoDelegate;

@interface EditPhotoTableView : UITableViewController {
}
@property (nonatomic, weak) id <EditPhotoDelegate> delegate;
@property (nonatomic) BOOL hasCurrentPhoto;

@end


@protocol EditPhotoDelegate
- (void)removePhoto;
- (void)addPhoto;
@end