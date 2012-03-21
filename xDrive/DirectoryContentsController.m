//
//  DirectoryContentsController.m
//  xDrive
//
//  Created by Chris Gibbs on 3/20/12.
//  Copyright (c) 2012 Meld Apps. All rights reserved.
//

#import "DirectoryContentsController.h"
#import "XDriveConfig.h"
#import "UpdateDirectoryOperation.h"
#import "NSString+DTFormatNumbers.h"


@interface DirectoryContentsController()

@property (nonatomic, weak) XDirectory *_directory;
@property (nonatomic, weak) DirectoryContentsViewController *_viewController;
@property (nonatomic, strong) UpdateDirectoryOperation *_updateDirectoryOperation;

@end


@implementation DirectoryContentsController

@synthesize _directory;
@synthesize _viewController;
@synthesize _updateDirectoryOperation;



#pragma mark - Initialization

- (id)initWithDirectory:(XDirectory *)directory forViewController:(DirectoryContentsViewController *)viewController
{
	self = [super init];
	if (!self) return nil;
	
	_directory = directory;
	_viewController = viewController;
	
	return self;
}



#pragma mark - Fetch Directory Contents

- (void)updateDirectoryContents
{
	[_viewController updateDirectoryStatus:DirectoryContentFetching];
	[[XService sharedXService].remoteService fetchDirectoryContentsAtPath:_directory.path withDelegate:self];
}

- (void)evaluateFetchedDirectoryDetails:(NSDictionary *)fetchedDirectoryDetails
{
	// Evaluate cached directory's last update time against server directory's last update time
	NSTimeInterval lastUpdatedSeconds = [[fetchedDirectoryDetails objectForKey:@"lastUpdated"] doubleValue] / 1000;
	NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdatedSeconds];
	if (_directory.contentsLastUpdated)
	{
		if ([_directory.contentsLastUpdated isEqualToDate:lastUpdated])
		{
			// Directory has not been updated; use cached directory
			XDrvDebug(@"%@ :: Directory has not been updated; using cached directory", _directory.path);
			[_viewController updateDirectoryStatus:DirectoryContentCached];
			return;
		}
	}
	
	dispatch_async(UpdateOperationQueue, ^{
		[self updateDirectoryWithDetails:fetchedDirectoryDetails];
	});
}


#pragma mark - Update Directory Contents

- (void)updateDirectoryWithDetails:(NSDictionary *)details
{
	// Create new service with it's own context for background operation
	XDrvDebug(@"%@ :: Creating new service for background operation", [details objectForKey:@"path"]);
	XServiceLocal *localService = [[XService sharedXService].localService newServiceForOperation];
	
	// Get directory
	XDrvDebug(@"%@ :: Fetching directory object from local service", [details objectForKey:@"path"]);
	XDirectory *directory = [localService directoryWithPath:[details objectForKey:@"path"]];
	
	// Update last updated time (times come from details in milliseconds since epoch)
	NSTimeInterval lastUpdatedSeconds = [[details objectForKey:@"lastUpdated"] doubleValue] / 1000;
	NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdatedSeconds];
	directory.lastUpdated = lastUpdated;
	directory.contentsLastUpdated = [NSDate date];
	
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
			entry = [localService directoryWithPath:[entryFromJson objectForKey:@"path"]];
		}
		else
		{
			// File
			XFile *file = [localService fileWithPath:[entryFromJson objectForKey:@"path"]];
			file.type = [entryFromJson objectForKey:@"type"];
			file.size = [entryFromJson objectForKey:@"size"];
			file.sizeDescription = [NSString stringByFormattingBytes:[file.size integerValue]];
			entry = file;
		}
		// Common attributes
		NSTimeInterval createdSeconds = [[entryFromJson objectForKey:@"created"] doubleValue] / 1000;
		NSTimeInterval lastUpdatedSeconds = [[entryFromJson objectForKey:@"lastUpdated"] doubleValue] / 1000;
		entry.created = [NSDate dateWithTimeIntervalSince1970:createdSeconds];
		entry.lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdatedSeconds];
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
			XDrvDebug(@"%@ :: Content entry %@ no longer exists on server; removing cache and entry from local store", directory.path, entry.path);
			
			if ([entry isKindOfClass:[XDirectory class]])
			{
				[[XService sharedXService] removeCacheForDirectory:(XDirectory *)entry];
			}
			else
			{
				[[XService sharedXService] removeCacheForFile:(XFile *)entry];
			}
			[localService removeEntry:entry];
		}
	}
	
	// Update directory's contents with set of entries from server
	[directory setContents:remoteEntries];
	
	// Save changes
	[localService saveWithCompletionBlock:^(NSError *error) {
		if (error)
		{
			XDrvLog(@"%@ :: Error: Problem saving local context: %@", directory.path, error);
			//dispatch_async(dispatch_get_main_queue(), ^{
				[self directoryUpdateFailedWithError:error];
			//});
		}
		else
		{
			XDrvDebug(@"%@ :: Saved local context", directory.path);
			//dispatch_async(dispatch_get_main_queue(), ^{
				[self directoryUpdateDidFinish];
			//});
		}
	}];
}

- (void)directoryUpdateDidFinish
{
	XDrvDebug(@"%@ :: Update finished", _directory.path);
	[_viewController updateDirectoryStatus:DirectoryContentUpdateFinished];
}

- (void)directoryUpdateFailedWithError:(NSError *)error
{
	XDrvLog(@"%@ :: Update failed: %@", _directory.path, error);
	[_viewController updateDirectoryStatus:DirectoryContentUpdateFailed];
}



#pragma mark - XServiceRemoteDelegate

- (void)connectionFinishedWithResult:(NSObject *)result
{
	if ([result isKindOfClass:[NSDictionary class]])
	{
		[self evaluateFetchedDirectoryDetails:(NSDictionary *)result];		
	}
	else
	{
		XDrvLog(@"%@ :: Connection returned unexpected result: %@", _directory.path, result);
		[_viewController updateDirectoryStatus:DirectoryContentFetchFailed];
	}
}

- (void)connectionFailedWithError:(NSError *)error
{
	XDrvLog(@"%@ :: Connection failed: %@", _directory.path, error);
	[_viewController updateDirectoryStatus:DirectoryContentFetchFailed];
}


@end








