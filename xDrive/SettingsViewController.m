//
//  SettingsViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 9/23/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "SettingsViewController.h"
#import "XDriveConfig.h"
#import "XService.h"
#import "WebViewController.h"



static NSString *FeedbackToAddress = @"xdrive-feedback@acu.edu";


@interface SettingsViewController ()

- (void)openFeedbackEmail;

@end



@implementation SettingsViewController

@synthesize hostnameLabel, userLabel, storageLabel;




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
	
	// Account
	hostnameLabel.text = [XService sharedXService].localService.server.hostname;
	NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[XDriveConfig protectionSpaceForServer:nil]];
	userLabel.text = credential.user;
	
	// Storage
	storageLabel.text = [[XDriveConfig localStorageOption] objectForKey:@"description"];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	self.hostnameLabel = nil;
	self.userLabel = nil;
	self.storageLabel = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"ShowAbout"])
	{
		NSURL *aboutURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"]];
		[((WebViewController *)segue.destinationViewController) loadContentAtURL:aboutURL withTitle:@"About"];
	}
	else if ([segue.identifier isEqualToString:@"ShowLegal"])
	{
		NSURL *aboutURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"legal" ofType:@"html"]];
		[((WebViewController *)segue.destinationViewController) loadContentAtURL:aboutURL withTitle:@"Legal"];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}



#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == 3)
		return [NSString stringWithFormat:@"Version %@", [XDriveConfig appVersion]];
	else
		return nil;
}



#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 3)
	{
		if ([MFMailComposeViewController canSendMail])
		{
			[self openFeedbackEmail];
		}
		else
		{
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Available" message:@"This device is not configured for sending email" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}
}



#pragma mark - Feedback

- (void)openFeedbackEmail
{
	MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
	[mailViewController setToRecipients:[NSArray arrayWithObject:FeedbackToAddress]];
	mailViewController.mailComposeDelegate = self;
	
	NSString *device = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"iPhone" : @"iPad";
	NSString *subject = [NSString stringWithFormat:@"%@ %@ for %@ Feedback", [XDriveConfig appName], [XDriveConfig appVersion], device];
	[mailViewController setSubject:subject];
	
	[self presentModalViewController:mailViewController animated:YES];
}



#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[self dismissModalViewControllerAnimated:YES];
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}



@end















