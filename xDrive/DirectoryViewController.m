//
//  DirectoryViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 3/29/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "DirectoryViewController.h"
#import "DirectoryContentsViewController.h"
#import "OpenFileViewController.h"
#import "UIStoryboard+Xdrive.h"
#import "XDriveConfig.h"

@interface DirectoryViewController ()
@property (nonatomic, strong) DirectoryContentsViewController *_contentsViewController;
@property (nonatomic, assign) BOOL _contentsViewIsLoaded;
- (void)showInitialUpdateView;
- (void)showDirectoryContentsAnimated:(BOOL)animated;
@end

@implementation DirectoryViewController

@synthesize directory;
@synthesize initialUpdateView;
@synthesize _contentsViewController;
@synthesize _contentsViewIsLoaded;


- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!self.title) self.title = directory.name;
	
	if (_contentsViewController.contentStatus == DirectoryContentUpdating)
	{
		[self showInitialUpdateView];
	}
	else
	{
		[self showDirectoryContentsAnimated:NO];
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	self._contentsViewController = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (_contentsViewIsLoaded)
	{
		[_contentsViewController viewWillAppear:animated];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (_contentsViewIsLoaded)
	{
		[_contentsViewController viewDidAppear:animated];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



#pragma mark - Directory

- (void)setDirectory:(XDirectory *)dir
{
	directory = dir;
	_contentsViewController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"directoryContentsView"];
	_contentsViewController.directoryViewController = self;
	_contentsViewController.directory = directory;
}



#pragma mark - Initial Update

- (void)showInitialUpdateView
{
	
}



#pragma mark - Directory Contents

- (void)showDirectoryContentsAnimated:(BOOL)animated
{
	[_contentsViewController viewWillAppear:animated];
	if (!animated)
	{
		[self.view addSubview:_contentsViewController.view];
	}
	else
	{
		
	}
	[_contentsViewController viewDidAppear:animated];
	_contentsViewIsLoaded = YES;
}



#pragma mark - Navigation

- (void)navigateToDirectory:(XDirectory *)dir
{
	DirectoryViewController *viewController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"directoryView"];
	viewController.directory = dir;
	[self.navigationController pushViewController:viewController animated:YES];
}

- (void)navigateToFile:(XFile *)file
{
	XDrvLog(@"Navigating to file is not implemented yet");
	/*OpenFileViewController *viewController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"fileView"];
	viewController.file = file;
	[self.navigationController pushViewController:viewController animated:YES];*/
}

@end


















