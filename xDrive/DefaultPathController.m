//
//  XDefaultPathController.m
//  xDrive
//
//  Created by Chris Gibbs on 9/22/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "DefaultPathController.h"
#import "XDriveConfig.h"
#import "XDefaultPath.h"
#import "UpdateDirectoryOperation.h"



@interface DefaultPathController()

@property (nonatomic, weak) SetupController *_setupController;
@property (nonatomic, strong) XServiceRemote *_remoteService;
@property (nonatomic, strong) NSMutableArray *_defaultPathsList;
@property (nonatomic, strong) UpdateDirectoryOperation *_rootUpdateDirectoryOperation;
@property (nonatomic, assign) int _fetchCount;
@property (nonatomic, strong) NSMutableArray *_iconsToDownload;
@property (nonatomic, strong) NSMutableArray *_iconDownloads;


- (void)receiveDefaultPathsList:(NSArray *)defaultPathsList;
	// Creates an XDefaultPath object for each path returned and attaches them to the server

//- (void)receiveDefaultPathDetails:(NSDictionary *)details;
	// Creates the default path directory and associates it with the XDefaultPath object

//- (void)receiveDefaultPathIcon:(NSString *)tmpFilePath;
	// Moves the icon file to a permanent home and sets the path on the XDefaultPath object

- (XDefaultPath *)defaultPathWithPath:(NSString *)path;
	// Searches the XDefaultPath objects for one that matches the given path



@end




@implementation DefaultPathController

@synthesize _setupController;
@synthesize _remoteService;
@synthesize _defaultPathsList;
@synthesize _rootUpdateDirectoryOperation;
@synthesize _fetchCount;
@synthesize _iconsToDownload;
@synthesize _iconDownloads;



#pragma mark - Initializing

- (id)initWithController:(SetupController *)setupController
{
	self = [super init];
	if (!self) return nil;
	
	_setupController = setupController;

	return self;
}



#pragma mark - Default Paths

- (void)fetchDefaultPaths
{	
	// Get the list of default paths
	NSString *msg = NSLocalizedStringFromTable(@"Downloading defaults...",
											   @"XDrive",
											   @"Message displayed during setup while default paths are being downloaded.");
	[_setupController defaultPathsStatusUpdate:msg];
	
	_remoteService = [[XServiceRemote alloc] initWithServer:_setupController.server];

	_remoteService.authenticationChallengeBlock = ^ NSURLCredential * (NSURLAuthenticationChallenge *challenge){
		return [NSURLCredential credentialWithUser:_setupController.validateUser password:_setupController.validatePass persistence:NSURLCredentialPersistenceNone];
	};
	
	__block typeof(_setupController) bSetupController = _setupController;
	_remoteService.failureBlock = ^(NSError *error) {
		XDrvLog(@"Error encountered: %@", error);
		[bSetupController defaultPathsFailedWithError:error];
	};
	
	[_remoteService fetchDefaultPathsWithCompletionBlock:^(id result) {
		[self receiveDefaultPathsList:result];
	}];
}

- (void)receiveDefaultPathsList:(NSArray *)defaultPathsList
{
	XDrvDebug(@"Got default paths");
	_defaultPathsList = [[NSMutableArray alloc] init];
	NSMutableArray *tabBarOrder = [[NSMutableArray alloc] init];
	
	for (NSDictionary *item in defaultPathsList)
	{
		NSMutableDictionary *defaultPathDetails = [[NSMutableDictionary alloc] initWithDictionary:item];
		
		// Save path order
		[tabBarOrder addObject:[defaultPathDetails objectForKey:@"name"]];
		
		// Replace user placeholder in paths
		[defaultPathDetails setValue:[[defaultPathDetails objectForKey:@"path"] stringByReplacingOccurrencesOfString:@"${user}" withString:_setupController.validateUser] forKey:@"path"];
		[_defaultPathsList addObject:defaultPathDetails];
		
		// Create default path directory object
		XDirectory *directory = [[XService sharedXService].localService directoryWithPath:[defaultPathDetails objectForKey:@"path"]];
		directory.server = _setupController.server;
		
		// Create default path object
		XDefaultPath *defaultPath = [[XService sharedXService].localService createDefaultPathAtPath:[defaultPathDetails objectForKey:@"path"]
															   withName:[defaultPathDetails objectForKey:@"name"]];
		defaultPath.directory = directory;
		
		// Add default path to server
		[_setupController.server addDefaultPathsObject:defaultPath];
	}
		
	// Add standard tab bar items and save order
	[tabBarOrder addObject:@"Recent"];
	[tabBarOrder addObject:@"Settings"];
	[XDriveConfig saveTabItemOrder:tabBarOrder];
	
	// All done
	[_setupController defaultPathsValidated];
}



#pragma mark - Default Path Icons

- (void)initializeDefaultPaths
{	
	_iconDownloads = [[NSMutableArray alloc] init];
	
	for (NSDictionary *defaultPathDetails in _defaultPathsList)
	{
		if ([defaultPathDetails objectForKey:@"icon"])
		{
			[self downloadIconWithName:[defaultPathDetails objectForKey:@"icon"] forDefaultPath:[defaultPathDetails objectForKey:@"path"]];
		}
		if ([defaultPathDetails objectForKey:@"icon@2x"])
		{
			[self downloadIconWithName:[defaultPathDetails objectForKey:@"icon@2x"]];
		}
	}
}

- (void)downloadIconWithName:(NSString *)name forDefaultPath:(NSString *)path
{
	NSString *localPath = [self downloadIconWithName:name];
	
	// Set the icon path on the default path object
	XDefaultPath *defaultPath = [self defaultPathWithPath:path];
	defaultPath.icon = localPath;
}

- (NSString *)downloadIconWithName:(NSString *)name
{
	NSString *remotePath = [_setupController.server.context stringByAppendingString:name];
	NSString *localPath = [[[[XService sharedXService] documentsPath] stringByAppendingString:@"-meta/icons"] 
						   stringByAppendingPathComponent:name];
	
	XServiceRemote *remoteService = [[XServiceRemote alloc] initWithServer:_setupController.server];
	[_iconDownloads addObject:remoteService];
	
	_fetchCount++;
	[remoteService downloadFileAtPath:remotePath ifModifiedSinceCachedDate:nil 
					  withUpdateBlock:^(float percentDownloaded) {} 
					  completionBlock:^(id result) {
						  NSString *tmpFilePath = (NSString *)result;
						  XDrvDebug(@"Icon finished downloading; tmp path: %@", tmpFilePath);
						  
						  // Move file to permanent home
						  [[XService sharedXService] moveFileAtPath:tmpFilePath toPath:localPath];
						  
						  [self iconDownloadFinished];
					  }];
	
	return localPath;
}

- (void)iconDownloadFinished
{
	_fetchCount--;
	if (!_fetchCount)
	{
		XDrvDebug(@"Last icon download finished");
		[_setupController defaultPathsFinished];
		_iconDownloads = nil;
		return;
	}
	XDrvDebug(@"Waiting for %i more icon downloads to finish", _fetchCount);
}



#pragma mark - Utils

- (XDefaultPath *)defaultPathWithPath:(NSString *)path
{
	XDefaultPath *defaultPath = nil;
	NSSet *defaultPaths = [[XService sharedXService].localService server].defaultPaths;
	for (XDefaultPath *dPath in defaultPaths)
	{
		if ([dPath.path isEqualToString:path])
		{
			defaultPath = dPath;
		}
	}
	return defaultPath;
}


@end










