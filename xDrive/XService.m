//
//  XService.m
//  xDrive
//
//  Created by Chris Gibbs on 7/1/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XService.h"
#import "XFileUtils.h"
#import "XDriveConfig.h"
#import "XDefaultPath.h"
#import "DefaultPathController.h"




@interface XService()

@property (nonatomic, strong) NSURLCredential *validateCredential;
	// Credential used when validating server info.

@property (nonatomic, strong) DefaultPathController *defaultPathController;

@property (nonatomic, assign) int fetchingDefaultPaths;
	// Counter that gets decremented as default path fetches return.

/*
- (void)saveCredentialWithUsername:(NSString *)user password:(NSString *)pass;
- (void)removeAllCredentialsForProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
- (NSURLProtectionSpace *)protectionSpace;
- (NSURLCredential *)storedCredentialForProtectionSpace:(NSURLProtectionSpace *)protectionSpace withUser:(NSString *)user;
*/
@end







@implementation XService

static XService *sharedXService;


@synthesize localService = _localService;
@synthesize remoteService = _remoteService;
@synthesize serverStatusDelegate;
@synthesize validateCredential;
@synthesize fetchingDefaultPaths;
@synthesize defaultPathController;


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
    }
    return self;
}



#pragma mark - Server

- (XServer *)activeServer
{
	return [self.localService activeServer];
}

- (NSString *)activeServerDocumentPath
{
	return [[XFileUtils applicationDocumentsDirectory] stringByAppendingPathComponent:[self activeServer].hostname];
}

- (NSString *)activeServerCachePath
{
	return [[XFileUtils applicationCachesDirectory] stringByAppendingPathComponent:[self activeServer].hostname];
}



#pragma mark - Credentials

/*- (void)saveCredentialWithUsername:(NSString *)user password:(NSString *)pass
{
	// Make credential
	NSURLCredential *credential = [NSURLCredential credentialWithUser:user password:pass persistence:NSURLCredentialPersistencePermanent];
	
	// Save credential to be used for protection space
	XDrvDebug(@"Setting credential for user: %@", user);
	[[NSURLCredentialStorage sharedCredentialStorage] setCredential:credential forProtectionSpace:[self protectionSpace]];
}

- (void)removeAllCredentialsForProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{	
	NSDictionary *allCredentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:[self protectionSpace]];
	XDrvDebug(@"Found %i credentials", [allCredentials count]);
	
	NSArray *allKeys = [allCredentials allKeys];
	
	for (NSString *username in allKeys)
	{
		XDrvDebug(@"Removing credential for user: %@", username);
		NSURLCredential *credential = [allCredentials objectForKey:username];
		[[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:protectionSpace];
	}
}

- (NSURLProtectionSpace *)protectionSpace
{
	XServer *server = [self.localService activeServer];
	if (!server)
	{
		XDrvLog(@"No server found, protection space is nil");
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
		XDrvLog(@"No credentials were found for given protection space");
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
		XDrvLog(@"No username was found");
		return nil;
	}
	
	// Return the first username found
	NSArray *allKeys = [allCredentials allKeys];
	XDrvDebug(@"First user found: %@", [allKeys objectAtIndex:0]);
	return [allKeys objectAtIndex:0];
}*/

#pragma mark - Directory

- (XDirectory *)directoryWithPath:(NSString *)path
{
	// Fire off remote directory fetch
	[self.remoteService fetchDirectoryContentsAtPath:path withTarget:self action:@selector(updateDirectoryDetails:)];
	
	// Return local directory object
	return [self.localService directoryWithPath:path];
}

- (XDirectory *)updateDirectoryDetails:(NSDictionary *)details
{
	if ([details isKindOfClass:[NSError class]])
	{
		XDrvLog(@"Error updating directory details: %@", details);
		return nil;
	}
	
	
	XDrvDebug(@"Updating directory details at path: %@", [details objectForKey:@"path"]);
	
	// Get directory
	XDirectory *directory = [self.localService directoryWithPath:[details objectForKey:@"path"]];
	NSSet *localEntries = [directory contents];
	
	// Go through contents and create a set of remote entries (entries that don't exist are created on the fly)
	NSMutableSet *remoteEntries = [[NSMutableSet alloc] init];
	NSArray *contents = [details objectForKey:@"contents"];
	for (NSDictionary *entryFromJson in contents)
	{
		// Describe object
		//XDrvDebug(@"type: %@ path: %@", [entryFromJson objectForKey:@"type"], [entryFromJson objectForKey:@"path"]);
		
		XEntry *entry = nil;
		if ([[entryFromJson objectForKey:@"type"] isEqualToString:@"folder"])
		{
			entry = [self.localService directoryWithPath:[entryFromJson objectForKey:@"path"]];
		}
		else
		{
			XFile *file = [self.localService fileWithPath:[entryFromJson objectForKey:@"path"]];
			file.type = [entryFromJson objectForKey:@"type"];
			file.size = [entryFromJson objectForKey:@"size"];
			entry = file;
		}
		entry.parent = directory;
		[remoteEntries addObject:entry];
	}
	
	// Look for entries that no longer exist on server and need to be deleted
	for (XEntry *entry in localEntries) {
		if (![remoteEntries containsObject:entry]) {
			XDrvDebug(@"Entry %@ no longer exists on server; deleting...", entry.path);
		}
	}
	
	// Update directory's contents with set of entries from server
	[directory setContents:remoteEntries];
	
	// Save changes
	NSError *error = nil;
	if ([[_localService managedObjectContext] save:&error])
	{
		XDrvDebug(@"Successfully updated directory: %@", directory.path);
	}
	else
	{
		XDrvLog(@"Error: problem saving changes to directory: %@", directory.path);
	}
	
	return directory;
}



#pragma mark - File

- (void)downloadFile:(XFile *)file withDelegate:(id<XServiceRemoteDelegate>)delegate;
{
	[self.remoteService downloadFileAtPath:file.path withDelegate:delegate];
}


@end





















