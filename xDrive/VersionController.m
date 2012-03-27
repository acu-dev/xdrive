//
//  VersionController.m
//  xDrive
//
//  Created by Chris Gibbs on 2/24/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "VersionController.h"
#import "XDriveConfig.h"
#import "DTVersion.h"

static NSString *latestVersionURL = @"http://xdrive.acu.edu/version";
static NSString *downloadURL = @"http://xdrive.acu.edu";


@interface VersionController ()

@property (nonatomic, strong) UIAlertView *alert;

- (void)alertUserToNewAppVersion;
	// Creates an alert that allows user to download new version

@end



@implementation VersionController

@synthesize alert;



- (void)checkVersion
{
	if (![[XDriveConfig appVersion] hasSuffix:@"-SNAPSHOT"])
	{
		//[[XService sharedXService].remoteService fetchJSONAtURL:latestVersionURL withDelegate:self];
	}
}

- (void)alertUserToNewAppVersion
{
	NSString *titleTemplate = NSLocalizedStringFromTable(@"A newer version of %@ is available", 
														 @"xdrive",
														 @"Title for alert displayed when a newer version is available");
	NSString *title = [NSString stringWithFormat:titleTemplate, [XDriveConfig appName]];
	NSString *message = NSLocalizedStringFromTable(@"Would you like to download it now?", 
												   @"xdrive",
												   @"Message for alert displayed when a newer version is available");
	
	alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles:@"Download", nil];
	[alert show];
}



#pragma mark - XServiceRemoteDelegate

- (void)connectionFinishedWithResult:(NSObject *)result
{
	if (![result isKindOfClass:[NSDictionary class]])
		return;
	
	DTVersion *latestVersion = [DTVersion versionWithString:[(NSDictionary *)result objectForKey:@"latest"]];
	DTVersion *currentVersion = [DTVersion versionWithString:[XDriveConfig appVersion]];
	
	if ([latestVersion compare:currentVersion] == NSOrderedDescending)
	{
		[self alertUserToNewAppVersion];
	}
}

- (void)connectionFailedWithError:(NSError *)error
{
	XDrvLog(@"Version check failed: %@", error);
}



#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex)
	{
		// URL for app plist if it is protected with basic auth
		//NSURL *appURL = [NSURL URLWithString:[NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@", downloadURL]];
		
		// URL to open app download page in safari
		NSURL *appURL = [NSURL URLWithString:downloadURL];
		
		[[UIApplication sharedApplication] openURL:appURL];
	}
	self.alert = nil;
}


@end



