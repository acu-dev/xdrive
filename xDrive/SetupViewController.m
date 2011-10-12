//
//  SetupViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 10/7/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "SetupViewController.h"
#import <QuartzCore/QuartzCore.h>



static int VisibleHeightIphonePortrait = 460;
static int VisibleHeightIphoneLandscape = 300;
static int VisibleHeightIpadPortrait = 1004;
static int VisibleHeightIpadLandscape = 748;
static int KeyboardHeightIphonePortrait = 216;
static int KeyboardHeightIphoneLandscape = 162;
static int KeyboardHeightIpadPortrait = 263;
static int KeyboardHeightIpadLandscape = 351;


static int FormDefaultYPosIphonePortrait = 66;
static int FormDefaultYPosIphoneLandscape = 33;
static int FormDefaultYPosIpadPortrait = 270;
static int FormDefaultYPosIpadLandscape = 166;


@interface SetupViewController()

@property (nonatomic, assign) BOOL isKeyboardVisible, isRotating;

- (int)calculateYPositionForCenteringViewInOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (int)defaultFormYPositionForOrientation:(UIInterfaceOrientation)orientation;
- (int)visibleHeightForOrientation:(UIInterfaceOrientation)orientation;
- (int)keyboardHeightForOrientation:(UIInterfaceOrientation)orientation;

@end




@implementation SetupViewController

@synthesize isKeyboardVisible, isRotating;

@synthesize bgImageView;
@synthesize centeringView;
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
	
	// Style BG
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	bgImageView.layer.cornerRadius = 5;
	bgImageView.layer.masksToBounds = YES;
	
	// Button images
	[loginButton setBackgroundImage:[[UIImage imageNamed:@"button-bg.png"] stretchableImageWithLeftCapWidth:8 topCapHeight:0] forState:UIControlStateNormal];
	[loginButton setBackgroundImage:[[UIImage imageNamed:@"button-bg.png"] stretchableImageWithLeftCapWidth:8 topCapHeight:0] forState:UIControlStateHighlighted];
	
	// Register to get notified when keyboard appears/disappears
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.bgImageView = nil;
	self.centeringView = nil;
	self.serverField = nil;
	self.usernameField = nil;
	self.passwordField = nil;
	self.loginButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	// Set view to position for new interface
	CGRect newFrame = centeringView.frame;
	newFrame.origin.y = [self calculateYPositionForCenteringViewInOrientation:toInterfaceOrientation];
	centeringView.frame = newFrame;
	
	isRotating = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	isRotating = NO;
}





#pragma mark - User Actions

- (IBAction)dismissKeyboard:(id)sender
{
	[serverField resignFirstResponder];
	[usernameField resignFirstResponder];
	[passwordField resignFirstResponder];
}



#pragma mark - Center Form

- (int)calculateYPositionForCenteringViewInOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	int newY = [self defaultFormYPositionForOrientation:interfaceOrientation];
	if (isKeyboardVisible)
	{
		int visibleHeight = [self visibleHeightForOrientation:interfaceOrientation] - [self keyboardHeightForOrientation:interfaceOrientation];
		newY = visibleHeight - centeringView.frame.size.height;
		if (newY > 1)
			newY = newY / 2;
	}
	return newY;
}

- (int)defaultFormYPositionForOrientation:(UIInterfaceOrientation)orientation
{
	int yPos = 0;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		yPos = (orientation == UIInterfaceOrientationPortrait || 
				orientation == UIInterfaceOrientationPortraitUpsideDown) ? FormDefaultYPosIphonePortrait : FormDefaultYPosIphoneLandscape;
	}
	else
	{
		yPos = (orientation == UIInterfaceOrientationPortrait || 
				orientation == UIInterfaceOrientationPortraitUpsideDown) ? FormDefaultYPosIpadPortrait : FormDefaultYPosIpadLandscape;
	}
	return yPos;
}

- (int)keyboardHeightForOrientation:(UIInterfaceOrientation)orientation
{
	int height = 0;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		height = (orientation == UIInterfaceOrientationPortrait || 
				  orientation == UIInterfaceOrientationPortraitUpsideDown) ? KeyboardHeightIphonePortrait : KeyboardHeightIphoneLandscape;
	}
	else
	{
		height = (orientation == UIInterfaceOrientationPortrait || 
				  orientation == UIInterfaceOrientationPortraitUpsideDown) ? KeyboardHeightIpadPortrait : KeyboardHeightIpadLandscape;
	}
	return height;
}

- (int)visibleHeightForOrientation:(UIInterfaceOrientation)orientation
{
	int height = 0;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		height = (orientation == UIInterfaceOrientationPortrait || 
				  orientation == UIInterfaceOrientationPortraitUpsideDown) ? VisibleHeightIphonePortrait : VisibleHeightIphoneLandscape;
	}
	else
	{
		height = (orientation == UIInterfaceOrientationPortrait || 
				  orientation == UIInterfaceOrientationPortraitUpsideDown) ? VisibleHeightIpadPortrait : VisibleHeightIpadLandscape;
	}
	return height;
}



-(void) keyboardWillShow:(NSNotification *)note
{
	if (isRotating) return;
	isKeyboardVisible = YES;
	
	// Move the centering view
	CGRect newFrame = centeringView.frame;
	newFrame.origin.y = [self calculateYPositionForCenteringViewInOrientation:self.interfaceOrientation];
	[UIView animateWithDuration:0.3 animations:^(void){
		centeringView.frame = newFrame;
	}];
}

-(void) keyboardWillHide:(NSNotification *)note
{
	if (isRotating) return;
	isKeyboardVisible = NO;
	
	// Move the centering view
	CGRect newFrame = centeringView.frame;
	newFrame.origin.y = [self calculateYPositionForCenteringViewInOrientation:self.interfaceOrientation];
	[UIView animateWithDuration:0.3 animations:^(void){
		centeringView.frame = newFrame;
	}];
}



#pragma mark - UITextFieldDelegate




@end









