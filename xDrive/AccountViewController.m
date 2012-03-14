//
//  AccountViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 2/15/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "AccountViewController.h"
#import "XDriveConfig.h"
#import "XService.h"
#import "AppDelegate.h"


@interface AccountViewController ()

- (NSString *)usernameFromDefaultCredential;
- (void)logout;

@end


@implementation AccountViewController

@synthesize serverLabel, usernameLabel;


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

	serverLabel.text = [XService sharedXService].localService.server.hostname;
	usernameLabel.text = [self usernameFromDefaultCredential];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	self.serverLabel = nil;
	self.usernameLabel = nil;
}



#pragma mark - View content

- (NSString *)usernameFromDefaultCredential
{
	NSURLProtectionSpace *protectionSpace = [XDriveConfig protectionSpaceForServer:nil];
	NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:protectionSpace];
	return credential.user;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logout" message:@"Are you sure?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Logout", nil];
		[alert show];
	}
}



#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex)
	{
		[self logout];
	}
}



#pragma mark - Logout

- (void)logout
{
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] logoutAndBeginSetup];
}

@end
























