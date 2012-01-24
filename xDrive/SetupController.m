//
//  SetupController.m
//  xDrive
//
//  Created by Chris Gibbs on 1/20/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "SetupController.h"
#import "SetupViewController.h"
#import "XService.h"
#import "XServiceRemote.h"
#import "XDriveConfig.h"




@interface SetupController() <XServiceRemoteDelegate>

@property (nonatomic, strong) NSURLCredential *validateCredential;
	// Credential used when validating server info
	
@end




@implementation SetupController

@synthesize viewController;
@synthesize validateCredential;

- (UIViewController *)viewController
{
	if (!viewController)
	{
		NSString *storyboardName = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"MainStoryboard_iPhone" : @"MainStoryboard_iPad";
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
		viewController = [storyboard instantiateViewControllerWithIdentifier:@"SetupView"];
		((SetupViewController *)viewController).setupController = self;
	}
	return viewController;
}



#pragma mark - Setup

- (void)setupWithUsername:(NSString *)username password:(NSString *)password forHost:(NSString *)host
{
	// Create validation credential
	
	
	// Get server info
	[[XService sharedXService].remoteService fetchInfoAtHost:host withDelegate:self];
}


#pragma mark - XServiceRemoteDelegate

- (void)connectionFinishedWithResult:(NSObject *)result
{
	
}

- (void)connectionFailedWithError:(NSError *)error
{
	if ([error code] == -1013)
	{
		// Build fake info object
		NSDictionary *xservice = [[NSDictionary alloc] initWithObjectsAndKeys:
								  @"1.0-SNAPSHOT", @"version",
								  @"https", @"protocol",
								  @"webfiles.acu.edu", @"host",
								  [NSNumber numberWithInt:443], @"port",
								  @"/xservice", @"context",
								  @"/rs", @"serviceBase",
								  nil];
		NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:@"xservice", xservice, nil];
		[self connectionFinishedWithResult:result];
	}
}

- (NSURLCredential *)credentialForAuthenticationChallenge
{
	return nil;
}

@end
