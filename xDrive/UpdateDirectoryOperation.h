//
//  UpdateDirectoryOperation.h
//  xDrive
//
//  Created by Chris Gibbs on 3/6/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UpdateDirectoryOperation : NSOperation

///---------------------
/// @name Initialization
///---------------------

/**
 Initializes the operation for the specified directory path.
 
 @param path The directory path to update.
 */
- (id)initWithDirectoryPath:(NSString *)path;


@end
