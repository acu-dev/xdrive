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


+ (NSString *)appDocuments
{
	return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
}

+ (void)moveFileAtPath:(NSString *)oldFilePath toPath:(NSString *)newFilePath
{
	XDrvDebug(@"Moving file from path: %@ to path: %@", oldFilePath, newFilePath);
	NSError *error = nil;
	
	// Create destination directory
	NSString *destinationDirPath = [newFilePath stringByDeletingLastPathComponent];
	BOOL dirExists = [[NSFileManager defaultManager] createDirectoryAtPath:destinationDirPath 
											   withIntermediateDirectories:YES 
																attributes:nil 
																	 error:&error];
	if (error)
	{
		XDrvLog(@"Problem creating destination directory: %@", error);
	}
	if (!dirExists)
	{
		XDrvLog(@"Unable to move file - destination dir does not exist: %@", destinationDirPath);
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
