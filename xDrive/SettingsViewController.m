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
	hostnameLabel.text = [XService sharedXService].activeServer.hostname;
	NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[XDriveConfig protectionSpaceForServer:nil]];
	userLabel.text = credential.user;
	
	// Storage
	NSInteger amount = [[XService sharedXService] localStorageAmount];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



@end















