//
//  SetupViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 10/7/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SetupViewController.h"
#import "XDriveConfig.h"
#import "XService.h"
#import "ATMHud.h"



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

@property (nonatomic, strong) ATMHud *hud;
	// Heads up display for account validation messages

- (int)calculateYPositionForCenteringViewInOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (int)defaultFormYPositionForOrientation:(UIInterfaceOrientation)orientation;
- (int)visibleHeightForOrientation:(UIInterfaceOrientation)orientation;
- (int)keyboardHeightForOrientation:(UIInterfaceOrientation)orientation;
	// Calculates the correct Y position for the login form based on the device orientation
	// and whether or not the keyboard is showing.

- (BOOL)isFormValid;
	// Evaluates the user, pass, and server text fields for valid data

- (void)doLogin;
	// Asks XService to validate the account credentials.

- (void)dismissSetup;
	// Executes the transition to the app's root view. Called after setup is complete.

@end




@implementation SetupViewController

@synthesize isKeyboardVisible, isRotating;
@synthesize hud;

@synthesize bgImageView;
@synthesize centeringView;
@synthesize serverField, usernameField, passwordField;
@synthesize loginButton;
@synthesize activityIndicator;
@synthesize setupController;




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
	[loginButton setBackgroundImage:[[UIImage imageNamed:@"button-down-bg.png"] stretchableImageWithLeftCapWidth:8 topCapHeight:0] forState:UIControlStateHighlighted];
	
	// Register to get notified when keyboard appears/disappears
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	// Create hud to display messages
	hud = [[ATMHud alloc] initWithDelegate:self];
	[self.view addSubview:hud.view];
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
	self.activityIndicator = nil;
	self.hud = nil;
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

- (IBAction)login:(id)sender
{
	[self dismissKeyboard:nil];
	
	if ([self isFormValid])
	{
		
		[self doLogin];
	}
	else
	{
		[hud setCaption:@"OOPS! You have supplied an invalid login. Please try again."];
		[hud show];
		[hud hideAfter:2];
	}
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

- (void)keyboardWillShow:(NSNotification *)note
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

- (void)keyboardWillHide:(NSNotification *)note
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

- (void)updateHudPosition
{
	
}



#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == serverField)
	{
		[usernameField becomeFirstResponder];
	}
	else if (textField == usernameField)
	{
		[passwordField becomeFirstResponder];
	}
	else if ([self isFormValid])
	{
		[self doLogin];
	}
	
	return NO;
}



#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UIButton class]])
	{
        return NO;
    }
    return YES;
}



#pragma mark - Login

- (void)doLogin
{
	loginButton.enabled = NO;
	[self dismissKeyboard:self];
	
	// Show activity
	[self setupStatusUpdate:@"Connecting to server..."];
	[activityIndicator startAnimating];
	activityIndicator.hidden = NO;
	
	if (!setupController)
	{
		XDrvLog(@"Can't do setup, setupController is not set");
		return;
	}
	
	[setupController setupWithUsername:usernameField.text password:passwordField.text forHost:serverField.text];
}

- (BOOL)isFormValid
{
	if (!serverField.text || !usernameField.text || !passwordField.text)
		return NO;
	
	if ([serverField.text isEqualToString:@""] || [usernameField.text isEqualToString:@""] || [passwordField.text isEqualToString:@""])
		return NO;
	
	return YES;
}

- (void)dismissSetup
{
	[self performSegueWithIdentifier:@"DismissSetupView" sender:self];
}



#pragma mark - Setup Responses

- (void)setupStatusUpdate:(NSString *)status
{
	if (!status)
		status = @"Login";
	
	[loginButton setTitle:status forState:UIControlStateNormal];
}

- (void)setupFailedWithError:(NSError *)error
{
	NSString *reason = nil;
	
	if (error)
	{
		XDrvLog(@"Setup failed: %@", [error description]);
		
		if ([error code] == NSURLErrorUserCancelledAuthentication)
		{
			// Authentication failed
			reason = NSLocalizedStringFromTable(@"Authentication failed; verify username/password",
												@"AccountViewController", 
												@"Message displayed when authentication fails during server validation.");
		}
		else if ([error code] == ServerIsIncompatible)
		{
			reason = [error localizedDescription];
		}
		else
		{
			// Something else went wrong
			reason = NSLocalizedStringFromTable(@"Unable to connect to server",
												@"AccountViewController", 
												@"Message displayed when server validation failed.");
		}
	}
	else
	{
		// Version incompatible
		XDrvLog(@"Validate account failed: Server version is incompatible");
		NSString *msg = NSLocalizedStringFromTable(@"Server version is incompatible with this version of %@. Please check for updates.", 
												   @"AccountViewController", 
												   @"Message displayed when server version is incompatible.");
		reason = [NSString stringWithFormat:msg, [XDriveConfig appName]];
	}
		
	[self setupStatusUpdate:nil];
	[activityIndicator stopAnimating];
	activityIndicator.hidden = YES;
	loginButton.enabled = YES;
	
	[hud setCaption:reason];
	[hud show];
	[hud hideAfter:2];
}

- (void)setupFinished
{
	// Success!
	[self setupStatusUpdate:@"Success!"];
	[activityIndicator stopAnimating];
	activityIndicator.hidden = YES;
	
	// Hide view after hud hides
	[self performSelector:@selector(dismissSetup) withObject:nil afterDelay:1.5];
}


@end









