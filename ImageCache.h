//
//  ImageCache.h
//  Homepwner
//
//  Created by David Shrock on 10/17/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ImageCache : NSObject {
	NSMutableDictionary *dictionary;
}
+ (ImageCache *)sharedImageCache;
- (void)setImage:(UIImage *)i forKey:(NSString *)s;
- (UIImage *)imageForKey:(NSString *)s;
- (UIImage *)imageOldForKey:(NSString *)s;
- (void)deleteImageForKey:(NSString *)s;
- (void)deleteImageOldForKey:(NSString *)s;
//- (void)release;

- (NSString *)picturePathOldDirectoryForFile:(NSString *)fileName;
- (NSString *)picturePathInDocumentDirectory:(NSString *)fileName;
@end
