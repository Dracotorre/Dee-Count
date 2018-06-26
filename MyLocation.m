// 
//  MyLocation.m
//  DCount
//
//  Created by David Shrock on 10/20/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//

#import "MyLocation.h"
#import "MyInventory.h"

@implementation MyLocation 

@synthesize oldName;

@dynamic label;
@dynamic picture;             // thumbnail data for storage
@dynamic inventories;
@dynamic picuuid;             // UUID to full pic in cache

- (id)init 
{
	self = [super init];
	if (!self) return nil;
	
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
/*
static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
	float fw, fh;
	if (ovalWidth == 0 || ovalHeight == 0) {
		CGContextAddRect(context, rect);
		return;
	}
	CGContextSaveGState(context);
	CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
	CGContextScaleCTM (context, ovalWidth, ovalHeight);
	fw = CGRectGetWidth (rect) / ovalWidth;
	fh = CGRectGetHeight (rect) / ovalHeight;
	CGContextMoveToPoint(context, fw, fh/2);
	CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
	CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
	CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
	CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
	CGContextClosePath(context);
	CGContextRestoreGState(context);
}
*/

@end
