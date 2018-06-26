//
//  ImageCache.m
//  DCount
//
//  Created by David Shrock on 10/17/10.
//  Copyright 2010 DracoTorre.com. All rights reserved.
//

#import "ImageCache.h"

static ImageCache *sharedImageCache;  //p186, singleton

@implementation ImageCache
- (id)init
{
	self = [super init];
    if (!self) return nil;
	dictionary = [[NSMutableDictionary alloc] init];
	
	//p218, deal with mem warnings
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
		   selector:@selector(clearCache:) 
			   name:UIApplicationDidReceiveMemoryWarningNotification 
			 object:nil];
	
	return self;
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

#pragma mark Accessing the cache

//p218, mem warning; clear
- (void)clearCache:(NSNotificationCenter *)note
{
	NSLog(@"flushing %lu images out of the cache", (unsigned long)[dictionary count]);
	[dictionary removeAllObjects];
}
- (void)setImage:(UIImage *)i forKey:(NSString *)s
{
	[dictionary setObject:i forKey:s];
	
	//p209
	//creat full path for image
	NSString *imagePath = [self picturePathInDocumentDirectory:(s)];
	
	// turn to JPEG data
	NSData *d = UIImageJPEGRepresentation(i, 0.5);
	
	//wirte to path
	[d writeToFile:imagePath atomically:YES];
}

- (UIImage *)imageForKey:(NSString *)s
{
	//p210, if possible get from dictionary
	UIImage *result = [dictionary objectForKey:s];
	
	if (!result) {
		// create image object from file
		result = [UIImage imageWithContentsOfFile:[self picturePathInDocumentDirectory:(s)]];
		
		// if we found image on fs, place in cache
		if (result) [dictionary setObject:result forKey:s];
		else {
			NSLog(@"Error: unable to find %@", [self picturePathInDocumentDirectory:(s)]);
		}

	}
	return result;
}

- (UIImage *)imageOldForKey:(NSString *)s
{
    UIImage *result = [dictionary objectForKey:s];
    
    if (!result) {
        // create image object from file
        result = [UIImage imageWithContentsOfFile:[self picturePathOldDirectoryForFile:(s)]];
        
        // if we found image on fs, place in cache
        if (result) [dictionary setObject:result forKey:s];
        else {
            NSLog(@"Error: unable to find (old) %@", [self picturePathInDocumentDirectory:(s)]);
        }
        
    }
    return result;
}

- (void)deleteImageForKey:(NSString *)s
{
	[dictionary removeObjectForKey:s];
	
	//p210, don't forget to delet form filesystem
	NSString *path = [self picturePathInDocumentDirectory:(s)];
    //NSLog(@"deleting image at %@", path);
	[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)deleteImageOldForKey:(NSString *)s
{
    [dictionary removeObjectForKey:s];
    NSString *path = [self picturePathOldDirectoryForFile:s];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (NSString *)picturePathOldDirectoryForFile:(NSString *)fileName
{
    // get list of document directories in sandbox
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    // get only doc dir from list and append pics
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    // append passed file to dir and return
    return [documentDirectory stringByAppendingPathComponent:fileName];
}

- (NSString *)picturePathInDocumentDirectory:(NSString *)fileName
{
    if ([fileName hasSuffix:@".jpg"] == NO) {
        fileName = [fileName stringByAppendingString:@".jpg"];
    }
    // get list of document directories in sandbox
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    // get only doc dir from list and append pics
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    documentDirectory = [documentDirectory stringByAppendingPathComponent:@"images"];
    NSFileManager *fileMan = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fileMan fileExistsAtPath:documentDirectory isDirectory:&isDir] == NO) {
        NSError *err;
        if ([fileMan createDirectoryAtPath:documentDirectory withIntermediateDirectories:NO attributes:nil error:&err] == NO) {
            NSLog(@" failed to create images dir");
        }
    }
    
    // append passed file to dir and return
    return [documentDirectory stringByAppendingPathComponent:fileName];
}


#pragma mark Singleton Stuff

+ (ImageCache *)sharedImageCache
{
	if (!sharedImageCache) {
		sharedImageCache = [[ImageCache alloc] init];
	}
	return sharedImageCache;
}

+ (id)allocWithZone:(NSZone *)zone
{
	if (!sharedImageCache) {
		sharedImageCache = [super allocWithZone:zone];
		return sharedImageCache;
	}
	else {
		return nil;
	}
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

@end
