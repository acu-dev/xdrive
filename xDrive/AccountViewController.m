//
//  AccountViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "AccountViewController.h"
#import "XDriveConfig.h"
#import "XService.h"
#import "ATMHud.h"

//#import <CGNetUtils/CGNetUtils.h>




@interface AccountViewController() <ServerStatusDelegate>

@property (nonatomic, strong) ATMHud *hud;
	// Heads up display for account validation messages



- (void)validateAccount;
	// Kicks off a connection to the server with the given info

- (BOOL)isFormValid;
	// Evaluates the user, pass, and server text fields for valid data

- (void)enableSignIn;
- (void)disableSignIn;
	// Enables/disables the sign in cell

- (void)updateHudWithDelay;
	// Tells the hud to update and dismiss after a given number of seconds

@end



@implementation AccountViewController

// Private ivars
@synthesize hud;

// Public ivars
@synthesize saveButton;
@synthesize serverURLField, usernameField, passwordField;




#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	XServer *server = [[XService sharedXService] activeServer];
	if (server)
	{
		serverURLField.text = server.hostname;
		
		// TODO fill in the user/pass
		
		[self enableSignIn];
	}
	else
	{
		[self disableSignIn];
	}
	
	hud = [[ATMHud alloc] initWithDelegate:self];
	[self.view addSubview:hud.view];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	self.hud = nil;
	
	self.serverURLField = nil;
	self.usernameField = nil;
	self.passwordField = nil;
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
	
	// Ask XService to validate account
	[[XService sharedXService] validateUsername:usernameField.text 
									   password:passwordField.text 
										forHost:serverURLField.text 
								   withDelegate:self];
}



#pragma mark - Utils

- (void)dismissAccountInfo
{
	[self performSegueWithIdentifier:@"dismissAccountInfo" sender:self];
}

- (void)updateHudWithDelay
{
	NSTimeInterval updateDisplayTime = 1.5;
	[hud update];
	[hud hideAfter:updateDisplayTime];
}



#pragma mark - Form Validation

- (IBAction)textFieldValueChanged:(id)sender
{
	if ([self isFormValid])
		[self enableSignIn];
	else
		[self disableSignIn];
}

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
	//signInLabel.textColor = [UIColor blackColor];
	//signInCell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (void)disableSignIn
{
	//signInLabel.textColor = [UIColor grayColor];
	//signInCell.selectionStyle = UITableViewCellSelectionStyleNone;
}



#pragma mark - UITextFieldDelegate

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
	else if ([self isFormValid])
	{
		[self validateAccount];
	}
	
	return NO;
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"ServerCell";
    if (indexPath.row == 1)
		cellIdentifier = @"UserCell";
	else if (indexPath.row == 2)
		cellIdentifier = @"PassCell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

	UITextField *inputField = (UITextField *)[cell viewWithTag:2];
	
    switch (indexPath.row)
	{
		case 0:
			inputField = serverURLField;
			break;
		case 1:
			inputField = usernameField;
			break;
		case 2:
		default:
			inputField = passwordField;
			break;
	}
    
    return cell;
}



#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!indexPath.section)
		return;
	
	if (![self isFormValid])
		return;
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self validateAccount];
}



#pragma mark - ServerStatusDelegate

- (void)validateServerStatusUpdate:(NSString *)status
{
	[hud setCaption:status];
	[hud update];
}

- (void)validateServerFailedWithError:(NSError *)error
{
	NSString *reason = nil;
	
	if (error)
	{
		XDrvLog(@"Validate account failed: %@", [error description]);
		
		if ([error code] == NSURLErrorUserCancelledAuthentication)
		{
			// Authentication failed
			reason = NSLocalizedStringFromTable(@"Authentication failed; verify username/password",
												@"AccountViewController", 
												@"Message displayed when authentication fails during server validation.");
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
	
	[hud setCaption:reason];
	[hud setActivity:NO];
	[hud setImage:[UIImage imageNamed:@"x"]];
	[self updateHudWithDelay];
	
	[self enableSignIn];
}

- (void)validateServerFinishedWithSuccess
{
	// Success!
	[hud setActivity:NO];
	[hud setImage:[UIImage imageNamed:@"check"]];
	[hud setCaption:@"Success!"];
	[self updateHudWithDelay];
	
	// Hide view after hud hides
	[self performSelector:@selector(dismissAccountInfo) withObject:nil afterDelay:2.0];
}


@end


























