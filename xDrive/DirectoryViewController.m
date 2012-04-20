//
//  DirectoryViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 3/29/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "DirectoryViewController.h"
#import "DirectoryContentsViewController.h"
#import "FileViewController.h"
#import "UIStoryboard+Xdrive.h"
#import "XDriveConfig.h"

@interface DirectoryViewController ()
@property (nonatomic, strong) DirectoryContentsViewController *_contentsViewController;
@property (nonatomic, strong) FileViewController *_fileViewController;
@end

@implementation DirectoryViewController

@synthesize _contentsViewController;
@synthesize _fileViewController;

@synthesize directory;
@synthesize messageView;
@synthesize messageLabel;
@synthesize activityIndicator;



#pragma mark - Directory

- (void)setDirectory:(XDirectory *)dir
{
	directory = dir;
	_contentsViewController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"directoryContentsView"];
	_contentsViewController.directoryViewController = self;
	_contentsViewController.directory = directory;
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!self.title) self.title = directory.name;
	
	[self.view addSubview:_contentsViewController.view];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		_fileViewController = (FileViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[_contentsViewController viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[_contentsViewController viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



#pragma mark - Messages

- (UIView *)initialUpdateMessageView
{
	messageView.hidden = NO;
	messageLabel.text = NSLocalizedStringFromTable(@"Fetching directory contents...",
												   @"XDrive",
												   @"Message displayed when the directory contents are being fetched for the first time.");
	activityIndicator.hidden = NO;
	[activityIndicator startAnimating];
	
	return messageView;
}

- (UIView *)noContentsMessageView
{
	messageView.hidden = NO;
	messageLabel.text = NSLocalizedStringFromTable(@"Folder is Empty",
												   @"XDrive",
												   @"Message displayed when folder has no contents.");
	[activityIndicator stopAnimating];
	activityIndicator.hidden = YES;
	
	return messageView;
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
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		FileViewController *viewController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"fileView"];
		viewController.title = [file.name stringByDeletingPathExtension];
		[self.navigationController pushViewController:viewController animated:YES];
		[viewController showFile:file];
	}
	else
	{
		[_fileViewController showFile:file];
	}
}

@end


















