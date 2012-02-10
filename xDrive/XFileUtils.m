//
//  XFileManager.m
//  xDrive
//
//  Created by Chris Gibbs on 10/14/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "XFileUtils.h"
#import "XDriveConfig.h"

@implementation XFileUtils


+ (NSString *)applicationDocumentsDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths lastObject];
}

+ (NSString *)applicationCachesDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths lastObject];
}

+ (void)moveFileAtPath:(NSString *)oldFilePath toPath:(NSString *)newFilePath
{
	XDrvDebug(@"Moving file from path: %@ to path: %@", oldFilePath, newFilePath);
	NSError *error = nil;
	
	// Create destination directory(s)
	NSString *destinationDirPath = [newFilePath stringByDeletingLastPathComponent];
	BOOL dirExists = [[NSFileManager defaultManager] createDirectoryAtPath:destinationDirPath 
											   withIntermediateDirectories:YES 
																attributes:nil 
																	 error:&error];
	if (error || !dirExists)
	{
		XDrvLog(@"Problem creating destination directory: %@", error);
		return;
	}
	
	// Move file
	error = nil;
	[[NSFileManager defaultManager] moveItemAtPath:oldFilePath toPath:newFilePath error:&error];
	if (error)
	{
		XDrvLog(@"Problem moving file: %@", error);
	}
}


@end
