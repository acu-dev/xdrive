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


static NSString * const kXServiceDefaultProtocol = @"https";
static NSUInteger const kXServiceDefaultPort = 443;
static NSString * const kXServiceDefaultContext = @"/xservice";
static NSUInteger const kXServiceDefaultCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
static NSUInteger const kXServiceDefaultTimoutInterval = 15;


@interface SetupController()

@property (nonatomic, strong) SetupViewController *_viewController;
@property (nonatomic, strong) XServiceRemote *_remoteService;
@property (nonatomic, strong) DefaultPathController *_defaultPathController;

- (void)receiveServerInfoResult:(NSObject *)result;
- (BOOL)isServerVersionCompatible:(NSString *)version;
- (void)saveCredentials;
	
@end




@implementation SetupController

// Public
@synthesize viewController;
@synthesize validateUser = _validateUser;
@synthesize validatePass = _validatePass;
@synthesize server = _server;
@synthesize isResetting = _isResetting;

// Private
@synthesize _viewController;
@synthesize _remoteService;
@synthesize _defaultPathController;


- (void)dealloc
{
	_validateUser = nil;
	_validatePass = nil;
	_server = nil;
	self._viewController = nil;
	self._defaultPathController = nil;
}



#pragma mark - Accessors

- (UIViewController *)viewController
{
	if (!_viewController)
	{
		_viewController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"SetupView"];
		_viewController.setupController = self;
	}
	return _viewController;
}



#pragma mark - Setup

- (void)setupWithUsername:(NSString *)username password:(NSString *)password forHost:(NSString *)host
{	
	// Save user/pass for validation on next step
	_validateUser = username;
	_validatePass = password;
	
	// Build URL from defaults
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%i%@", kXServiceDefaultProtocol, host, kXServiceDefaultPort, kXServiceDefaultContext]];
	XDrvDebug(@"Fetching server info from URL: %@", [url absoluteString]);
	
	// Create request
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:kXServiceDefaultCachePolicy timeoutInterval:kXServiceDefaultTimoutInterval];
	
	// Send request
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		if (error)
		{
			[_viewController setupFailedWithError:error];
		}
		else
		{
			NSError *jsonError = nil;
			id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
			if (jsonError || ![result isKindOfClass:[NSDictionary class]])
			{
				[_viewController setupFailedWithError:jsonError];
			}
			else
			{
				[self receiveServerInfoResult:result];
			}
		}
	}];
}

- (void)receiveServerInfoResult:(NSDictionary *)result
{	
	XDrvDebug(@"Received server info");
	NSDictionary *xserviceInfo = [result objectForKey:@"xservice"];
	
	// Evaluate version info
	if (![self isServerVersionCompatible:[xserviceInfo objectForKey:@"version"]])
	{
		// Version incompatible
		XDrvLog(@"Server version is incompatible");
		NSString *title = NSLocalizedStringFromTable(@"Unsupported server version",
													 @"XService",
													 @"Title for error given when a server responds with an unsupported version.");
		NSString *desc = NSLocalizedStringFromTable(@"Server's version is unsupported by this app. Please check for updates.", 
													@"XService",
													@"Description for error given when a server responds with an unsupported version.");
		NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:title, NSLocalizedFailureReasonErrorKey, desc, NSLocalizedDescriptionKey, nil];
		NSError *error = [NSError errorWithDomain:@"XService" code:ServerIsIncompatible userInfo:errorInfo];

		[_viewController setupFailedWithError:error];
		return;
	}
		
	// Create server object
	_server = [[XService sharedXService].localService createServerWithProtocol:[xserviceInfo objectForKey:@"protocol"]
																		  port:[xserviceInfo objectForKey:@"port"]
																 	  hostname:[xserviceInfo objectForKey:@"host"]
																	   context:[xserviceInfo objectForKey:@"context"]
																   servicePath:[xserviceInfo objectForKey:@"serviceBase"]];
	
	// Fetch default paths
	_defaultPathController = [[DefaultPathController alloc] initWithController:self];
	[_defaultPathController fetchDefaultPaths];
}

- (BOOL)isServerVersionCompatible:(NSString *)version
{
	// Evaluate if the server version is listed as supported
	return ([[XDriveConfig supportedServiceVersions] containsObject:version]);
}

- (void)saveCredentials
{
	// Create protection space for the new server
	NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:_server.hostname
																				  port:[_server.port integerValue]
																			  protocol:_server.protocol
																				 realm:_server.hostname
																  authenticationMethod:@"NSURLAuthenticationMethodDefault"];
	// Make a credential with permanent persistence
	NSURLCredential *credential = [NSURLCredential credentialWithUser:_validateUser password:_validatePass persistence:NSURLCredentialPersistencePermanent];
	
	// Save credential to the protection space
	XDrvDebug(@"Saving credentials for user: %@", _validateUser);
	[[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:protectionSpace];
}



#pragma mark - Default Paths Status

- (void)defaultPathsStatusUpdate:(NSString *)status
{
	[_viewController setupStatusUpdate:status];
}

- (void)defaultPathsFailedWithError:(NSError *)error
{
	[_viewController setupFailedWithError:error];
}

- (void)defaultPathsValidated
{
	// Save the context now that server info has been validated
	[[XService sharedXService].localService saveWithCompletionBlock:^(NSError *error) {
		
		if (error)
		{
			XDrvLog(@"Error: unable to save context after adding new server - %@", error);
			[_viewController setupFailedWithError:error];
		}
		else
		{
			// Success!
			XDrvDebug(@"Successfully saved server and default paths");
			
			// Update remote service
			//[XService sharedXService].remoteService.activeServer = server;
			
			// Save the credentials permanently now that they have been validated
			[self saveCredentials];
			
			// Pre-populate default path directory contents
			[_defaultPathController initializeDefaultPaths];
		}
	}];
}

- (void)defaultPathsFinished
{
	XDrvLog(@"Done setting up default paths; saving context...");
	
	// Save the context now that the default paths have been initialized
	[[XService sharedXService].localService saveWithCompletionBlock:^(NSError *error) {
		
		// Set default local storage
		[XDriveConfig setLocalStorageOption:[XDriveConfig defaultLocalStorageOption]];
			
		// All done
		XDrvDebug(@"Setup Finished");
		[_viewController setupFinished];
	}];
}


#pragma mark - XServiceRemoteDelegate

- (void)connectionFinishedWithResult:(NSObject *)result
{
	[self receiveServerInfoResult:result];
}

- (void)connectionFailedWithError:(NSError *)error
{
	[_viewController setupFailedWithError:error];
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














