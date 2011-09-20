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
	self.title = @"Browser";
	rootPath = path;
	XDirectory *directory = [[XService sharedXService] directoryWithPath:rootPath];
	[(DirectoryContentsViewController *)self.topViewController setDirectory:directory];
}

/*- (id)initWithRootPath:(NSString *)path
{
	XDirectory *directory = [[XService sharedXService] directoryWithPath:path];
    return [self initWithDirectory:directory];
}

- (id)initWithDirectory:(XDirectory *)directory
{
	DirectoryContentsViewController *rootViewController = [[DirectoryContentsViewController alloc] initWithDirectory:directory];
	self = [super initWithRootViewController:rootViewController];
    if (self) {
		self.title = @"Browser";
    }
    
    return self;
}*/

- (void)setTitle:(NSString *)title
{
	[super setTitle:title];
	[self.topViewController setTitle:title];
}

@end
