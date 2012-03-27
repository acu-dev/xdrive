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

@end


@implementation UpdateDirectoryOperation

// Private
@synthesize _directoryDetails;
@synthesize _directoryPath;


#pragma mark - Initiailization

- (id)initWithDetails:(NSDictionary *)details forDirectoryPath:(NSString *)directoryPath
{
    self = [super init];
    if (!self) return nil;

	XDrvDebug(@"%@ :: Creating update operation", directoryPath);
	_directoryPath = directoryPath;
	_directoryDetails = details;
	
    return self;
}



#pragma mark - Update Directory

- (void)main
{
	// Create new service with it's own context for background operation
	XDrvDebug(@"%@ :: Creating new service for background operation", _directoryPath);
	XServiceLocal *localService = [[XService sharedXService].localService newServiceForOperation];
	
	// Get directory
	XDrvDebug(@"%@ :: Fetching directory object from local service", _directoryPath);
	XDirectory *directory = [localService directoryWithPath:[_directoryDetails objectForKey:@"path"]];
	
	// Update last updated time (times come from details in milliseconds since epoch)
	NSTimeInterval lastUpdatedSeconds = [[_directoryDetails objectForKey:@"lastUpdated"] doubleValue] / 1000;
	NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdatedSeconds];
	directory.lastUpdated = lastUpdated;
	directory.contentsLastUpdated = lastUpdated;
	
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
			dispatch_async(dispatch_get_main_queue(), ^{
				[[XService sharedXService] updateEntryFailedWithError:error];
			});
		}
		else
		{
			XDrvDebug(@"%@ :: Saved local context", directory.path);
			dispatch_async(dispatch_get_main_queue(), ^{
				[[XService sharedXService] operationDidFinishUpdatingDirectoryAtPath:directory.path];
			});
		}
	}];
}

@end
















