//
//  XFile.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "XFile.h"
#import "XService.h"


@implementation XFile

@dynamic size;
@dynamic type;

- (NSString *)extension
{
	return [[self.name componentsSeparatedByString:@"."] lastObject];
}

- (NSString *)localPath
{
	return [[[XService sharedXService] activeServerDocumentPath] stringByAppendingString:self.path];
}

@end
