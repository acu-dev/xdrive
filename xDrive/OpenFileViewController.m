//
//  OpenFileViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 9/18/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "OpenFileViewController.h"



@interface OpenFileViewController()


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

/*- (id)initWithFile:(XFile *)file
{
    self = [super init];
    if (self) {
		xFile = file;
    }
    return self;
}*/

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*- (void)loadView
{
	UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	
	// Nav bar
	UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, 44)];
	navBar.topItem.title = xFile.name;
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	navBar.topItem.rightBarButtonItem = doneButton;
	[view addSubview:navBar];
	
	// Web view
	UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 44, view.frame.size.width, view.frame.size.height - 44)];
	//[view addSubview:webView];
	
	self.view = view;
}*/

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = xFile.name;
	
	NSLog(@"Loading %@ content at %@ into web view", xFile.type, xFile.path);
	/*[webView loadData:[NSData dataWithContentsOfFile:xFile.path]
			 MIMEType:xFile.type textEncodingName:@"utf-8" 
			  baseURL:[NSURL URLWithString:xFile.path]];*/
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

@end
