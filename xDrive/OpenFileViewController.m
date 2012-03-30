//
//  OpenFileViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 9/18/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "OpenFileViewController.h"
#import "XDriveConfig.h"
#import "XService.h"




@interface OpenFileViewController()
@property XServiceRemote *_remoteService;
- (void)downloadFile;
- (void)loadFile;
@end



@implementation OpenFileViewController

@synthesize _remoteService;
@synthesize file;
@synthesize webView;
@synthesize downloadView;
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
	return ([supportedFileExtensions containsObject:[file extension]]);
}



#pragma mark - Initialization


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = [file.name stringByDeletingPathExtension];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[file cachePath]])
	{
		// File has been cached locally
		
		if ([file.lastAccessed compare:file.lastUpdated] == NSOrderedDescending)
		{
			// Last access is later in time than last updated (cached file is still fresh)
			XDrvDebug(@"%@ :: Loading cached file", file.path);
			
			// Display file
			downloadView.hidden = YES;
			[self loadFile];
			
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

- (void)viewDidUnload
{
    [super viewDidUnload];
	self.webView = nil;
	self.downloadProgressView = nil;
	self.downloadFileNameLabel = nil;
	self.downloadView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



# pragma mark - Download File

- (void)downloadFile
{	
	// Setup service
	_remoteService = [[XServiceRemote alloc] initWithServer:[[XService sharedXService].localService server]];
	[_remoteService setFailureBlock:^(NSError *error) {
		XDrvLog(@"%@ :: Download failed: %@", file.path, error);
		NSString *title = NSLocalizedStringFromTable(@"Unable to download file", 
													 @"XDrive", 
													 @"Title of alert displayed when a file download fails.");
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	}];
	
	// Download file
	[_remoteService downloadFileAtPath:file.path ifModifiedSinceCachedDate:nil
					   withUpdateBlock:^(float percentDownloaded) {
						   [downloadProgressView setProgress:percentDownloaded animated:YES];
					   } 
					   completionBlock:^(id result) {
						   [self downloadFinishedAtTemporaryPath:(NSString *)result];
					   }];
}

- (void)downloadFinishedAtTemporaryPath:(NSString *)tmpPath
{
	[[XService sharedXService] cacheFile:file fromTmpPath:tmpPath];
	
	// Load file
	[self loadFile];
	
	// Reveal webview
	[UIView animateWithDuration:0.3
					 animations:^(void){
						 [webView setAlpha:1.0];
					 }
					 completion:^(BOOL finished){
						 downloadView.hidden = YES;
					 }];
}



- (void)loadFile
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[file cachePath]]];
    [webView loadRequest:request];
	
	// Update file's last access time
	file.lastAccessed = [NSDate date];
	[[XService sharedXService].localService saveWithCompletionBlock:^(NSError *error) {}];
}

@end















