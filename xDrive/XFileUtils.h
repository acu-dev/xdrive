//
//  XFileUtils.h
//  xDrive
//
//  Created by Chris Gibbs on 10/14/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

@interface XFileUtils : NSObject

+ (NSString *)cachesPath;
	// Path to the Library/Caches directory in the app's sandbox

+ (NSString *)documentsPath;
	// Path to the Documents directory in the app's sandbox

+ (void)moveFileAtPath:(NSString *)oldFilePath toPath:(NSString *)newFilePath;
	// Moves a file from one location to another

+ (NSString *)stringByFormattingBytes:(long long)bytes;
	// Generates a human readable file size string (e.g. '5.7 MB')

@end
