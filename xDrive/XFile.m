//
//  XFile.m
//  xDrive
//
//  Created by Chris Gibbs on 2/15/12.
//  Copyright (c) 2012 Meld Apps. All rights reserved.
//

#import "XFile.h"
#import "XService.h"


@implementation XFile

@dynamic lastAccessed;
@dynamic size;
@dynamic type;
@dynamic sizeDescription;

- (NSString *)extension
{
	return [[self.name componentsSeparatedByString:@"."] lastObject];
}

- (NSString *)cachePath
{
	return [[[XService sharedXService] activeServerCachePath] stringByAppendingString:self.path];
}

- (NSString *)documentPath
{
	return [[[XService sharedXService] activeServerDocumentPath] stringByAppendingString:self.path];
}

@end
