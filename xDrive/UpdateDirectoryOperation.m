//
//  UpdateDirectoryOperation.m
//  xDrive
//
//  Created by Chris Gibbs on 3/6/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "UpdateDirectoryOperation.h"
#import "XDriveConfig.h"


@interface UpdateDirectoryOperation ()
@property (nonatomic, strong) NSString *directoryPath;
- (void)updateDirectoryInBackgroundWithDetails:(NSDictionary *)details;
- (void)updateDirectoryWithDetails:(NSDictionary *)details;
- (void)updateDirectoryDidFinish;
@end


@implementation UpdateDirectoryOperation
@synthesize state = _state;
@synthesize directoryPath;


- (id)initWithDirectoryPath:(NSString *)path
{
    self = [super init];
    if (!self) return nil;
	
	directoryPath = path;	
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
		[self updateDirectoryWithDetails:details];
		dispatch_async(mainQueue, ^{
			[self updateDirectoryDidFinish];
		});
	});
	
	dispatch_release(updateQueue);
}

- (void)updateDirectoryWithDetails:(NSDictionary *)details
{
	
}

- (void)updateDirectoryDidFinish
{
	_state = DirectoryOperationFinishedState;
	[self finish];
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
		[[XService sharedXService].remoteService fetchDirectoryContentsAtPath:directoryPath withDelegate:self];
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
















