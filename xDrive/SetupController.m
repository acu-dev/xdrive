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
#import "UIStoryboard+Xdrive.h"
#import "DTAsyncFileDeleter.h"



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

// Public
@synthesize validateUser, validatePass;
@synthesize isResetting = _isResetting;

// Private
@synthesize viewController;
@synthesize server;
@synthesize setupStep;
@synthesize defaultPathController;



- (void)dealloc
{
	self.validateUser = nil;
	self.validatePass = nil;
	self.defaultPathController = nil;
	self.server = nil;
	self.viewController = nil;
}



- (UIViewController *)viewController
{
	if (!viewController)
	{
		viewController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"SetupView"];
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
	server = [[XService sharedXService].localService createServerWithProtocol:[xserviceInfo objectForKey:@"protocol"]
																		 port:[xserviceInfo objectForKey:@"port"]
																	 hostname:[xserviceInfo objectForKey:@"host"]
																	  context:[xserviceInfo objectForKey:@"context"]
																  servicePath:[xserviceInfo objectForKey:@"serviceBase"]];
	
	// Become auth challenge handler
	[XService sharedXService].remoteService.authDelegate = self;
	
	// Fetch default paths
	setupStep = FetchingDefaultPaths;
	defaultPathController = [[DefaultPathController alloc] initWithSetupController:self];
	[defaultPathController fetchDefaultPathsForServer:server];
}

- (BOOL)isServerVersionCompatible:(NSString *)version
{
	// Evaluate if the server version is listed as supported
	return ([[XDriveConfig supportedServiceVersions] containsObject:version]);
}

- (void)saveCredentials
{
	// Create protection space for the new server
	NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:server.hostname
																				  port:[server.port integerValue]
																			  protocol:server.protocol
																				 realm:server.hostname
																  authenticationMethod:@"NSURLAuthenticationMethodDefault"];
	// Make a credential with permanent persistence
	NSURLCredential *credential = [NSURLCredential credentialWithUser:validateUser password:validatePass persistence:NSURLCredentialPersistencePermanent];
	
	// Save credential to the protection space
	XDrvDebug(@"Saving credentials for user: %@", validateUser);
	[[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:protectionSpace];
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
	[[XService sharedXService].localService saveWithCompletionBlock:^(NSError *error) {
		
		if (error)
		{
			XDrvLog(@"Error: unable to save context after adding new server - %@", error);
			[viewController setupFailedWithError:error];
		}
		else
		{
			// Success!
			XDrvDebug(@"Successfully saved server and default paths");
			
			// Update remote service
			[XService sharedXService].remoteService.activeServer = server;
			
			// Save the credentials permanently now that they have been validated
			[self saveCredentials];
			
			// Pre-populate default path directory contents
			[defaultPathController initializeDefaultPaths];
		}
	}];
}

- (void)defaultPathsFinished
{
	// Save the context now that the default paths have been initialized
	[[XService sharedXService].localService saveWithCompletionBlock:^(NSError *error) {
		
		// Set default local storage
		[XDriveConfig setLocalStorageOption:[XDriveConfig defaultLocalStorageOption]];
			
		// All done
		[viewController setupFinished];
	}];
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



#pragma mark - Reset

- (void)resetBeforeSetup
{
	_isResetting = YES;
	
	// Delete cache files
	[[XService sharedXService] clearCacheWithCompletionBlock:^(NSError *error) {}];
	
	// Delete meta files
	NSURL *metaURL = [NSURL fileURLWithPath:[[[XService sharedXService] documentsPath] stringByAppendingString:@"-meta"]];
	XDrvDebug(@"Removing meta dir at: %@", metaURL.path);
	[[DTAsyncFileDeleter sharedInstance] removeItemAtURL:metaURL];
	
	// Reset database
	[[[XService sharedXService] localService] resetPersistentStore];
	
	_isResetting = NO;
}

@end














