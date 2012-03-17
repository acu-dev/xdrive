//
//  UpdateDirectoryOperation.m
//  xDrive
//
//  Created by Chris Gibbs on 3/6/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "UpdateDirectoryOperation.h"
#import "XDriveConfig.h"
#import "NSString+DTFormatNumbers.h"


@interface UpdateDirectoryOperation ()
@property (nonatomic, strong) NSString *_directoryPath;
@property (nonatomic, strong) XServiceLocal *_localService;

- (void)updateDirectoryInBackgroundWithDetails:(NSDictionary *)details;
- (void)updateDirectoryWithDetails:(NSDictionary *)details;

@end


@implementation UpdateDirectoryOperation

// Private
@synthesize _directoryPath;
@synthesize _localService;

// Public
@synthesize state = _state;


- (id)initWithDirectoryPath:(NSString *)path
{
    self = [super init];
    if (!self) return nil;
	
	_directoryPath = path;
    _state = DirectoryOperationReadyState;
	
    return self;
}



#pragma mark - Update Directory

- (void)updateDirectoryInBackgroundWithDetails:(NSDictionary *)details
{
	_state = DirectoryOperationUpdatingState;
	
	dispatch_queue_t updateQueue = dispatch_queue_create("edu.acu.xdrive.updateDirectory", 0);
	dispatch_async(updateQueue, ^{
		[self updateDirectoryWithDetails:details];
	});
	
	dispatch_release(updateQueue);
}

- (void)updateDirectoryWithDetails:(NSDictionary *)details
{
	// Create new service
	_localService = [[XService sharedXService].localService newServiceForOperation];
	
	// Get directory
	XDirectory *directory = [_localService directoryWithPath:[details objectForKey:@"path"]];
	
	// Directory's last updated time from server
	NSTimeInterval lastUpdatedSeconds = [[details objectForKey:@"lastUpdated"] doubleValue] / 1000;
	NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdatedSeconds];
	if (directory.contentsLastUpdated)
	{
		if ([directory.contentsLastUpdated isEqualToDate:lastUpdated])
		{
			// Directory has not been updated since last fetch; nothing else to do
			XDrvDebug(@"Directory has not been updated; using cached object for dir: %@", directory.path);
			return;
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
			entry = [_localService directoryWithPath:[entryFromJson objectForKey:@"path"]];
		}
		else
		{
			// File
			XFile *file = [_localService fileWithPath:[entryFromJson objectForKey:@"path"]];
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
			XDrvDebug(@"Entry %@ no longer exists on server; deleting...", entry.path);
			
			if ([entry isKindOfClass:[XDirectory class]])
			{
				[[XService sharedXService] removeCacheForDirectory:(XDirectory *)entry];
			}
			else
			{
				[[XService sharedXService] removeCacheForFile:(XFile *)entry];
			}
			[_localService removeEntry:entry];
		}
	}
	
	// Update directory's contents with set of entries from server
	[directory setContents:remoteEntries];
	
	// Save changes
	[_localService saveWithCompletionBlock:^(NSError *error) {
		if (error)
		{
			XDrvLog(@"Error: Problem saving local context for %@", directory.path);
			_state = DirectoryOperationFailedState;
		}
		else
		{
			XDrvDebug(@"Saved local context for %@", directory.path);
			_state = DirectoryOperationFinishedState;
		}
		
		// Run finish on main queue
		dispatch_async(dispatch_get_main_queue(), ^{
			[self finish];
		});
	}];
}






#pragma mark - NSOperation

- (BOOL)isReady
{
    return _state == DirectoryOperationReadyState && [super isReady];
}

- (BOOL)isExecuting
{
    return _state == DirectoryOperationFetchingState || _state == DirectoryOperationUpdatingState;
}

- (BOOL)isFinished
{
    return _state == DirectoryOperationFinishedState;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (void)start
{
    if ([self isReady])
	{
		XDrvDebug(@"Starting directory update operation for %@", _directoryPath);
        _state = DirectoryOperationFetchingState;
		[[XService sharedXService].remoteService fetchDirectoryContentsAtPath:_directoryPath withDelegate:self];
    }
	else
	{
		XDrvLog(@"Directory update operation was not initialized properly");
	}
}

- (void)finish
{
	self.completionBlock();
}



#pragma mark - XServiceRemoteDelegate

- (void)connectionFinishedWithResult:(NSObject *)result
{
	if ([result isKindOfClass:[NSDictionary class]])
	{
		XDrvDebug(@"Directory fetch finished for %@", _directoryPath);
		[self updateDirectoryInBackgroundWithDetails:(NSDictionary *)result];
	}
	else
	{
		XDrvLog(@"Directory fetch returned unexpected result: %@", result);
		_state = DirectoryOperationFailedState;
		[self finish];
	}
}

- (void)connectionFailedWithError:(NSError *)error
{
	XDrvLog(@"Directory fetch failed: %@", error);
	_state = DirectoryOperationFailedState;
	[self finish];
}



@end
















