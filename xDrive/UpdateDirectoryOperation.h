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
	DirectoryOperationFetchingState,
	DirectoryOperationUpdatingState,
	DirectoryOperationFinishedState,
	DirectoryOperationFailedState
} DirectoryOperationState;


@interface UpdateDirectoryOperation : NSOperation <XServiceRemoteDelegate>

/**
 The current state of the operation.
 */
@property (nonatomic, assign, readonly) DirectoryOperationState state;

///---------------------
/// @name Initialization
///---------------------

/**
 Initializes the operation for the specified directory path.
 
 @param path The directory path to update.
 */
- (id)initWithDirectoryPath:(NSString *)path;


@end
