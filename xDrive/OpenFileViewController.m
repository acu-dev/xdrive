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



@interface OpenFileViewController() <XServiceRemoteDelegate>

- (void)downloadFile;
- (void)loadFile;

@end



@implementation OpenFileViewController


@synthesize xFile;
@synthesize webView;



+ (BOOL)isFileViewable:(XFile *)file
{
	NSArray *supportedFileExtensions = [NSArray arrayWithObjects:@"pdf",
										@"pages", @"numbers", @"key",
										@"doc",	@"xls", @"ppt",
										@"txt",	@"rtf",	@"html",
										@"jpg",	@"jpeg", @"png",
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
	
	self.title = xFile.name;
	
	XDrvDebug(@"File path: %@", [xFile localPath]);
	if ([[NSFileManager defaultManager] fileExistsAtPath:[xFile localPath]])
	{
		// Display file
		[self loadFile];
	}
	else
	{
		// Download file
		XDrvDebug(@"File doesn't exist, need to download it");
		[self downloadFile];
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void)done:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}


# pragma mark - Download File

- (void)downloadFile
{
	// Update view
	
	// Kick off download
	[[XService sharedXService] downloadFile:xFile withDelegate:self];
}

- (void)loadFile
{
	XDrvDebug(@"Loading %@ content at %@ into web view", xFile.type, xFile.path);
	[webView loadData:[NSData dataWithContentsOfFile:[xFile localPath]]
			 MIMEType:xFile.type
	 textEncodingName:@"utf-8" 
			  baseURL:[NSURL URLWithString:[xFile localPath]]];
}



#pragma mark - XServiceRemoteDelegate

- (void)connectionFinishedWithResult:(NSObject *)result
{
	XDrvLog(@"download finished with result: %@", result);
	[XService moveFileAtPath:(NSString *)result toPath:[xFile localPath]];
	[self loadFile];
}

- (void)connectionFailedWithError:(NSError *)error
{
	XDrvLog(@"Download failed: %@", [error description]);
}

- (void)connectionDownloadPercentUpdate:(int)percent
{
	XDrvLog(@"download percent: %i", percent);
}

@end





