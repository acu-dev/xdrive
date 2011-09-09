//
//  AccountViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "AccountViewController.h"
#import "XService.h"



@interface AccountViewController()

@property (nonatomic, strong) CGConnection *activeConnection;
@property (nonatomic, strong) XServer *server;
@property (nonatomic, assign) BOOL isAuthenticating;
@property (nonatomic, strong) ATMHud *hud;

- (void)updateHudWithDelay;
@end



@implementation AccountViewController

// Private ivars
@synthesize activeConnection;
@synthesize server;
@synthesize isAuthenticating;
@synthesize hud;

// Public ivars
@synthesize serverURLField, usernameField, passwordField;
@synthesize signInLabel;
@synthesize signInCell;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	server = [[XService sharedXService] activeServer];
	if (server)
	{
		serverURLField.text = [NSString stringWithFormat:@"%@://%@:%i", server.protocol, server.hostname, server.port];
		
		// TODO fill in the user/pass
		
		[self enableSignIn];
	}
	else
	{
		[self disableSignIn];
	}
	
	hud = [[ATMHud alloc] initWithDelegate:self];
	[self.view addSubview:hud.view];
	
	// Set self as challenge response delegate
	[CGNet utils].challengeResponseDelegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	self.activeConnection = nil;
	self.server = nil;
	self.hud = nil;
	
	self.serverURLField = nil;
	self.usernameField = nil;
	self.passwordField = nil;
	self.signInLabel = nil;
	self.signInCell = nil;
	
	// Unset self as challenge response delgate
	[CGNet utils].challengeResponseDelegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



#pragma mark - Login

- (void)validateAccount
{
	[self disableSignIn];
	
	// Hide keyboard
	[serverURLField resignFirstResponder];
	[usernameField resignFirstResponder];
	[passwordField resignFirstResponder];
	
	// Show activity indicator
	[hud setCaption:@"Connecting to server..."];
	[hud setActivity:YES];
	[hud show];
	
	// TODO make this look at a /version service to validate compatibility
	
	// Build service validation URL
	int port = 443;
	NSString *protocol = @"https";
	NSString *serviceBase = @"/xservice";
	NSString *infoService = @"/info";
	NSString *infoServiceUrlString = [NSString stringWithFormat:@"%@://%@:%i%@%@",
									  protocol,
									  serverURLField.text,
									  port,
									  serviceBase,
									  infoService];
	
	// Attempt to get JSON at server URL
	activeConnection = [[CGNet utils] getJSONAtURL:[NSURL URLWithString:infoServiceUrlString] withDelegate:self];
	[activeConnection start];
}

- (void)dismissAccountInfo
{
	[self performSegueWithIdentifier:@"dismissAccountInfo" sender:self];
}

- (void)updateHudWithDelay
{
	NSTimeInterval updateDisplayTime = 2.0;
	[hud update];
	[hud hideAfter:updateDisplayTime];
}



#pragma mark - Validation

- (BOOL)isFormValid
{
	if (!serverURLField.text || !usernameField.text || !passwordField.text)
		return NO;
	
	if ([serverURLField.text isEqualToString:@""] || [usernameField.text isEqualToString:@""] || [passwordField.text isEqualToString:@""])
		return NO;
	
	return YES;
}

- (void)enableSignIn
{
	isAuthenticating = NO;
	signInLabel.textColor = [UIColor blackColor];
	signInCell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (void)disableSignIn
{
	isAuthenticating = YES;
	signInLabel.textColor = [UIColor grayColor];
	signInCell.selectionStyle = UITableViewCellSelectionStyleNone;
}



#pragma mark - Text field delegate

- (IBAction)textFieldValueChanged:(id)sender
{
	if ([self isFormValid])
		[self enableSignIn];
	else
		[self disableSignIn];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == serverURLField)
	{
		[usernameField becomeFirstResponder];
	}
	else if (textField == usernameField)
	{
		[passwordField becomeFirstResponder];
	}
	else
	{
		if ([self isFormValid] && !isAuthenticating)
			[self validateAccount];
	}
	
	return NO;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!indexPath.section)
		return;
	
	if (![self isFormValid])
		return;
	
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self validateAccount];
}



#pragma mark - CGConnectionDelegate

- (void)cgConnection:(CGConnection *)connection finishedWithResult:(id)result
{
	NSLog(@"result: %@", result);
	
	// Success!
	[hud setActivity:NO];
	[hud setImage:[UIImage imageNamed:@"check"]];
	[hud setCaption:@"Success!"];
	[self updateHudWithDelay];
	
	// Hide view after hud hides
	//[self performSelector:@selector(dismissAccountInfo) withObject:nil afterDelay:2.0];
}

- (void)cgConnection:(CGConnection *)connection failedWithError:(NSError *)error
{
	if ([error code] != NSURLErrorUserCancelledAuthentication)
	{
		// Display error message
		[hud setActivity:NO];
		[hud setImage:[UIImage imageNamed:@"x"]];
		[hud setCaption:[error localizedDescription]];
		[self updateHudWithDelay];
	}
	
	[self enableSignIn];
	
	self.activeConnection = nil;
}



#pragma mark - CGChallengeResponseDelegate

- (void)respondToAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
							  forHandler:(CGChallengeHandler *)challengeHandler
{
	if (!challenge.previousFailureCount)
	{
		[hud setCaption:@"Authenticating..."];
		[hud update];
		
		// Create credential from login form
		NSURLCredential *credential = [NSURLCredential credentialWithUser:usernameField.text 
																 password:passwordField.text 
															  persistence:NSURLCredentialPersistencePermanent];
		[challengeHandler stopWithCredential:credential];
	}
	else
	{
		// Display error message
		[hud setActivity:NO];
		[hud setCaption:@"Authentication failed"];
		[hud setImage:[UIImage imageNamed:@"x"]];
		[self updateHudWithDelay];
		
		[challengeHandler stopWithCredential:nil];
	}
}

@end


























