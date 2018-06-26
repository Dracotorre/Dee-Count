//
//  DTCountLocation.m
//  Dee Count
//
//  Created by David G Shrock on 9/10/14.
//  Copyright (c) 2014 Draco Torre, David G Shrock. All rights reserved.
//

#import "DTCountLocation.h"
#import "DTCountInventory.h"


@implementation DTCountLocation

@synthesize oldName;

@dynamic label;
@dynamic picture;
@dynamic picuuid;
@dynamic defCatLabel;
@dynamic inventories;

- (instancetype)init
{
    self = [super init];
    if (self) {
        // nothing to do now
    }
    
    return self;
}

// custom getter
- (UIImage *)thumbnail
{
    if(![self valueForKey:@"picture"]) {
        return nil;
    }
    
    if (!pthumbnail) {
        // create image from data
        pthumbnail = [UIImage imageWithData:[self valueForKey:@"picture"]];
    }
    return pthumbnail;
}

// udpates image for new thumbnail
- (void)setDataFromImage:(UIImage *)image
{
    
    //[[self picture] release];
    float width = [image size].width;
    
    float multiplier = 70.0f / [image size].height;
    width *= multiplier;
    
    CGRect imageRect = CGRectMake(0, 0, width, 70);
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(imageRect.size, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(imageRect.size);
    }
    
    // render image onto context
    [image drawInRect:imageRect];
    
    pthumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    [self setValue:UIImageJPEGRepresentation(pthumbnail, 0.50) forKey:@"picture"];
    
    UIGraphicsEndImageContext();
}

@end
