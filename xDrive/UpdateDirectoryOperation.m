//
//  UpdateDirectoryOperation.m
//  xDrive
//
//  Created by Chris Gibbs on 3/6/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "UpdateDirectoryOperation.h"
#import "XDriveConfig.h"

typedef unsigned short DirectoryOperationState;
typedef enum {
	DirectoryOperationReadyState,
	DirectoryOperationExecutingState,
	DirectoryOperationFinishedState
} _DirectoryOperationState;


@interface UpdateDirectoryOperation ()
@property (nonatomic, assign) DirectoryOperationState state;
@property (nonatomic, strong) NSString *directoryPath;
@end


@implementation UpdateDirectoryOperation
@synthesize state;
@synthesize directoryPath;


- (id)initWithDirectoryPath:(NSString *)path
{
    self = [super init];
    if (!self) return nil;
	
	directoryPath = path;
    state = DirectoryOperationReadyState;
	
    return self;
}

- (void)setCompletionBlock:(void (^)(void))block
{
	if (!block)
	{
		[super setCompletionBlock:nil];
	}
	else
	{
		__block id _blockSelf = self;
		[super setCompletionBlock:^ {
			block();
			[_blockSelf setCompletionBlock:nil];
		}];
	}
}



#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == DirectoryOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == DirectoryOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == DirectoryOperationFinishedState;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    if ([self isReady]) {
        self.state = DirectoryOperationExecutingState;
        
        //[self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
}

/*- (void)operationDidStart {
    [self.lock lock];
    if ([self isCancelled]) {
        [self finish];
    } else {
        self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
            [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
        }
        
        [self.connection start];  
    }
    [self.lock unlock];
}

- (void)finish {
    self.state = AFHTTPOperationFinishedState;
}*/



@end
















