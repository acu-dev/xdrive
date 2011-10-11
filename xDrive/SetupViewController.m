//
//  SetupViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 10/7/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "SetupViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation SetupViewController


@synthesize bgImageView;
@synthesize serverField, usernameField, passwordField;
@synthesize loginButton;




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
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	
	bgImageView.layer.cornerRadius = 5;
	bgImageView.layer.masksToBounds = YES;
	[loginButton setBackgroundImage:[[UIImage imageNamed:@"button-bg.png"] stretchableImageWithLeftCapWidth:8 topCapHeight:0] forState:UIControlStateNormal];
	[loginButton setBackgroundImage:[[UIImage imageNamed:@"button-bg.png"] stretchableImageWithLeftCapWidth:8 topCapHeight:0] forState:UIControlStateHighlighted];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	self.serverField = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



#pragma mark - User Actions

- (IBAction)dismissKeyboard:(id)sender
{
	[serverField resignFirstResponder];
	[usernameField resignFirstResponder];
	[passwordField resignFirstResponder];
}

@end
