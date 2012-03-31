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
static NSString *downloadURL = @"http://xdrive.acu.edu/app.plist";


@interface VersionController ()

@property (nonatomic, strong) UIAlertView *alert;

- (void)alertUserToNewAppVersion;

@end


@implementation VersionController

@synthesize alert;

- (void)checkVersion
{
	if ([[XDriveConfig appVersion] hasSuffix:@"-SNAPSHOT"]) return;
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:latestVersionURL]];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

							   if (error)
							   {
								   XDrvDebug(@"Error fetching version information: %@", error);
								   return;
							   }

							   NSError *jsonError = nil;
							   id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
							   if (jsonError || ![result isKindOfClass:[NSDictionary class]])
							   {
								   XDrvDebug(@"Error converting JSON data into object: %@", jsonError);
								   return;
							   }
							   else
							   {
								   DTVersion *latestVersion = [DTVersion versionWithString:[(NSDictionary *)result objectForKey:@"latest"]];
								   DTVersion *currentVersion = [DTVersion versionWithString:[XDriveConfig appVersion]];
								   
								   if ([latestVersion compare:currentVersion] == NSOrderedDescending)
								   {
									   [self alertUserToNewAppVersion];
								   }
								   else
								   {
									   XDrvDebug(@"Current version is newer than remote version");
								   }
							   }
						   }];

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



#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex)
	{
		// URL for app plist if it is protected with basic auth
		NSURL *appURL = [NSURL URLWithString:[NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@", downloadURL]];
		[[UIApplication sharedApplication] openURL:appURL];
	}
	self.alert = nil;
}


@end



