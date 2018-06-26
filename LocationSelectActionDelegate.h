//
//  LocationSelectActionDelegate.h
//  Dee Count
//
//  Created by David Shrock on 7/22/11.
//  Copyright 2011 DracoTorre.com. All rights reserved.
//
@class DTCountLocation;

@protocol LocationselectActionDelegate
- (void) selectedLocation:(DTCountLocation *)loc selectedItemLabel:(NSString *)label;
@end
