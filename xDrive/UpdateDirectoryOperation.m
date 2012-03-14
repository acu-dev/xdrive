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
@property (nonatomic, strong) NSManagedObjectContext *_localManagedObjectContext;

- (void)updateDirectoryInBackgroundWithDetails:(NSDictionary *)details;
- (BOOL)updateDirectoryWithDetails:(NSDictionary *)details;
- (void)updateDirectoryDidFinish:(BOOL)success;

- (NSManagedObjectContext *)localContext;
- (XFile *)fileWithPath:(NSString *)path;
- (XDirectory *)directoryWithPath:(NSString *)path;
- (XEntry *)entryOfType:(NSString *)type withPath:(NSString *)path;
- (XEntry *)createEntryOfType:(NSString *)type withPath:(NSString *)path;
@end


@implementation UpdateDirectoryOperation

// Private
@synthesize _directoryPath;
@synthesize _localManagedObjectContext;

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
	dispatch_queue_t mainQueue = dispatch_get_main_queue();
	
	dispatch_async(updateQueue, ^{
		BOOL success = [self updateDirectoryWithDetails:details];
		dispatch_async(mainQueue, ^{
			[self updateDirectoryDidFinish:success];
		});
	});
	
	dispatch_release(updateQueue);
}

- (BOOL)updateDirectoryWithDetails:(NSDictionary *)details
{
	// Get directory
	XDirectory *directory = [self directoryWithPath:[details objectForKey:@"path"]];
	if (!directory)
	{
		return NO;
	}
	
	// Directory's last updated time from server
	NSTimeInterval lastUpdatedSeconds = [[details objectForKey:@"lastUpdated"] doubleValue] / 1000;
	NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdatedSeconds];
	if (directory.contentsLastUpdated)
	{
		if ([directory.contentsLastUpdated isEqualToDate:lastUpdated])
		{
			// Directory has not been updated since last fetch; nothing else to do
			XDrvDebug(@"Directory has not been updated; using cached object for dir: %@", directory.path);
			return YES;
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
			entry = [self directoryWithPath:[entryFromJson objectForKey:@"path"]];
		}
		else
		{
			// File
			XFile *file = [self fileWithPath:[entryFromJson objectForKey:@"path"]];
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
	if ([[self localContext] save:&error])
	{
		XDrvDebug(@"Saved local context for %@", directory.path);
		return YES;
	}
	else
	{
		XDrvLog(@"Error: Problem saving local context for %@", directory.path);
		return NO;
	}
}

- (void)updateDirectoryDidFinish:(BOOL)success
{
	_state = (success) ? DirectoryOperationFinishedState : DirectoryOperationFailedState;
	[self finish];
}



#pragma mark - Get/create entries

- (NSManagedObjectContext *)localContext
{
	if (!_localManagedObjectContext)
	{
		_localManagedObjectContext = [[NSManagedObjectContext alloc] init];
		[_localManagedObjectContext setPersistentStoreCoordinator:[XService sharedXService].localService.persistentStoreCoordinator];
	}
	return _localManagedObjectContext;
}

- (XFile *)fileWithPath:(NSString *)path
{
	return (XFile *)[self entryOfType:@"File" withPath:path];
}

- (XDirectory *)directoryWithPath:(NSString *)path
{
	return (XDirectory *)[self entryOfType:@"Directory" withPath:path];
}

- (XEntry *)entryOfType:(NSString *)type withPath:(NSString *)path
{
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:type];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"path == %@", path]];
	[fetchRequest setFetchBatchSize:1];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [[self localContext] executeFetchRequest:fetchRequest error:&error];
	if (!fetchedObjects)
	{
		// Something went wrong
		XDrvLog(@"Error performing fetch request: %@", [error localizedDescription]);
		return nil;
	}
	
	if (![fetchedObjects count])
	{
		// No entries found, create one
		return [self createEntryOfType:type withPath:path];
	}
	else
	{
		// Return last object found (there should only be one)
		return [fetchedObjects lastObject];
	}
}

- (XEntry *)createEntryOfType:(NSString *)type withPath:(NSString *)path
{
	XEntry *newEntry = [NSEntityDescription insertNewObjectForEntityForName:type
													 inManagedObjectContext:[self localContext]];
	newEntry.path = path;
	newEntry.name = [path lastPathComponent];
	newEntry.server = [XService sharedXService].localService.server;
	
	return newEntry;
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
		XDrvDebug(@"Starting directory update operation for %@", directoryPath);
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
		XDrvDebug(@"Directory fetch finished for %@", directoryPath);
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
















