//
//  FileViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 4/3/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "FileViewController.h"
#import "XDriveConfig.h"
#import "XService.h"


@interface FileViewController ()
@property (nonatomic, strong) XFile *_file;
@property (nonatomic, strong) XServiceRemote *_remoteService;
@property (nonatomic, strong) UIPopoverController *_dirPopoverController;
- (void)downloadFile;
- (void)displayFile;
@end

@implementation FileViewController

@synthesize _file;
@synthesize _remoteService;
@synthesize _dirPopoverController;
@synthesize webView;
@synthesize downloadView, noFileSelectedView;
@synthesize downloadFileNameLabel;
@synthesize downloadProgressView;


+ (BOOL)isFileViewable:(XFile *)file
{
	NSArray *supportedFileExtensions = [NSArray arrayWithObjects:@"pdf",
										@"pages", @"numbers", @"key",
										@"doc",	@"xls", @"ppt",
										@"txt",	@"rtf",	@"html",
										@"jpg",	@"jpeg", @"png",
										@"m4v", @"mov", @"mp4",
										@"mp3", @"wav", @"m4a",
										nil];
	return ([supportedFileExtensions containsObject:[[file extension] lowercaseString]]);
}

- (void)hidePopover
{
	if (_dirPopoverController)
	{
		[_dirPopoverController dismissPopoverAnimated:YES];
	}
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		noFileSelectedView.hidden = NO;
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
	self.downloadProgressView = nil;
	self.downloadFileNameLabel = nil;
	self.downloadView = nil;
	self.noFileSelectedView = nil;
	self.webView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



#pragma mark - Load file

- (void)loadFile:(XFile *)file
{
	_file = file;
	self.title = [file.name stringByDeletingPathExtension];
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		// iPad specifics
		
		if (noFileSelectedView.hidden == NO)
		{
			// Hide no file selected view
			[UIView animateWithDuration:0.2 animations:^{
				[noFileSelectedView setAlpha:0];
			} completion:^(BOOL finished) {
				noFileSelectedView.hidden = YES;
			}];
		}
		
		if (_dirPopoverController != nil)
		{
			// Hide popover
			[_dirPopoverController dismissPopoverAnimated:YES];
		}
	}
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[file cachePath]])
	{
		// File has been cached locally
		
		if ([file.lastAccessed compare:file.lastUpdated] == NSOrderedDescending)
		{
			// Last access is later in time than last updated (cached file is still fresh)
			XDrvDebug(@"%@ :: Loading cached file", file.path);
			
			// Display file
			downloadView.hidden = YES;
			[self displayFile];
			
			return;
		}
		else
		{
			// Last access is earlier in time than last updated (cached file is stale)
			// Proceed to download file...
			XDrvDebug(@"Cached file is stale, need to download it");
		}
	}
	else
	{
		// File not found locally. Proceed to download file...
		XDrvDebug(@"File doesn't exist, need to download it");
	}
	
	// Hide webview and show download indicator
	[webView setAlpha:0];
	downloadFileNameLabel.text = file.name;
	
	// Download file
	[self downloadFile];
}



# pragma mark - Download File

- (void)downloadFile
{
	downloadView.hidden = NO;
	
	// Setup service
	_remoteService = [[XServiceRemote alloc] initWithServer:[[XService sharedXService].localService server]];
	[_remoteService setFailureBlock:^(NSError *error) {
		XDrvLog(@"%@ :: Download failed: %@", _file.path, error);
		NSString *title = NSLocalizedStringFromTable(@"Unable to download file", 
													 @"XDrive", 
													 @"Title of alert displayed when a file download fails.");
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	}];
	
	// Download file
	[_remoteService downloadFileAtPath:_file.path ifModifiedSinceCachedDate:nil
					   withUpdateBlock:^(float percentDownloaded) {
						   [downloadProgressView setProgress:percentDownloaded animated:YES];
					   } 
					   completionBlock:^(id result) {
						   [self downloadFinishedAtTemporaryPath:(NSString *)result];
					   }];
}

- (void)downloadFinishedAtTemporaryPath:(NSString *)tmpPath
{
	[[XService sharedXService] cacheFile:_file fromTmpPath:tmpPath];
	
	// Load file
	[self displayFile];
	
	// Reveal webview
	[UIView animateWithDuration:0.3
					 animations:^(void){
						 [webView setAlpha:1.0];
					 }
					 completion:^(BOOL finished){
						 downloadView.hidden = YES;
					 }];
}

- (void)displayFile
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[_file cachePath]]];
    [webView loadRequest:request];
	
	// Update file's last access time
	_file.lastAccessed = [NSDate date];
	[[XService sharedXService].localService saveWithCompletionBlock:^(NSError *error) {}];
}



#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController 
		  withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
	barButtonItem.title = @"xDrive";
	[self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
	_dirPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)button
{
	[self.navigationItem setLeftBarButtonItem:nil animated:YES];
	_dirPopoverController = nil;
}

@end



















