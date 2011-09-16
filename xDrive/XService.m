//
//  XService.m
//  xDrive
//
//  Created by Chris Gibbs on 7/1/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XService.h"
#import "XDefaultPath.h"
#import <CGNetUtils/CGNetUtils.h>



@interface XService() <CGChallengeResponseDelegate>

@property (nonatomic, weak) AccountViewController *accountViewController;
	// View controller to send server validation results back to

@property (nonatomic, strong) NSURLCredential *validateCredential;
	// Credential to use when validating server version

- (void)receiveServerVersionResult:(NSDictionary *)result;
	// Determines if server's version is compatible

- (void)receiveServerInfoResult:(NSDictionary *)result;
	// Creates the server object to be saved and calls -fetchDefaultPaths


@property (nonatomic, assign) int fetchingDefaultPaths;

// Account validation/storage
//- (void)receiveValidateAccountDetailsResponse:(XServiceFetcher *)fetcher;

- (void)fetchDefaultPaths:(NSDictionary *)pathDetails;
//- (void)receiveDefaultPath:(XServiceFetcher *)fetcher;
- (void)saveCredentialWithUsername:(NSString *)user password:(NSString *)pass;
- (void)removeAllCredentialsForProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
- (NSURLProtectionSpace *)protectionSpace;
- (NSURLCredential *)storedCredentialForProtectionSpace:(NSURLProtectionSpace *)protectionSpace withUser:(NSString *)user;

// Directory
- (XDirectory *)updateDirectoryDetails:(NSDictionary *)details;

@end







@implementation XService



// Private ivars
@synthesize localService = _localService;
@synthesize remoteService = _remoteService;
@synthesize accountViewController;
@synthesize validateCredential;


@synthesize fetchingDefaultPaths;


// Public ivars
static XService *sharedXService;
@synthesize rootViewController;


#pragma mark - Initialization

+ (XService *)sharedXService
{
	@synchronized(self)
	{
		if (sharedXService == nil)
		{
			sharedXService = [[self alloc] init];
		}
	}
	return sharedXService;
}

- (id)init
{
    self = [super init];
    if (self)
	{
		// Init local and remote services
		_localService = [[XServiceLocal alloc] init];
		_remoteService = [[XServiceRemote alloc] initWithServer:[self.localService activeServer]];
		
		// Set self as the challenge response delegate
		[CGNet utils].challengeResponseDelegate = self;
    }
    return self;
}



#pragma mark - Server

- (XServer *)activeServer
{
	return [self.localService activeServer];
}

- (void)validateActiveServer
{
	[self.remoteService fetchServerVersion:nil withTarget:self action:@selector(receiveServerVersionResult:)];
}

- (void)validateUsername:(NSString *)username password:(NSString *)password forHost:(NSString *)host withViewController:(AccountViewController *)viewController
{
	accountViewController = viewController;
	validateCredential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
	[self.remoteService fetchServerVersion:host withTarget:self action:@selector(receiveServerVersionResult:)];
}

- (void)receiveServerVersionResult:(NSObject *)result
{
	if ([result isKindOfClass:[NSError class]])
	{
		NSLog(@"Error getting server version");
		[accountViewController validateAccountFailedWithError:(NSError *)result];
	}
	
	NSLog(@"received version result: %@", result);
	// message accountVC the version status
}


/*
#pragma mark - Account validation

- (void)validateAccountDetails:(NSDictionary *)details withViewController:(AccountViewController *)viewController
{
	accountDetailsToValidate = details;
	accountViewController = viewController;
	[remoteService fetchServerInfo:details withTarget:self action:@selector(receiveValidateAccountDetailsResponse:)];
}

- (void)receiveValidateAccountDetailsResponse:(XServiceFetcher *)fetcher
{
	if (fetcher.result)
	{
		// Received a valid server response
		XSvcLog(@"Received a valid server description");
		[self saveServerWithDetails:fetcher.result];
		[self saveCredentialWithUsername:[accountDetailsToValidate objectForKey:@"username"] password:[accountDetailsToValidate objectForKey:@"password"]];
		
		
		if ([fetcher.result objectForKey:@"defaultPaths"])
			[self fetchDefaultPaths:[fetcher.result objectForKey:@"defaultPaths"]];
	}
	else if (fetcher.finalError)
	{
		XSvcLog(@"Received error with code %i", [fetcher.finalError code]);
		[accountViewController receiveValidateAccountResponse:NO withMessage:[fetcher.finalError localizedDescription]];
	}
	else
	{
		XSvcLog(@"Invalid response");
	}
}*/

#pragma mark - Account storage

- (void)saveServerWithDetails:(NSDictionary *)details
{
	XSvcLog(@"Creating new server object");
	XServer *newServer = [NSEntityDescription insertNewObjectForEntityForName:@"Server" 
													   inManagedObjectContext:[self.localService managedObjectContext]];
	NSDictionary *serverDetails = [details objectForKey:@"server"];
	newServer.protocol = [serverDetails objectForKey:@"protocol"];
	newServer.port = [serverDetails objectForKey:@"port"];
	newServer.hostname = [serverDetails objectForKey:@"host"];
	newServer.servicePath = [serverDetails objectForKey:@"servicePath"];
	
	// Create all default path objects
	NSDictionary *pathDetails = [details objectForKey:@"defaultPaths"];
	for (NSDictionary *defaultPath in pathDetails)
	{
		XDefaultPath *newDefaultPath = [NSEntityDescription insertNewObjectForEntityForName:@"DefaultPath"
																	 inManagedObjectContext:[self.localService managedObjectContext]];
		newDefaultPath.name = [defaultPath objectForKey:@"name"];
		newDefaultPath.path = [defaultPath objectForKey:@"path"];
		[newServer addDefaultPathsObject:newDefaultPath];
	}
	
	// Save context
	NSError *error = nil;
	if ([[self.localService managedObjectContext] save:&error])
	{
		// Success!
		XSvcLog(@"Successfully created server");
		
		// Update remote service
		self.remoteService.activeServer = newServer;
	}
	else
	{
		// Handle error
		XSvcLog(@"Error: unable to save context after adding new server - %@", [error localizedDescription]);
	}
}

/*
- (void)fetchDefaultPaths:(NSDictionary *)pathDetails
{
	XSvcLog(@"Fetching default paths...");
	
	// Update display message
	[accountViewController updateDisplayWithMessage:NSLocalizedStringFromTable(@"Downloading defaults...",
																			   @"XService",
																			   @"Message displayed while defaults are being downloaded from the server.")];

	// Counter to decrement as fetches return
	fetchingDefaultPaths = [pathDetails count] + 1;
	
	// Fire off directory request for root path
	[remoteService fetchDefaultPath:@"/" withTarget:self action:@selector(receiveDefaultPath:)];
	
	// Fire off directory request for each default path
	for (NSDictionary *defaultPath in pathDetails)
	{
		[remoteService fetchDefaultPath:[defaultPath objectForKey:@"path"] withTarget:self action:@selector(receiveDefaultPath:)];
	}
}

- (void)receiveDefaultPath:(XServiceFetcher *)fetcher
{
	// Decrement counter
	fetchingDefaultPaths--;
	
	if (!fetcher.result)
	{
		XSvcLog(@"Error: No data found for default path; server not configured correctly");
		return;
	}
	
	// Create directory
	XDirectory *directory = [self updateDirectoryDetails:fetcher.result];
	
	// Find the default path object for the directory
	for (XDefaultPath *defaultPath in [self activeServer].defaultPaths)
	{
		if ([directory.path isEqualToString:defaultPath.path])
		{
			// Associate directory with default path
			defaultPath.directory = directory;
			NSError *error = nil;
			if (![[localService managedObjectContext] save:&error])
			{
				XSvcLog(@"Error: Unable to attach directory with path %@ to default path", directory.path);
			}
		}
	}
	
	// For funsies
	if (fetchingDefaultPaths == 2)
		[accountViewController updateDisplayWithMessage:@"Reticulating splines..."];
	
	if (!fetchingDefaultPaths)
	{
		// All done getting default paths; update view
		[accountViewController receiveValidateAccountResponse:YES
												  withMessage:NSLocalizedStringFromTable(@"All done.",
																						 @"XService",
																						 @"Message displayed when defaults are finished downloading")];
		// Cleanup
		accountViewController = nil;
		accountDetailsToValidate = nil;
	}
}*/

- (void)saveCredentialWithUsername:(NSString *)user password:(NSString *)pass
{
	// Make credential
	NSURLCredential *credential = [NSURLCredential credentialWithUser:user password:pass persistence:NSURLCredentialPersistencePermanent];
	
	// Save credential to be used for protection space
	XSvcLog(@"Setting credential for user: %@", user);
	[[NSURLCredentialStorage sharedCredentialStorage] setCredential:credential forProtectionSpace:[self protectionSpace]];
}

- (void)removeAllCredentialsForProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{	
	NSDictionary *allCredentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:[self protectionSpace]];
	XSvcLog(@"Found %i credentials", [allCredentials count]);
	
	NSArray *allKeys = [allCredentials allKeys];
	
	for (NSString *username in allKeys)
	{
		XSvcLog(@"Removing credential for user: %@", username);
		NSURLCredential *credential = [allCredentials objectForKey:username];
		[[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:protectionSpace];
	}
}

- (NSURLProtectionSpace *)protectionSpace
{
	XServer *server = [self.localService activeServer];
	if (!server)
	{
		XSvcLog(@"No server found, protection space is nil");
		return nil;
	}
	
	return [[NSURLProtectionSpace alloc] initWithHost:server.hostname
												  port:[server.port integerValue]
											  protocol:server.protocol
												 realm:server.hostname
								  authenticationMethod:@"NSURLAuthenticationMethodHTTPBasic"];
}

- (NSURLCredential *)storedCredentialForProtectionSpace:(NSURLProtectionSpace *)protectionSpace withUser:(NSString *)user
{
	// Get all credentials for the protection space
	NSDictionary *allCredentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:[self protectionSpace]];
	if (![allCredentials count])
	{
		XSvcLog(@"No credentials were found for given protection space");
		return nil;
	}
	
	// Look for the credential with a key matching the passed username
	return [allCredentials objectForKey:user];
}

- (NSString *)username
{
	// Get all credentials for the protection space
	NSDictionary *allCredentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:[self protectionSpace]];
	
	if (![allCredentials count])
	{
		// None found
		XSvcLog(@"No username was found");
		return nil;
	}
	
	// Return the first username found
	NSArray *allKeys = [allCredentials allKeys];
	XSvcLog(@"First user found: %@", [allKeys objectAtIndex:0]);
	return [allKeys objectAtIndex:0];
}

#pragma mark - Directory

- (XDirectory *)directoryWithPath:(NSString *)path
{
	// Fire off remote directory fetch
	//[remoteService fetchDirectoryContentsAtPath:path withTarget:self action:@selector(updateDirectoryDetails:)];
	
	// Return local directory object
	return [self.localService directoryWithPath:path];
}

- (XDirectory *)updateDirectoryDetails:(NSDictionary *)details
{
	//XSvcLog(@"Updating directory details at path: %@", [details objectForKey:@"path"]);
	
	// Get directory
	XDirectory *directory = [self.localService directoryWithPath:[details objectForKey:@"path"]];
	NSSet *localEntries = [directory contents];
	
	// Go through contents and create a set of remote entries (entries that don't exist are created on the fly)
	NSMutableSet *remoteEntries = [[NSMutableSet alloc] init];
	NSArray *contents = [details objectForKey:@"contents"];
	for (NSDictionary *entryFromJson in contents)
	{
		// Describe object
		//XSvcLog(@"type: %@ path: %@", [entryFromJson objectForKey:@"type"], [entryFromJson objectForKey:@"path"]);
		
		XEntry *entry = nil;
		if ([[entryFromJson objectForKey:@"type"] isEqualToString:@"folder"])
			entry = [self.localService directoryWithPath:[entryFromJson objectForKey:@"path"]];
		else
			entry = [self.localService fileWithPath:[entryFromJson objectForKey:@"path"]];
		entry.parent = directory;
		[remoteEntries addObject:entry];
	}
	
	// Look for entries that no longer exist on server and need to be deleted
	for (XEntry *entry in localEntries) {
		if (![remoteEntries containsObject:entry]) {
			XSvcLog(@"Entry %@ no longer exists on server; deleting...", entry.path);
		}
	}
	
	// Update directory's contents with set of entries from server
	[directory setContents:remoteEntries];
	
	// Save changes
	NSError *error = nil;
	if ([[self.localService managedObjectContext] save:&error])
	{
		//XSvcLog(@"Successfully updated directory: %@", directory.path);
	}
	else
	{
		XSvcLog(@"Error: problem saving changes to directory: %@", directory.path);
	}
	
	return directory;
}



#pragma mark - CGChallengeResponseDelegate

- (void)respondToAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge forHandler:(CGAuthenticationChallengeHandler *)challengeHandler
{
	if (validateCredential)
	{
		[challengeHandler stopWithCredential:validateCredential];
	}
}



@end





















