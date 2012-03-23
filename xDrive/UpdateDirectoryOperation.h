//
//  UpdateDirectoryOperation.h
//  xDrive
//
//  Created by Chris Gibbs on 3/6/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XService.h"


typedef enum {
	DirectoryOperationReadyState,
	DirectoryOperationUpdatingState,
	DirectoryOperationFinishedState,
	DirectoryOperationFailedState
} DirectoryOperationState;

typedef void (^UpdateDirectoryOperationFailedBlock)(NSError *error);


@interface UpdateDirectoryOperation : NSOperation

/**
 The current state of the operation.
 */
@property (nonatomic, assign, readonly) DirectoryOperationState state;

///---------------------
/// @name Initialization
///---------------------

/**
 Initializes the operation for the specified directory path.
 
 @param details The directory detials fetched from the server.
 @param directoryPath The directory path to update.
 */
- (id)initWithDetails:(NSDictionary *)details forDirectoryPath:(NSString *)directoryPath;

///--------------
/// @name Failure
///--------------

/**
 Sets a callback to be called when a failure occurs during the update.
 
 @param block A block object to be called when an error occurs during the update directory process.
 */
- (void)setFailureBlock:(UpdateDirectoryOperationFailedBlock)block;

@end


