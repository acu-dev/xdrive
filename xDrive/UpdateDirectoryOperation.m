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

@property (nonatomic, strong) NSDictionary *_directoryDetails;
@property (nonatomic, strong) NSString *_directoryPath;
@property (nonatomic, strong) XServiceLocal *_localService;

@end


@implementation UpdateDirectoryOperation

// Private
@synthesize _directoryDetails;
@synthesize _directoryPath;
@synthesize _localService;


#pragma mark - Initiailization

- (id)initWithDetails:(NSDictionary *)details forDirectoryAtPath:(NSString *)path
{
    self = [super init];
    if (!self) return nil;

	XDrvDebug(@"%@ :: Creating update operation", path);
	_directoryPath = path;
	_directoryDetails = details;
	
    return self;
}



#pragma mark - Update Directory

- (void)main
{
	// Create new service with it's own context for background operation
	XDrvDebug(@"%@ :: Creating new service for background operation", _directoryPath);
	_localService = [[XService sharedXService].localService newServiceForOperation];
	
	// Get directory
	XDirectory *directory = [_localService directoryWithPath:_directoryPath];
	
	// Remote directory's last updated time (times come from details in milliseconds since epoch)
	NSTimeInterval lastUpdatedSeconds = [[_directoryDetails objectForKey:@"lastUpdated"] doubleValue] / 1000;
	NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdatedSeconds];
	
	if ([directory.contentsLastUpdated compare:lastUpdated] == NSOrderedDescending)
	{
		// Remote directory has no changes
		XDrvDebug(@"%@ :: Remote directory has not changed", directory.path);
		directory.contentsLastUpdated = [NSDate date];
		[self finished];
		return;
	}
	
	// Update dates
	directory.lastUpdated = lastUpdated;
	directory.contentsLastUpdated = [NSDate date];
	
	// Go through contents and create a set of remote entries (entries that don't exist are created on the fly)
	NSMutableSet *remoteEntries = [[NSMutableSet alloc] init];
	NSArray *contents = [_directoryDetails objectForKey:@"contents"];
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
			file.sizeDescription = [NSString stringByFormattingBytes:[file.size longLongValue]];
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
			[_localService removeEntry:entry];
		}
	}
	
	// Update directory's contents with set of entries from server
	[directory setContents:remoteEntries];
	
	// All done
	[self finished];
}

- (void)finished
{
	// Save changes
	[_localService saveWithCompletionBlock:^(NSError *error) {
		NSString *path = _directoryPath;
		if (error)
		{
			XDrvLog(@"%@ :: Error: Problem saving local context: %@", path, error);
			dispatch_async(dispatch_get_main_queue(), ^{
				[[XService sharedXService] updateDirectoryAtPath:path failedWithError:error];
			});
		}
		else
		{
			XDrvDebug(@"%@ :: Saved local context", path);
			dispatch_async(dispatch_get_main_queue(), ^{
				[[XService sharedXService] didFinishUpdatingDirectoryAtPath:path];
			});
		}
	}];
}

@end
















