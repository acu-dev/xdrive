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



@interface SettingsViewController()

- (void)customizeAccountCell:(UITableViewCell *)cell;

@end



@implementation SettingsViewController






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



#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (!section)
		return 1;
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return [NSString stringWithFormat:@"Version %@", [XDriveConfig appVersion]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *cellIdentifier = (indexPath.section) ? @"BasicCell" : @"AccountCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

	[self customizeAccountCell:cell];
    
    return cell;
}



#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!indexPath.section)
	{
		return 55;
	}
	return 45;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	/*switch (indexPath.section) {
		case 0: {
			// Account
			
		} break;
		
		case 1: {
			// Storage
			
		} break;
			
		case 2: {
			// Misc
			
		} break;
			
		default:
			break;
	}*/
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}



#pragma mark - Cell customization

- (void)customizeAccountCell:(UITableViewCell *)cell
{
	cell.textLabel.text = [XService sharedXService].activeServer.hostname;
	
	NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[XDriveConfig protectionSpaceForServer:nil]];
	cell.detailTextLabel.text = credential.user;
}

@end















