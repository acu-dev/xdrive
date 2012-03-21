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



@interface DefaultPathController() <XServiceRemoteDelegate>

/**
 Controller to receive status notifications.
 */
@property (nonatomic, weak) SetupController *_setupController;

/**
 Server object to fetch default paths from.
 */
@property (nonatomic, strong) XServer *_server;

/**
 The list of default paths to configure.
 */
@property (nonatomic, strong) NSMutableArray *_defaultPathsList;

/**
 Root directory update operation. Required before any other operations fire off.
 */
@property (nonatomic, strong) UpdateDirectoryOperation *_rootUpdateDirectoryOperation;

/**
 Counter used to track active fetches.
 */
@property (nonatomic, assign) int _activeFetchCount;

/**
 Maintains a map of icon file names and which default path they belong to.
 */
@property (nonatomic, strong) NSMutableDictionary *_iconToPathMap;


- (void)receiveDefaultPathsList:(NSArray *)defaultPathsList;
	// Creates an XDefaultPath object for each path returned and attaches them to the server

//- (void)receiveDefaultPathDetails:(NSDictionary *)details;
	// Creates the default path directory and associates it with the XDefaultPath object

- (void)receiveDefaultPathIcon:(NSString *)tmpFilePath;
	// Moves the icon file to a permanent home and sets the path on the XDefaultPath object

- (XDefaultPath *)defaultPathWithPath:(NSString *)path;
	// Searches the XDefaultPath objects for one that matches the given path

- (NSString *)contextURLString;
	// Generates a URL to the configured server's context

@end




@implementation DefaultPathController

@synthesize _setupController;
@synthesize _server;
@synthesize _defaultPathsList;
@synthesize _rootUpdateDirectoryOperation;
@synthesize _activeFetchCount;
@synthesize _iconToPathMap;



#pragma mark - Initializing

- (id)initWithSetupController:(SetupController *)setupController
{
	self = [super init];
	if (!self) return nil;
	
	_setupController = setupController;

	return self;
}



#pragma mark - Default Paths

- (void)fetchDefaultPathsForServer:(XServer *)server
{
	_server	= server;
	
	// Get the list of default paths
	NSString *msg = NSLocalizedStringFromTable(@"Downloading defaults...",
											   @"XDrive",
											   @"Message displayed during setup while default paths are being downloaded.");
	[_setupController defaultPathsStatusUpdate:msg];
	[[XService sharedXService].remoteService fetchDefaultPathsForServer:_server withDelegate:self];
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
		directory.server = _server;
		
		// Create default path object
		XDefaultPath *defaultPath = [[XService sharedXService].localService createDefaultPathAtPath:[defaultPathDetails objectForKey:@"path"]
															   withName:[defaultPathDetails objectForKey:@"name"]];
		defaultPath.directory = directory;
		
		// Add default path to server
		[_server addDefaultPathsObject:defaultPath];
	}
		
	// Add standard tab bar items and save order
	[tabBarOrder addObject:@"Recent"];
	[tabBarOrder addObject:@"Settings"];
	[XDriveConfig saveTabItemOrder:tabBarOrder];
	
	// All done
	[_setupController defaultPathsValidated];
}



#pragma mark - Default Path Contents

- (void)initializeDefaultPaths
{
	// Get the root directory contents
	/*XDrvDebug(@"Updating root directory contents");
	_rootUpdateDirectoryOperation = [[UpdateDirectoryOperation alloc] initWithDirectoryPath:@"/"];
	__block typeof(self) bself = self;
	[_rootUpdateDirectoryOperation setCompletionBlock:^{
		[bself didFinishActiveFetch];
	}];
	[_rootUpdateDirectoryOperation start];*/
	
	// Map to associate fetched icons with their default path
	_iconToPathMap = [[NSMutableDictionary alloc] init];
	
	// Start downloading icons for each default path
	for (NSDictionary *defaultPath in _defaultPathsList)
	{
		// List of icons to download
		NSArray *iconNames = [NSArray arrayWithObjects:@"icon", @"icon@2x", nil];
		
		[iconNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
			NSString *iconPath = [defaultPath objectForKey:[iconNames objectAtIndex:idx]];
			if (iconPath)
			{
				// Get the default path's icon
				iconPath = [[self contextURLString] stringByAppendingString:iconPath];
				XDrvDebug(@"Fetching icon: %@", iconPath);
				[[XService sharedXService].remoteService downloadFileAtAbsolutePath:iconPath ifModifiedSinceCachedDate:nil withDelegate:self];
				[_iconToPathMap setObject:[defaultPath objectForKey:@"path"] forKey:[iconPath lastPathComponent]];
				_activeFetchCount++;
			}
		}];
	}
}

- (void)didFinishActiveFetch
{
	_activeFetchCount--;
	if (!_activeFetchCount)
	{
		// All done getting default paths; notify delegate
		[_setupController defaultPathsFinished];
	}
	else
	{
		XDrvLog(@"%i active fetches remaining", _activeFetchCount);
	}
}

- (void)receiveDefaultPathIcon:(NSString *)tmpFilePath
{
	// Move file to permanent home
	NSString *fileName = [tmpFilePath lastPathComponent];
	NSString *newFilePath = [[[[XService sharedXService] documentsPath] stringByAppendingString:@"-meta/icons"] 
							 stringByAppendingPathComponent:fileName];
	[[XService sharedXService] moveFileAtPath:tmpFilePath toPath:newFilePath];
	
	// Set icon path
	NSString *path = [_iconToPathMap objectForKey:fileName];
	if (path)
	{
		XDefaultPath *defaultPath = [self defaultPathWithPath:path];
		XDrvDebug(@"Attaching icon %@ to default path %@", newFilePath, defaultPath.path);
		defaultPath.icon = newFilePath;
	}

	// This fetch is finished
	[self didFinishActiveFetch];
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

- (NSString *)contextURLString
{
	return [NSString stringWithFormat:@"%@://%@:%i%@",
			_server.protocol,
			_server.hostname,
			[_server.port intValue],
			_server.context];
}



#pragma mark - XServiceRemoteDelegate

- (void)connectionFinishedWithResult:(NSObject *)result
{
	if (!_server)
	{
		// A connection failed and we're in a reset state; do nothing
		return;
	}
	
	
	if (_activeFetchCount == 0 && [result isKindOfClass:[NSArray class]])
	{
		// List of default paths
		[self receiveDefaultPathsList:(NSArray *)result];
	}
	else if ([result isKindOfClass:[NSString class]])
	{
		// Handle icon file
		[self receiveDefaultPathIcon:(NSString *)result];
	}
	else
	{
		// No idea what this is
		XDrvLog(@"Unrecognized result: %@", result);
	}
}

- (void)connectionFailedWithError:(NSError *)error
{
	XDrvLog(@"Connection failed: %@", error);
	
	// Update view
	[_setupController defaultPathsFailedWithError:error];
	
	// Reset
	_defaultPathsList = nil;
	_activeFetchCount = 0;
	_setupController = nil;
	_server = nil;
}


@end










