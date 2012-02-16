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


#pragma mark - Paths

+ (NSString *)cachesPath
{
	static dispatch_once_t onceToken;
	static NSString *cachedPath;
	
	dispatch_once(&onceToken, ^{
		cachedPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];	
	});
	
	return cachedPath;
}

+ (NSString *)documentsPath
{
	static dispatch_once_t onceToken;
	static NSString *cachedPath;
	
	dispatch_once(&onceToken, ^{
		cachedPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];	
	});
	
	return cachedPath;
}



#pragma mark - File Actions

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



#pragma mark - Utils

+ (NSString *)stringByFormattingBytes:(long long)bytes
{
	NSArray *units = [NSArray arrayWithObjects:@"%1.0f Bytes", @"%1.1f KB", @"%1.1f MB", @"%1.1f GB", @"%1.1f TB", nil];
	
	long long value = bytes * 10;
	for (int i=0; i<[units count]; i++)
	{
		if (i > 0)
		{
			value = value/1024;
		}
		if (value < 10000)
		{
			return [NSString stringWithFormat:[units objectAtIndex:i], value/10.0];
		}
	}
	
	return [NSString stringWithFormat:[units objectAtIndex:[units count]-1], value/10.0];
}


@end
