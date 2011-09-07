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
@property (nonatomic, strong) XServer *server;
@property (nonatomic, assign) BOOL isAuthenticating;
@property (nonatomic, strong) ATMHud *hud;
@end



@implementation AccountViewController

// Private ivars
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
		
		// fill in the user/pass
		
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
	
	[self setSignInLabel:nil];
	[self setSignInCell:nil];
	[self setServerURLField:nil];
	[self setUsernameField:nil];
	[self setPasswordField:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)textFieldValueChanged:(id)sender
{
	if ([self isFormValid])
		[self enableSignIn];
	else
		[self disableSignIn];
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
	
	NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:
							 serverURLField.text, @"serverHost",
							 usernameField.text, @"username",
							 passwordField.text, @"password",
							 nil];
	
	[[XService sharedXService] validateAccountDetails:details withViewController:self];
}

- (void)updateDisplayWithMessage:(NSString *)message
{
	[hud setCaption:message];
	[hud update];
}

- (void)receiveValidateAccountResponse:(BOOL)isAccountValid withMessage:(NSString *)message
{
	// Time to display hud before hiding
	NSTimeInterval updateDisplayTime = 2.0;
	
	// Stop activity indicator and show message
	[hud setCaption:message];
	[hud setActivity:NO];
	
	if (isAccountValid)
	{
		// Success!
		[hud setImage:[UIImage imageNamed:@"check"]];
		
		// Hide view after hud hides
		[self performSelector:@selector(dismissAccountInfo) withObject:nil afterDelay:updateDisplayTime];
	}
	else
	{
		// Failed
		[hud setImage:[UIImage imageNamed:@"x"]];
	}
	
	// Display updated hud temporarily
	[hud update];
	[hud hideAfter:updateDisplayTime];
	
	[self enableSignIn];
}

- (void)dismissAccountInfo
{
	[self performSegueWithIdentifier:@"dismissAccountInfo" sender:self];
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

@end


























