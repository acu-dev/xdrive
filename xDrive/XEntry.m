//
//  XEntry.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "XEntry.h"
#import "XDirectory.h"
#import "XServer.h"
#import "XService.h"


@implementation XEntry

@dynamic created;
@dynamic creator;
@dynamic lastUpdated;
@dynamic lastUpdator;
@dynamic name;
@dynamic path;
@dynamic parent;
@dynamic server;

- (NSString *)cachePath
{
	return [[[XService sharedXService] cachesPath] stringByAppendingString:self.path];
}

- (NSString *)documentPath
{
	return [[[XService sharedXService] documentsPath] stringByAppendingString:self.path];
}

@end
