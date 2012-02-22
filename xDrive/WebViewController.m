//
//  WebViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 2/22/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "WebViewController.h"
#import "XDriveConfig.h"

@interface WebViewController ()

@property (nonatomic, strong) NSURL *contentURL;

@end

@implementation WebViewController

// Private
@synthesize contentURL;

// Public
@synthesize webView;



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	[webView loadRequest:[NSURLRequest requestWithURL:contentURL]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}



#pragma mark - Load content

- (void)loadContentAtURL:(NSURL *)url withTitle:(NSString *)title
{
	self.title = title;
	contentURL = url;
}



#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
	{
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
	
    return YES;
}

@end
