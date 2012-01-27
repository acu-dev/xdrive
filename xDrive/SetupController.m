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

@property (nonatomic, assign) SetupStep setupStep;

@property (nonatomic, strong) DefaultPathController *defaultPathController;

- (void)receiveServerInfoResult:(NSObject *)result;
- (BOOL)isServerVersionCompatible:(NSString *)version;
- (void)saveCredentials;
	
@end




@implementation SetupController

@synthesize validateUser, validatePass;
@synthesize viewController;
@synthesize server;
@synthesize setupStep;
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
	setupStep = ValidateServer;
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
	XDrvDebug(@"Created new server object: %@", server);
	
	// Become auth challenge handler
	[XService sharedXService].remoteService.authDelegate = self;
	
	// Fetch default paths
	setupStep = FetchingDefaultPaths;
	defaultPathController = [[DefaultPathController alloc] initWithController:self];
	[defaultPathController fetchDefaultPathsForServer:server];
}

- (BOOL)isServerVersionCompatible:(NSString *)version
{
	// This could evaluate a set of compatible versions. For now
	// it requires an exact match.
	return ([version isEqualToString:[XDriveConfig appVersion]]);
}

- (void)saveCredentials
{
	// Create protection space for the new server
	NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:server.hostname
																				  port:[server.port integerValue]
																			  protocol:server.protocol
																				 realm:server.hostname
																  authenticationMethod:@"NSURLAuthenticationMethodHTTPBasic"];
	// Make a credential with permanent persistence
	NSURLCredential *credential = [NSURLCredential credentialWithUser:validateUser password:validatePass persistence:NSURLCredentialPersistencePermanent];
	
	// Save credential to the protection space
	XDrvDebug(@"Saving credentials for user: %@", validateUser);
	[[NSURLCredentialStorage sharedCredentialStorage] setCredential:credential forProtectionSpace:protectionSpace];
}



#pragma mark - Default Paths Status

- (void)defaultPathsStatusUpdate:(NSString *)status
{
	[viewController setupStatusUpdate:status];
}

- (void)defaultPathsFailedWithError:(NSError *)error
{
	[viewController setupFailedWithError:error];
}

- (void)defaultPathsValidated
{
	// Save the context now that server info has been validated
	NSError *error = nil;
	if (![[[XService sharedXService].localService managedObjectContext] save:&error])
	{
		// Handle error
		XDrvLog(@"Error: unable to save context after adding new server - %@", [error localizedDescription]);
		[viewController setupFailedWithError:error];
		return;
	}
	
	// Success!
	XDrvDebug(@"Successfully saved server");
	
	// Update remote service
	[XService sharedXService].remoteService.activeServer = server;
	
	// Save the credentials permanently now that they have been validated
	[self saveCredentials];
	
	// Pre-populate default path directory contents
	[defaultPathController initializeDefaultPaths];
}

- (void)defaultPathsFinished
{
	[viewController setupFinished];
}


#pragma mark - XServiceRemoteDelegate

- (void)connectionFinishedWithResult:(NSObject *)result
{
	[self receiveServerInfoResult:result];
}

- (void)connectionFailedWithError:(NSError *)error
{
	[viewController setupFailedWithError:error];
}

- (NSURLCredential *)credentialForAuthenticationChallenge
{
	XDrvDebug(@"Providing temp credential until it is validated");
	return [NSURLCredential credentialWithUser:validateUser password:validatePass persistence:NSURLCredentialPersistenceNone];
}

@end
