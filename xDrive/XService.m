//
//  XService.m
//  xDrive
//
//  Created by Chris Gibbs on 7/1/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//


#import "XService.h"
#import "XDriveConfig.h"
#import "XDefaultPath.h"
#import "DefaultPathController.h"
#import "DTAsyncFileDeleter.h"
#import "NSString+DTPaths.h"
#import "NSString+DTFormatNumbers.h"
#import "UpdateDirectoryOperation.h"
#import "DirectoryContentsViewController.h"


@interface XService()
@property (nonatomic, strong) NSMutableDictionary *_directoryUpdates;
@property (nonatomic, strong) NSOperationQueue *_operationQueue;
@property (nonatomic, strong) NSDictionary *_iconTypes;

@end


@implementation XService

// Private
@synthesize _directoryUpdates;
@synthesize _operationQueue;
@synthesize _iconTypes;

// Public
@synthesize localService = _localService;
@synthesize remoteService = _remoteService;
@synthesize documentsPath = _documentsPath;
@synthesize cachesPath = _cachesPath;



#pragma mark - Initialization

+ (XService *)sharedXService
{
	static dispatch_once_t onceToken;
	static XService *__sharedXService;
	
	dispatch_once(&onceToken, ^{
		__sharedXService = [[self alloc] init];	
	});
	
	return __sharedXService;
}

- (id)init
{
    self = [super init];
    if (self)
	{
		// Init local and remote services
		_localService = [[XServiceLocal alloc] init];
		_remoteService = [[XServiceRemote alloc] initWithServer:_localService.server];
		_directoryUpdates = [[NSMutableDictionary alloc] init];
		_operationQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}



#pragma mark - Accessors

- (NSString *)documentsPath
{
	if (!_documentsPath)
	{
		_documentsPath = [[NSString documentsPath] stringByAppendingPathComponent:_localService.server.hostname];
	}
	return _documentsPath;
}

- (NSString *)cachesPath
{
	if (!_cachesPath)
	{
		_cachesPath = [[NSString cachesPath] stringByAppendingPathComponent:_localService.server.hostname];
	}
	return _cachesPath;
}



#pragma mark - Directory Updates

- (void)updateDirectory:(XDirectory *)directory forContentsViewController:(DirectoryContentsViewController *)viewController
{
	NSMutableDictionary *directoryUpdate = nil;
	if ([_directoryUpdates objectForKey:directory.path])
	{
		// Add view controller to existing update for specified directory
		directoryUpdate = [_directoryUpdates objectForKey:directory.path];
		[[directoryUpdate objectForKey:@"viewControllers"] addObject:viewController];
		return;
	}
	directoryUpdate = [[NSMutableDictionary alloc] init];
	
	// View controller
	NSMutableArray *viewControllers = [[NSMutableArray alloc] initWithObjects:viewController, nil];
	[directoryUpdate setObject:viewControllers forKey:@"viewControllers"];
	
	// Remote service
	XServiceRemote *remoteService = [[XServiceRemote alloc] initWithServer:[_localService server]];
	remoteService.failureBlock = ^(NSError *error){
		[self updateDirectoryAtPath:directory.path failedWithError:error];
	};
	[directoryUpdate setObject:remoteService forKey:@"remoteService"];
	
	// Start fetch
	[remoteService fetchEntryDetailsAtPath:directory.path withCompletionBlock:^(id result) {
		[self receivedDirectoryDetails:(NSDictionary *)result];
	}];
	
	// Store update
	[_directoryUpdates setObject:directoryUpdate forKey:directory.path];
}

- (void)receivedDirectoryDetails:(NSDictionary *)details
{
	NSString *path = [details objectForKey:@"path"];
	XDrvDebug(@"Received entry details for path %@", path);
	NSMutableDictionary *directoryUpdate = [_directoryUpdates objectForKey:path];
	
	// Remove remote service
	[directoryUpdate removeObjectForKey:@"remoteService"];
	
	// Update operation
	UpdateDirectoryOperation *operation = [[UpdateDirectoryOperation alloc] initWithDetails:details forDirectoryAtPath:path];
	[_operationQueue addOperation:operation];
}

- (void)didFinishUpdatingDirectoryAtPath:(NSString *)path
{
	XDrvDebug(@"Operation finished udpating directory details at path %@", path);
	NSMutableDictionary *directoryUpdate = [_directoryUpdates objectForKey:path];
	for (DirectoryContentsViewController *viewController in [directoryUpdate objectForKey:@"viewControllers"])
	{
		[viewController updateDirectoryStatus:DirectoryContentUpdateFinished];
	}
	[_directoryUpdates removeObjectForKey:path];
}

- (void)updateDirectoryAtPath:(NSString *)path failedWithError:(NSError *)error
{
	XDrvLog(@"Error: Update entry failed: %@", error);
	NSMutableDictionary *directoryUpdate = [_directoryUpdates objectForKey:path];
	for (DirectoryContentsViewController *viewController in [directoryUpdate objectForKey:@"viewControllers"])
	{
		[viewController updateDirectoryStatus:DirectoryContentUpdateFailed];
	}
	[_directoryUpdates removeObjectForKey:path];
}



#pragma mark - Caching

- (void)clearCacheWithCompletionBlock:(void (^)(NSError *error))completionBlock
{
	// Remove cache directory
	XDrvDebug(@"Removing entire cache directory");
	[[DTAsyncFileDeleter sharedInstance] removeItemAtPath:[self cachesPath]];
	
	// Reset cached amount
	[XDriveConfig setTotalCachedBytes:0];
	
	// Clear lastAccessed for any cached files
	NSArray *cachedFiles = [_localService cachedFilesOrderedByLastAccessAscending:YES];
	[cachedFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		((XFile *)obj).lastAccessed = nil;
	}];
	
	// Save
	[_localService saveWithCompletionBlock:completionBlock];
}

- (void)cacheFile:(XFile *)file fromTmpPath:(NSString *)tmpPath
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:[file cachePath]])
	{
		// Remove existing cache file
		[self removeCacheForFile:file];
	}
	
	// Get new file size
	NSError *error = nil;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:tmpPath error:&error];
	if (error)
	{
		XDrvLog(@"Problem getting attributes of file at path: %@", tmpPath);
		XDrvLog(@"%@", error);
		return;
	}
	
	long long fileSize = [[fileAttributes objectForKey:NSFileSize] longLongValue];
	XDrvDebug(@"Adding %lld bytes to total cache size", fileSize);
	[XDriveConfig setTotalCachedBytes:[XDriveConfig totalCachedBytes] + fileSize];
	XDrvDebug(@"New total cache size: %@", [NSString stringByFormattingBytes:[XDriveConfig totalCachedBytes]]);
	
	// Move file to permanent home
	[self moveFileAtPath:tmpPath toPath:[file cachePath]];
}

- (void)removeCacheForEntry:(XEntry *)entry
{
	if ([entry isKindOfClass:[XDirectory class]])
		[self removeCacheForDirectory:(XDirectory *)entry];
	else
		[self removeCacheForFile:(XFile *)entry];
}

- (void)removeCacheForFile:(XFile *)file
{
	// Get existing file size
	NSError *error = nil;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[file cachePath] error:&error];
	if (error)
	{
		XDrvLog(@"Problem getting attributes of file at path: %@", [file cachePath]);
		XDrvLog(@"%@", error);
		return;
	}
	
	// Remove file size from total cached bytes
	long long fileSize = [[fileAttributes objectForKey:NSFileSize] longLongValue];
	XDrvDebug(@"Removing %lld bytes from total cache size", fileSize);
	[XDriveConfig setTotalCachedBytes:[XDriveConfig totalCachedBytes] - fileSize];
	
	// Sanity check
	if ([XDriveConfig totalCachedBytes] < 0) [XDriveConfig setTotalCachedBytes:0];
	XDrvDebug(@"New total cache size: %@", [NSString stringByFormattingBytes:[XDriveConfig totalCachedBytes]]);
	
	// Delete file
	[[DTAsyncFileDeleter sharedInstance] removeItemAtPath:[file cachePath]];
	
	// Remove lastAccessed for file
	file.lastAccessed = nil;
	
	// This type of change doesn't really need a completion callback
	//[_localService saveWithCompletionBlock:^(NSError *error) {}];
}

- (void)removeCacheForDirectory:(XDirectory *)directory
{
	for (XEntry *entry in directory.contents)
	{
		if ([entry isKindOfClass:[XDirectory class]])
		{
			[self removeCacheForDirectory:(XDirectory *)entry];
			
			XDrvDebug(@"Deleting cache dir %@", [entry cachePath]);
			[[DTAsyncFileDeleter sharedInstance] removeItemAtPath:[entry cachePath]];
		}
		else
		{
			if (((XFile *)entry).lastAccessed)
			{
				[self removeCacheForFile:(XFile *)entry];
			}
		}
	}
}

- (void)removeOldCacheUntilTotalCacheIsLessThanBytes:(long long)bytes
{
	if ([XDriveConfig totalCachedBytes] <= bytes)
	{
		XDrvDebug(@"Total cached bytes is already less than new max bytes");
		return;
	}
	
	XDrvLog(@"Removing cached files until cache is less than: %@", [NSString stringByFormattingBytes:bytes]);
	NSArray *cachedFiles = [_localService cachedFilesOrderedByLastAccessAscending:YES];
	[cachedFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		// Remove cached file
		[self removeCacheForFile:obj];
		
		// Check if cache is now less than specified bytes
		*stop = ([XDriveConfig totalCachedBytes] <= bytes);
	}];
}



#pragma mark - File

- (void)downloadFile:(XFile *)file withDelegate:(id<XServiceRemoteDelegate>)delegate;
{
	//[self.remoteService downloadFileAtPath:file.path ifModifiedSinceCachedDate:file.lastUpdated withDelegate:delegate];
	//[self.remoteService downloadFileAtPath:file.path withDelegate:delegate];
}

- (void)moveFileAtPath:(NSString *)oldFilePath toPath:(NSString *)newFilePath
{
	XDrvDebug(@"Moving file from path: %@ to path: %@", oldFilePath, newFilePath);
	NSError *error = nil;
	
	// Create destination directory(s)
	NSString *destinationDirPath = [newFilePath stringByDeletingLastPathComponent];
	BOOL dirExists = [[NSFileManager defaultManager] createDirectoryAtPath:destinationDirPath 
											   withIntermediateDirectories:YES 
																attributes:nil 
																	 error:&error];
	if (error || !dirExists)
	{
		XDrvLog(@"Problem creating destination directory: %@", error);
		return;
	}
	
	// Move file
	error = nil;
	if (![[NSFileManager defaultManager] moveItemAtPath:oldFilePath toPath:newFilePath error:&error])
	{
		XDrvLog(@"Problem moving file: %@", error);
	}
}



#pragma mark - Utils

- (NSString *)iconNameForEntryType:(NSString *)entryType
{
	if (!_iconTypes)
	{
		// Load icon mappings from plist
		_iconTypes = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"File-Types" ofType:@"plist"]] objectForKey:@"Icons"];
	}
	
	// First check for exact match
	NSString *iconName = [_iconTypes objectForKey:entryType];
	if (iconName)
	{
		return iconName;
	}
	
	// Match type category
	NSString *category = [[entryType componentsSeparatedByString:@"/"] objectAtIndex:0];
	iconName = [_iconTypes objectForKey:category];
	if (iconName)
	{
		return iconName;
	}
	
	// Use default
	return [_iconTypes objectForKey:@"default"];
}


@end





















