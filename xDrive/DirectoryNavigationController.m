//
//  DirectoryNavigationController.m
//  xDrive
//
//  Created by Christopher Gibbs on 7/7/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "DirectoryNavigationController.h"
#import "DirectoryContentsViewController.h"
#import "XService.h"

@implementation DirectoryNavigationController

@synthesize rootPath;

- (void)setRootPath:(NSString *)path
{
	self.title = @"Browse";
	rootPath = path;
	XDirectory *directory = [[XService sharedXService] directoryWithPath:rootPath];
	[(DirectoryContentsViewController *)self.topViewController setDirectory:directory];
}

- (void)setTitle:(NSString *)title
{
	[super setTitle:title];
	[self.topViewController setTitle:title];
}

@end
