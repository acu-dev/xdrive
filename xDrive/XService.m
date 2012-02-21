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





@interface XService()

@property (nonatomic, strong) NSString *_documentsPath, *_cachesPath;
	// Documents/caches path with the active server hostname appended

@end







@implementation XService

// Public
@synthesize localService = _localService;
@synthesize remoteService = _remoteService;

// Private
@synthesize _documentsPath, _cachesPath;



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
		_remoteService = [[XServiceRemote alloc] initWithServer:[self.localService activeServer]];
    }
    return self;
}



#pragma mark - Accessors

- (XServer *)activeServer
{
	return [self.localService activeServer];
}

- (NSString *)documentsPath
{
	if (!_documentsPath)
	{
		_documentsPath = [[NSString documentsPath] stringByAppendingPathComponent:[self activeServer].hostname];
	}
	return _documentsPath;
}

- (NSString *)cachesPath
{
	if (!_cachesPath)
	{
		_cachesPath = [[NSString cachesPath] stringByAppendingPathComponent:[self activeServer].hostname];
	}
	return _cachesPath;
}



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
	
	// Get directory
	XDirectory *directory = [self.localService directoryWithPath:[details objectForKey:@"path"]];
	
	// Directory's last updated time from server
	NSTimeInterval lastUpdatedSeconds = [[details objectForKey:@"lastUpdated"] doubleValue] / 1000;
	NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdatedSeconds];
	if (directory.contentsLastUpdated)
	{
		if ([directory.contentsLastUpdated isEqualToDate:lastUpdated])
		{
			// Directory has not been updated since last fetch; nothing else to do
			XDrvDebug(@"Directory has not been updated; using cached object for dir: %@", directory.path);
			return directory;
		}
	}
	XDrvDebug(@"Directory has changes; updating contents for dir: %@", directory.path);
	directory.contentsLastUpdated = lastUpdated;
	
	// Go through contents and create a set of remote entries (entries that don't exist are created on the fly)
	NSMutableSet *remoteEntries = [[NSMutableSet alloc] init];
	NSArray *contents = [details objectForKey:@"contents"];
	for (NSDictionary *entryFromJson in contents)
	{
		// Create/get object for each entry in contents
		XEntry *entry = nil;
		if ([[entryFromJson objectForKey:@"type"] isEqualToString:@"folder"])
		{
			// Folder
			entry = [self.localService directoryWithPath:[entryFromJson objectForKey:@"path"]];
		}
		else
		{
			// File
			XFile *file = [self.localService fileWithPath:[entryFromJson objectForKey:@"path"]];
			file.type = [entryFromJson objectForKey:@"type"];
			file.size = [entryFromJson objectForKey:@"size"];
			file.sizeDescription = [NSString stringByFormattingBytes:[file.size integerValue]];
			entry = file;
		}
		
		// Dates (times come from xservice in milliseconds since epoch)
		NSTimeInterval createdSeconds = [[entryFromJson objectForKey:@"created"] doubleValue] / 1000;
		NSTimeInterval lastUpdatedSeconds = [[entryFromJson objectForKey:@"lastUpdated"] doubleValue] / 1000;
		entry.created = [NSDate dateWithTimeIntervalSince1970:createdSeconds];
		entry.lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdatedSeconds];

		// Common attributes
		entry.creator = [entryFromJson objectForKey:@"creator"];
		entry.lastUpdator = [entryFromJson objectForKey:@"lastUpdator"];
		entry.parent = directory;
		[remoteEntries addObject:entry];
	}
	
	// Entries to delete
	for (XEntry *entry in [directory contents])
	{
		if (![remoteEntries containsObject:entry])
		{
			// Entry does not exist in contents returned from server; needs to be deleted
			
			if ([entry isKindOfClass:[XDirectory class]])
			{
				XDrvDebug(@"Directory %@ no longer exists on server; deleting...", entry.path);
			}
			else
			{
				
			}
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
	//[self.remoteService downloadFileAtPath:file.path ifModifiedSinceCachedDate:file.lastUpdated withDelegate:delegate];
	[self.remoteService downloadFileAtPath:file.path withDelegate:delegate];
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



#pragma mark - Cache

- (void)clearCache
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
	NSError *error = nil;
	if (![[_localService managedObjectContext] save:&error])
	{
		XDrvLog(@"Problem saving context: %@", error);
	}
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
	if (![[_localService managedObjectContext] save:&error])
	{
		XDrvLog(@"Problem saving context: %@", error);
	}
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
			[self removeCacheForFile:(XFile *)entry];
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


@end





















