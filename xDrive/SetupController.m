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
#import "DefaultPathController.h"



typedef enum _SetupStep {
	ValidateServer,
	FetchingDefaultPaths
} SetupStep;



@interface SetupController() <XServiceRemoteDelegate>

@property (nonatomic, strong) SetupViewController *viewController;
	// View controller to provide user/host/pass

@property (nonatomic, strong) XServer *server;

@property (nonatomic, strong) NSString *validateUser, *validatePass;
	// User/pass to use when authenticating to server

@property (nonatomic, strong) DefaultPathController *defaultPathController;

- (void)receiveServerInfoResult:(NSObject *)result;
- (BOOL)isServerVersionCompatible:(NSString *)version;

	
@end




@implementation SetupController

@synthesize viewController;
@synthesize server;
@synthesize validateUser, validatePass;
@synthesize defaultPathController;

- (UIViewController *)viewController
{
	if (!viewController)
	{
		NSString *storyboardName = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"MainStoryboard_iPhone" : @"MainStoryboard_iPad";
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
		viewController = [storyboard instantiateViewControllerWithIdentifier:@"SetupView"];
		viewController.setupController = self;
	}
	return viewController;
}



#pragma mark - Setup

- (void)setupWithUsername:(NSString *)username password:(NSString *)password forHost:(NSString *)host
{
	// Save user/pass for validation on next step
	validateUser = username;
	validatePass = password;
	
	// Get server info
	[[XService sharedXService].remoteService fetchInfoAtHost:host withDelegate:self];
}

- (void)receiveServerInfoResult:(NSObject *)result
{	
	NSDictionary *xserviceInfo = [(NSDictionary *)result objectForKey:@"xservice"];
	
	// Evaluate version info
	if (![self isServerVersionCompatible:[xserviceInfo objectForKey:@"version"]])
	{
		// Version incompatible
		NSString *title = NSLocalizedStringFromTable(@"Unsupported server version",
													 @"XService",
													 @"Title for error given when a server responds with an unsupported version.");
		NSString *desc = NSLocalizedStringFromTable(@"Server's version is unsupported by this app. Please check for updates.", 
													@"XService",
													@"Description for error given when a server responds with an unsupported version.");
		NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:title, NSLocalizedFailureReasonErrorKey, desc, NSLocalizedDescriptionKey, nil];
		NSError *error = [NSError errorWithDomain:@"XService" code:ServerIsIncompatible userInfo:errorInfo];

		[viewController setupFailedWithError:error];
		return;
	}

	// Create server object
	server = [NSEntityDescription insertNewObjectForEntityForName:@"Server" 
													   inManagedObjectContext:[[XService sharedXService].localService managedObjectContext]];
	server.protocol = [xserviceInfo objectForKey:@"protocol"];
	server.port = [xserviceInfo objectForKey:@"port"];
	server.hostname = [xserviceInfo objectForKey:@"host"];
	server.context = [xserviceInfo objectForKey:@"context"];
	server.servicePath = [xserviceInfo objectForKey:@"serviceBase"];
	XDrvDebug(@"Created enw server object: %@", server);
	
	// Fetch default paths
	defaultPathController = [[DefaultPathController alloc] initWithServer:server];
	[defaultPathController fetchDefaultPathsWithViewController:viewController];
}

- (BOOL)isServerVersionCompatible:(NSString *)version
{
	// This could evaluate a set of compatible versions. For now
	// it requires an exact match.
	return ([version isEqualToString:[XDriveConfig appVersion]]);
}


#pragma mark - XServiceRemoteDelegate

- (void)connectionFinishedWithResult:(NSObject *)result
{
	if (!server)
	{
		[self receiveServerInfoResult:result];
		return;
	}

	XDrvLog(@"Finished: %@", result);
}

- (void)connectionFailedWithError:(NSError *)error
{
	XDrvLog(@"Failed: %@", error);
}

- (NSURLCredential *)credentialForAuthenticationChallenge
{
	XDrvDebug(@"Providing temp credential");
	return nil;
}

@end
